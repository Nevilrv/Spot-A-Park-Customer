import 'dart:developer';

import 'package:customer_app/app/models/location_lat_lng.dart';
import 'package:customer_app/app/models/parking_model.dart';
import 'package:customer_app/constant/constant.dart';
import 'package:customer_app/utils/fire_store_utils.dart';
import 'package:customer_app/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  RxBool isLoading = false.obs;

  Rx<TextEditingController> addressController = TextEditingController().obs;

  RxList<ParkingModel> parkingList = <ParkingModel>[].obs;
  Rx<LocationLatLng> locationLatLng = LocationLatLng().obs;



  @override
  void onInit() {
    getCurrentLocation();
    super.onInit();
  }

  getCurrentLocation() async {
    Constant.currentLocation = await Utils.getCurrentLocation();
    locationLatLng.value = LocationLatLng(latitude: Constant.currentLocation!.latitude, longitude: Constant.currentLocation!.longitude);
    List<Placemark> placeMarks = await placemarkFromCoordinates(Constant.currentLocation!.latitude, Constant.currentLocation!.longitude);
    Constant.country = placeMarks.first.country;
    getTax();
    getNearbyParking();
  }

  getTax() async {
    await FireStoreUtils().getTaxList().then((value) {
      if (value != null) {
        Constant.taxList = value;
      }
    });
  }

  getNearbyParking() {
    FireStoreUtils()
        .getParkingNearest(latitude: locationLatLng.value.latitude, longLatitude: locationLatLng.value.longitude)
        .listen((event) {
      parkingList.value = event;

      parkingList.refresh();
      isLoading.value = true;
    });
  }

  addLikedParking(ParkingModel parkingModel) async {
    log("add-->>");
    parkingModel.likedUser!.add(FireStoreUtils.getCurrentUid());

    await FireStoreUtils.saveParkingDetails(parkingModel).then((value) {});
  }

  removeLikedParking(ParkingModel parkingModel) async {
    log("Remove-->>");
    parkingModel.likedUser!.remove(FireStoreUtils.getCurrentUid());

    await FireStoreUtils.saveParkingDetails(parkingModel).then((value) {});
  }

  @override
  void dispose() {
    FireStoreUtils().getNearestParkingRequestController!.close();
    super.dispose();
  }
}
