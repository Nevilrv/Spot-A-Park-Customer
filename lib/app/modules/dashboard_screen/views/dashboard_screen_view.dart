// ignore_for_file: deprecated_member_use

import 'package:customer_app/app/models/location_lat_lng.dart';
import 'package:customer_app/app/modules/home/controllers/home_controller.dart';
import 'package:customer_app/themes/app_colors.dart';
import 'package:customer_app/themes/app_them_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:place_picker/entities/entities.dart';

import '../../../../utils/utils.dart';
import '../../../routes/app_pages.dart';
import '../controllers/dashboard_screen_controller.dart';

class DashboardScreenView extends GetView<DashboardScreenController> {
  const DashboardScreenView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool keyboardIsOpen = MediaQuery.of(context).viewInsets.bottom != 0;
    return Obx(
      () => Scaffold(
        body: controller.pageList[controller.selectedIndex.value],
        bottomNavigationBar: BottomNavigationBar(
          elevation: 0,
          currentIndex: controller.selectedIndex.value,
          showUnselectedLabels: true,
          onTap: (int index) async {
            controller.selectedIndex.value = index;
          },
          selectedItemColor: AppColors.yellow04,
          showSelectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontFamily: AppThemData.bold,
            fontSize: 12,
          ),
          type: BottomNavigationBarType.fixed,
          unselectedItemColor: AppColors.darkGrey04,
          unselectedLabelStyle: const TextStyle(
            fontFamily: AppThemData.medium,
            fontSize: 12,
          ),
          backgroundColor: AppColors.darkGrey10,
          items: [
            BottomNavigationBarItem(
                activeIcon: SvgPicture.asset("assets/icons/ic_home_active.svg"),
                icon: SvgPicture.asset("assets/icons/ic_home.svg"),
                label: "Home".tr),
            BottomNavigationBarItem(
                activeIcon:
                    SvgPicture.asset("assets/icons/ic_notepad_active.svg"),
                icon: SvgPicture.asset("assets/icons/ic_notepad.svg"),
                label: "Bookings".tr),
            const BottomNavigationBarItem(
              icon: Icon(null),
              label: '',
            ),
            BottomNavigationBarItem(
                activeIcon:
                    SvgPicture.asset("assets/icons/ic_wallet_active.svg"),
                icon: SvgPicture.asset("assets/icons/ic_wallet.svg"),
                label: "Wallet".tr),
            BottomNavigationBarItem(
                activeIcon:
                    SvgPicture.asset("assets/icons/ic_myprofile_active.svg"),
                icon: SvgPicture.asset(
                  "assets/icons/ic_myprofile.svg",
                  color: AppColors.darkGrey04,
                ),
                label: "My Profile".tr),
          ],
        ),
        floatingActionButton: Visibility(
          visible: !keyboardIsOpen,
          child: Container(
            decoration: BoxDecoration(
                color: AppColors.lightGrey02,
                borderRadius: BorderRadius.circular(50)),
            padding: const EdgeInsets.all(8),
            child: FloatingActionButton(
              shape: const CircleBorder(),
              backgroundColor: AppColors.yellow04,
              onPressed: () async {
                LocationResult? result = await Utils.showPlacePicker(context);
                if (result != null) {
                  DashboardScreenController dashboardScreenController =
                      Get.put(DashboardScreenController());
                  dashboardScreenController.selectedIndex(0);
                  Get.toNamed(Routes.DASHBOARD_SCREEN);
                  HomeController controller = Get.put(HomeController());
                  controller.addressController.value.text =
                      result.formattedAddress.toString();
                  controller.locationLatLng.value = LocationLatLng(
                      latitude: result.latLng!.latitude,
                      longitude: result.latLng!.longitude);
                  await controller.getNearbyParking();
                }
              },
              child: SvgPicture.asset(
                "assets/icons/ic_place_marker.svg",
                height: 24,
                width: 24,
                color: AppColors.darkGrey10,
              ),
            ),
          ),
        ),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.miniCenterDocked,
      ),
    );
  }
}
