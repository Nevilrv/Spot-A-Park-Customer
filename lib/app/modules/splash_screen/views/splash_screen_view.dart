import 'package:customer_app/themes/app_colors.dart';
import 'package:customer_app/themes/app_them_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/splash_screen_controller.dart';

class SplashScreenView extends StatelessWidget {
  const SplashScreenView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashScreenController>(
      init: SplashScreenController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.yellow04,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/images/logo.png",
                  height: 166,
                  width: 88,
                ),
                const Text(
                  "Spot A Park",
                  style: TextStyle(
                      fontFamily: AppThemData.bold,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      fontSize: 32),
                ),
                const Text(
                  "Parking Made Effortless",
                  style: TextStyle(
                      fontFamily: AppThemData.regular,
                      color: Colors.black,
                      fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
