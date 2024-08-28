import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer_app/app/models/booking_model.dart';
import 'package:customer_app/app/models/coupon_model.dart';
import 'package:customer_app/constant/collection_name.dart';
import 'package:customer_app/constant/constant.dart';
import 'package:customer_app/constant/show_toast_dialogue.dart';
import 'package:customer_app/utils/fire_store_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class BookingDetailScreenController extends GetxController {
  RxBool isLoading = true.obs;

  Rx<TextEditingController> couponCodeController = TextEditingController().obs;
  Rx<CouponModel> selectedCouponModel = CouponModel().obs;

  RxDouble couponAmount = 0.0.obs;
  Rx<BookingModel> bookingModel = BookingModel().obs;

  @override
  void onInit() {
    getArgument();
    super.onInit();
  }

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      bookingModel.value = argumentData['bookingModel'];
      isLoading.value = false;
    }
    update();
  }

  getCoupon() async {
    if (couponCodeController.value.text.isNotEmpty) {
      ShowToastDialog.showLoader("Please wait".tr);
      await FireStoreUtils.fireStore
          .collection(CollectionName.coupon)
          .where('code', isEqualTo: couponCodeController.value.text)
          .where('active', isEqualTo: true)
          .where('expireAt', isGreaterThanOrEqualTo: Timestamp.now())
          .get()
          .then((value) {
        ShowToastDialog.closeLoader();
        if (value.docs.isNotEmpty) {
          selectedCouponModel.value = CouponModel.fromJson(value.docs.first.data());
          couponCodeController.value.text = selectedCouponModel.value.code.toString();
          if (selectedCouponModel.value.isFix == true) {
            if (double.parse(selectedCouponModel.value.minAmount.toString()) <= double.parse(bookingModel.value.subTotal.toString())) {
              couponAmount.value = double.parse(selectedCouponModel.value.amount.toString());
              ShowToastDialog.showToast("Coupon Applied".tr);
            } else {
              ShowToastDialog.showToast(
                  "Minimum Amount ${Constant.amountShow(amount: selectedCouponModel.value.minAmount.toString())} Required".tr);
            }
          } else {
            if (double.parse(selectedCouponModel.value.minAmount.toString()) <= double.parse(bookingModel.value.subTotal.toString())) {
              couponAmount.value =
                  double.parse(bookingModel.value.subTotal.toString()) * double.parse(selectedCouponModel.value.amount.toString()) / 100;

              ShowToastDialog.showToast("Coupon Applied".tr);
            } else {
              ShowToastDialog.showToast("Minimum Amount ${selectedCouponModel.value.minAmount.toString()} Required".tr);
            }
          }
        } else {
          ShowToastDialog.showToast("Coupon code is Invalid".tr);
        }
      }).catchError((error) {
        log(error.toString());
      });
    } else {
      ShowToastDialog.showToast("Please Enter coupon code".tr);
    }
  }

  applyCoupon() async {
    if (bookingModel.value.coupon != null) {
      if (bookingModel.value.coupon!.id != null) {
        if (bookingModel.value.coupon!.isFix == true) {
          couponAmount.value = double.parse(bookingModel.value.coupon!.amount.toString());
        } else {
          couponAmount.value =
              double.parse(bookingModel.value.subTotal.toString()) * double.parse(bookingModel.value.coupon!.amount.toString()) / 100;
        }
      }
    }
  }

  double calculateAmount() {
    applyCoupon();
    RxString taxAmount = "0.0".obs;
    if (bookingModel.value.taxList != null) {
      for (var element in bookingModel.value.taxList!) {
        taxAmount.value = (double.parse(taxAmount.value) +
                Constant().calculateTax(
                    amount: (double.parse(bookingModel.value.subTotal.toString()) - double.parse(couponAmount.toString())).toString(),
                    taxModel: element))
            .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
      }
    }
    return (double.parse(bookingModel.value.subTotal.toString()) - double.parse(couponAmount.toString())) + double.parse(taxAmount.value);
  }
}
