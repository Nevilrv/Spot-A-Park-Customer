import 'package:customer_app/app/models/location_lat_lng.dart';
import 'package:customer_app/app/models/parking_model.dart';
import 'package:customer_app/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchScreenController extends GetxController {
  RxBool isLoading = false.obs;

  Rx<TextEditingController> addressController = TextEditingController().obs;

  RxList<ParkingModel> parkingList = <ParkingModel>[].obs;
  Rx<LocationLatLng> locationLatLng = LocationLatLng().obs;

  int cnt = 1;

  getNearbyParking() {
    FireStoreUtils()
        .getParkingNearest(
            latitude: locationLatLng.value.latitude,
            longLatitude: locationLatLng.value.longitude)
        .listen((event) {
      parkingList.value = event;
      parkingList.refresh();
      isLoading.value = true;
    });
  }
}
