import 'package:customer_app/app/modules/booking_screen/views/booking_screen_view.dart';
import 'package:customer_app/app/modules/home/views/home_view.dart';
import 'package:customer_app/app/modules/profile_screen/views/profile_screen_view.dart';
import 'package:customer_app/app/modules/wallet_screen/views/wallet_screen_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardScreenController extends GetxController {
  RxInt selectedIndex = 0.obs;

  RxList pageList = [
    const HomeView(),
    const BookingScreenView(),
    const SizedBox(),
    const WalletScreenView(),
    const ProfileScreenView()
  ].obs;
}
