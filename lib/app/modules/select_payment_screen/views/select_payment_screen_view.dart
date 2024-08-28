import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer_app/app/models/wallet_transaction_model.dart';
import 'package:customer_app/app/widget/svg_image_widget.dart';
import 'package:customer_app/constant/constant.dart';
import 'package:customer_app/constant/show_toast_dialogue.dart';
import 'package:customer_app/themes/app_colors.dart';
import 'package:customer_app/themes/app_them_data.dart';
import 'package:customer_app/themes/button_theme.dart';
import 'package:customer_app/themes/common_ui.dart';
import 'package:customer_app/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/select_payment_screen_controller.dart';

class SelectPaymentScreenView extends StatelessWidget {
  const SelectPaymentScreenView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetX<SelectPaymentScreenController>(
        init: SelectPaymentScreenController(),
        builder: (controller) {
          return Scaffold(
            appBar: UiInterface().customAppBar(context, "Payment Method".tr, backgroundColor: AppColors.white),
            body: controller.isLoading.value
                ? Constant.loader()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                    child: Column(
                      children: [
                        Visibility(
                          visible: controller.paymentModel.value.wallet != null && controller.paymentModel.value.wallet!.enable == true,
                          child: paymentDecoration(
                              controller: controller,
                              value: controller.paymentModel.value.wallet!.name.toString(),
                              image: "assets/images/wallet.png"),
                        ),
                        Visibility(
                            visible: controller.paymentModel.value.strip != null && controller.paymentModel.value.strip!.enable == true,
                            child: paymentDecoration(
                                controller: controller,
                                value: controller.paymentModel.value.strip!.name.toString(),
                                image: "assets/images/stripe.png")),
                        Visibility(
                            visible: controller.paymentModel.value.paypal != null && controller.paymentModel.value.paypal!.enable == true,
                            child: paymentDecoration(
                                controller: controller,
                                value: controller.paymentModel.value.paypal!.name.toString(),
                                image: "assets/images/paypal.png"))
                      ],
                    ),
                  ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              child: ButtonThem.buildButton(
                txtSize: 16,
                context,
                title: "Pay Now",
                txtColor: AppColors.lightGrey01,
                bgColor: !controller.isPaymentCompleted.value ? AppColors.darkGrey06 : AppColors.darkGrey10,
                onPress: () async {
                  if (!controller.isPaymentCompleted.value) {
                    return;
                  }

                  if (controller.selectedPaymentMethod.value == controller.paymentModel.value.strip!.name) {
                    controller.stripeMakePayment(
                        amount: controller.calculateAmount().toStringAsFixed(Constant.currencyModel!.decimalDigits!));
                  } else if (controller.selectedPaymentMethod.value == controller.paymentModel.value.paypal!.name) {
                    controller.paypalPaymentSheet(controller.calculateAmount().toStringAsFixed(Constant.currencyModel!.decimalDigits!));
                  } else if (controller.selectedPaymentMethod.value == controller.paymentModel.value.wallet!.name) {
                    if (double.parse(controller.customerModel.value.walletAmount.toString()) >= controller.calculateAmount()) {
                      WalletTransactionModel transactionModel = WalletTransactionModel(
                          id: Constant.getUuid(),
                          amount: "-${controller.calculateAmount().toString()}",
                          createdDate: Timestamp.now(),
                          paymentType: controller.selectedPaymentMethod.value,
                          transactionId: controller.bookingModel.value.id,
                          parkingId: controller.bookingModel.value.parkingDetails!.id.toString(),
                          note: "Parking fee debited".tr,
                          type: "customer",
                          userId: FireStoreUtils.getCurrentUid(),
                          isCredit: false);

                      log(controller.calculateAmount().toString());
                      await FireStoreUtils.setWalletTransaction(transactionModel).then((value) async {
                        if (value == true) {
                          await FireStoreUtils.updateUserWallet(amount: "-${controller.calculateAmount().toString()}").then((value) {
                            controller.completeOrder();
                          });
                        }
                      });
                    } else {
                      ShowToastDialog.showToast("Wallet Amount Insufficient".tr);
                    }
                  }
                },
              ),
            ),
          );
        });
  }
}

paymentDecoration({required SelectPaymentScreenController controller, required String value, required String image}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: InkWell(
      onTap: () {
        controller.selectedPaymentMethod.value = value.toString();
      },
      child: Row(
        children: [
          Image.asset(
            image,
            height: 62,
            width: 62,
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: Text(
                    (value == "wallet") ? "My Wallet" : value,
                    style: const TextStyle(fontFamily: AppThemData.semiBold, fontSize: 16, color: AppColors.darkGrey08),
                  ),
                ),
                if (value == "wallet")
                  Text(
                    "Available Balance:- ${Constant.amountShow(amount: controller.customerModel.value.walletAmount)}",
                    style: const TextStyle(fontFamily: AppThemData.medium, color: AppColors.darkGrey05),
                  )
              ],
            ),
          ),
          SvgImageWidget(
            imagePath: (controller.selectedPaymentMethod.value == value.toString())
                ? "assets/icons/ic_check_active.svg"
                : "assets/icons/ic_check_inactive.svg",
            height: 22,
            width: 22,
            color: (controller.selectedPaymentMethod.value == value.toString()) ? AppColors.yellow04 : AppColors.darkGrey04,
          ),
        ],
      ),
    ),
  );
}
