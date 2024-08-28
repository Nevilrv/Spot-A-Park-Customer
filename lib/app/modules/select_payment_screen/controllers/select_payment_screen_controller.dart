// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer_app/app/models/booking_model.dart';
import 'package:customer_app/app/models/customer_model.dart';
import 'package:customer_app/app/models/owner_model.dart';
import 'package:customer_app/app/models/payment/stripe_failed_model.dart';
import 'package:customer_app/app/models/payment_method_model.dart';
import 'package:customer_app/app/models/wallet_transaction_model.dart';
import 'package:customer_app/app/models/watchman_model.dart';
import 'package:customer_app/app/modules/dashboard_screen/controllers/dashboard_screen_controller.dart';
import 'package:customer_app/app/routes/app_pages.dart';
import 'package:customer_app/constant/constant.dart';
import 'package:customer_app/constant/send_notification.dart';
import 'package:customer_app/constant/show_toast_dialogue.dart';
import 'package:customer_app/themes/app_colors.dart';
import 'package:customer_app/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_paypal_native/flutter_paypal_native.dart';
import 'package:flutter_paypal_native/models/custom/currency_code.dart';
import 'package:flutter_paypal_native/models/custom/environment.dart';
import 'package:flutter_paypal_native/models/custom/order_callback.dart';
import 'package:flutter_paypal_native/models/custom/purchase_unit.dart';
import 'package:flutter_paypal_native/models/custom/user_action.dart';
import 'package:flutter_paypal_native/str_helper.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class SelectPaymentScreenController extends GetxController {
  Rx<BookingModel> bookingModel = BookingModel().obs;
  Rx<CustomerModel> customerModel = CustomerModel().obs;
  Rx<PaymentModel> paymentModel = PaymentModel().obs;
  RxString selectedPaymentMethod = "".obs;
  RxBool isPaymentCompleted = true.obs;
  String couponAmount = "0.0";
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    getArgument();
    super.onInit();
  }

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      bookingModel.value = argumentData['bookingModel'];
      couponAmount = bookingModel.value.coupon!.amount ?? '0.0';
      getPaymentData();
    }
  }

  getPaymentData() async {
    isLoading.value = true;
    await FireStoreUtils().getPayment().then((value) {
      if (value != null) {
        paymentModel.value = value;
        Stripe.publishableKey =
            paymentModel.value.strip!.clientpublishableKey.toString();
        log(paymentModel.value.strip!.clientpublishableKey.toString());
        Stripe.merchantIdentifier = 'Spot A Park';
        Stripe.instance.applySettings();
        initPayPal();
        selectedPaymentMethod.value = bookingModel.value.paymentType.toString();
      }
    });

    await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid())
        .then((value) {
      if (value != null) {
        customerModel.value = value;
      }
    });
    isLoading.value = false;

    update();
  }

  double calculateAmount() {
    RxString taxAmount = "0.0".obs;
    if (bookingModel.value.taxList != null) {
      for (var element in bookingModel.value.taxList!) {
        taxAmount.value = (double.parse(taxAmount.value) +
                Constant().calculateTax(
                    amount:
                        (double.parse(bookingModel.value.subTotal.toString()) -
                                double.parse(couponAmount.toString()))
                            .toString(),
                    taxModel: element))
            .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
      }
    }
    return (double.parse(bookingModel.value.subTotal.toString()) -
            double.parse(couponAmount.toString())) +
        double.parse(taxAmount.value);
  }

  completeOrder() async {
    isPaymentCompleted.value = false;
    ShowToastDialog.showLoader("Please Wait");
    bookingModel.value.paymentCompleted = true;
    bookingModel.value.paymentType = selectedPaymentMethod.value;
    bookingModel.value.adminCommission = Constant.adminCommission;
    bookingModel.value.createdAt = Timestamp.now();

    WalletTransactionModel transactionModel = WalletTransactionModel(
        id: Constant.getUuid(),
        amount: calculateAmount().toString(),
        createdDate: Timestamp.now(),
        paymentType: selectedPaymentMethod.value,
        transactionId: bookingModel.value.id,
        parkingId: bookingModel.value.parkingDetails!.id.toString(),
        isCredit: true,
        type: "owner",
        userId: bookingModel.value.parkingDetails!.ownerId.toString(),
        note: "Parking fee credited");

    await FireStoreUtils.setWalletTransaction(transactionModel)
        .then((value) async {
      if (value == true) {
        await FireStoreUtils.updateOtherUserWallet(
            amount: calculateAmount().toString(),
            id: bookingModel.value.parkingDetails!.ownerId.toString());
      }
    });

    WalletTransactionModel adminCommissionWallet = WalletTransactionModel(
        id: Constant.getUuid(),
        amount:
            "-${Constant.calculateAdminCommission(amount: (double.parse(bookingModel.value.subTotal.toString()) - double.parse(couponAmount.toString())).toString(), adminCommission: bookingModel.value.adminCommission)}",
        createdDate: Timestamp.now(),
        paymentType: selectedPaymentMethod.value,
        transactionId: bookingModel.value.id,
        isCredit: false,
        type: "owner",
        parkingId: bookingModel.value.parkingDetails!.id.toString(),
        userId: bookingModel.value.parkingDetails!.ownerId.toString(),
        note: "Admin commission debited");

    await FireStoreUtils.setWalletTransaction(adminCommissionWallet)
        .then((value) async {
      if (value == true) {
        await FireStoreUtils.updateOtherUserWallet(
            amount:
                "-${Constant.calculateAdminCommission(amount: (double.parse(bookingModel.value.subTotal.toString()) - double.parse(couponAmount.toString())).toString(), adminCommission: bookingModel.value.adminCommission)}",
            id: bookingModel.value.parkingDetails!.ownerId.toString());
      }
    });

    OwnerModel? receiverUserModel = await FireStoreUtils.getOwnerProfile(
        bookingModel.value.parkingDetails!.ownerId.toString());
    Map<String, dynamic> playLoad = <String, dynamic>{
      "type": "order",
      "orderId": bookingModel.value.id
    };

    await SendNotification.sendOneNotification(
        token: receiverUserModel!.fcmToken.toString(),
        title: 'Booking Placed',
        body:
            '${bookingModel.value.parkingDetails!.parkingName.toString()} Booking placed on ${Constant.timestampToDate(bookingModel.value.bookingDate!)}.',
        payload: playLoad);

    if (Constant.timestampToDate(bookingModel.value.bookingDate!) ==
        Constant.timestampToDate(Timestamp.now())) {
      WatchManModel? watchManModel = await FireStoreUtils.getWatchManProfile(
          bookingModel.value.parkingId.toString());
      if (watchManModel != null) {
        await SendNotification.sendOneNotification(
            token: watchManModel.fcmToken.toString(),
            title: 'Booking Placed',
            body:
                '${bookingModel.value.parkingDetails!.parkingName.toString()} Booking placed on ${Constant.timestampToDate(bookingModel.value.bookingDate!)}.',
            payload: playLoad);
      }
    }

    await FireStoreUtils.setOrder(bookingModel.value).then((value) async {
      if (value == true) {
        await FireStoreUtils.getFirstOrderOrNOt(bookingModel.value)
            .then((value) async {
          if (value == true) {
            await FireStoreUtils.updateReferralAmount(bookingModel.value);
          }
        });
        ShowToastDialog.showToast("Booked");
        Get.offAllNamed(Routes.DASHBOARD_SCREEN);
        DashboardScreenController controller =
            Get.put(DashboardScreenController());
        controller.selectedIndex(1);
        ShowToastDialog.closeLoader();
      }
    });
  }

  Future<void> stripeMakePayment({required String amount}) async {
    log(double.parse(amount).toStringAsFixed(0));
    try {
      Map<String, dynamic>? paymentIntentData =
          await createStripeIntent(amount: amount);
      if (paymentIntentData!.containsKey("error")) {
        Get.back();
        ShowToastDialog.showToast(
            "Something went wrong, please contact admin.");
      } else {
        await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
                paymentIntentClientSecret: paymentIntentData['client_secret'],
                allowsDelayedPaymentMethods: false,
                googlePay: const PaymentSheetGooglePay(
                  merchantCountryCode: 'US',
                  testEnv: true,
                  currencyCode: "USD",
                ),
                style: ThemeMode.system,
                appearance: const PaymentSheetAppearance(
                  colors: PaymentSheetAppearanceColors(
                    primary: AppColors.yellow04,
                  ),
                ),
                merchantDisplayName: "Spot A Park"));
        displayStripePaymentSheet(amount: amount);
      }
    } catch (e, s) {
      log("$e \n$s");
      ShowToastDialog.showToast("exception:$e \n$s");
    }
  }

  displayStripePaymentSheet({required String amount}) async {
    try {
      await Stripe.instance.presentPaymentSheet().then((value) {
        ShowToastDialog.showToast("Payment successfully");
        completeOrder();
      });
    } on StripeException catch (e) {
      var lo1 = jsonEncode(e);
      var lo2 = jsonDecode(lo1);
      StripePayFailedModel lom = StripePayFailedModel.fromJson(lo2);
      ShowToastDialog.showToast(lom.error.message);
    } catch (e) {
      ShowToastDialog.showToast(e.toString());
    }
  }

  createStripeIntent({required String amount}) async {
    try {
      Map<String, dynamic> body = {
        'amount': ((double.parse(amount) * 100).round()).toString(),
        'currency': "USD",
        'payment_method_types[]': 'card',
        "description": "Strip Payment",
        "shipping[name]": customerModel.value.fullName,
        "shipping[address][line1]": "510 Townsend St",
        "shipping[address][postal_code]": "98140",
        "shipping[address][city]": "San Francisco",
        "shipping[address][state]": "CA",
        "shipping[address][country]": "US",
      };
      log(paymentModel.value.strip!.stripeSecret.toString());
      var stripeSecret = paymentModel.value.strip!.stripeSecret;
      var response = await http.post(
          Uri.parse('https://api.stripe.com/v1/payment_intents'),
          body: body,
          headers: {
            'Authorization': 'Bearer $stripeSecret',
            'Content-Type': 'application/x-www-form-urlencoded'
          });

      return jsonDecode(response.body);
    } catch (e) {
      log(e.toString());
    }
  }

  final _flutterPaypalNativePlugin = FlutterPaypalNative.instance;

  void initPayPal() async {
    //set debugMode for error logging
    FlutterPaypalNative.isDebugMode =
        paymentModel.value.paypal!.isSandbox == true ? true : false;

    //initiate payPal plugin
    await _flutterPaypalNativePlugin.init(
      //your app id !!! No Underscore!!! see readme.md for help
      returnUrl: "com.sataware.spotapark://paypalpay",
      //client id from developer dashboard
      clientID: paymentModel.value.paypal!.paypalClient.toString(),
      //sandbox, staging, live etc
      payPalEnvironment: paymentModel.value.paypal!.isSandbox == true
          ? FPayPalEnvironment.sandbox
          : FPayPalEnvironment.live,
      //what currency do you plan to use? default is US dollars
      currencyCode: FPayPalCurrencyCode.usd,
      //action paynow?
      action: FPayPalUserAction.payNow,
    );

    //call backs for payment
    _flutterPaypalNativePlugin.setPayPalOrderCallback(
      callback: FPayPalOrderCallback(
        onCancel: () {
          //user canceled the payment
          ShowToastDialog.showToast("Payment canceled");
        },
        onSuccess: (data) {
          //successfully paid
          //remove all items from queue
          _flutterPaypalNativePlugin.removeAllPurchaseItems();
          String visitor = data.cart?.shippingAddress?.firstName ?? 'Visitor';
          log('visitor==========>>>>>$visitor');
          String address =
              data.cart?.shippingAddress?.line1 ?? 'Unknown Address';
          log('address==========>>>>>$address');
          ShowToastDialog.showToast("Payment Successfully");
          completeOrder();
        },
        onError: (data) {
          //an error occured
          ShowToastDialog.showToast("error: ${data.reason}");
        },
        onShippingChange: (data) {
          //the user updated the shipping address
          ShowToastDialog.showToast(
              "shipping change: ${data.shippingChangeAddress?.adminArea1 ?? ""}");
        },
      ),
    );
  }

  paypalPaymentSheet(String amount) {
    //add 1 item to cart. Max is 4!
    if (_flutterPaypalNativePlugin.canAddMorePurchaseUnit) {
      _flutterPaypalNativePlugin.addPurchaseUnit(
        FPayPalPurchaseUnit(
          // random prices
          amount: double.parse(amount),

          ///please use your own algorithm for referenceId. Maybe ProductID?
          referenceId: FPayPalStrHelper.getRandomString(16),
        ),
      );
    }

    _flutterPaypalNativePlugin.makeOrder(
      action: FPayPalUserAction.payNow,
    );
  }
}
