// lib/location_service.dart

import 'package:location/location.dart';

class LocationService {
  Location location = Location();

  Future<LocationData?> getLocation() async {
    try {

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {

        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          return null;
        }
      }


      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {

        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return null;
        }
      }


      return await location.getLocation();
    } catch (e) {
      print("Error getting location: $e");
      return null;
    }
  }
}