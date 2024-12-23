// lib/utils/location_utils.dart

import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationUtils {
  LatLng generateRandomLocation(LatLng startLocation, double radius) {
    final random = Random();
    final double angle = random.nextDouble() * 2 * pi;
    final double distance = random.nextDouble() * radius;
    final double deltaLat = cos(angle) * distance / 111.32;
    final double deltaLng = sin(angle) * distance / (111.32 * cos(startLocation.latitude * pi / 180));
    return LatLng(startLocation.latitude + deltaLat, startLocation.longitude + deltaLng);
  }
}
