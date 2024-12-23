// lib/services/directions_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';

class DirectionsService {
  Future<Map<String, dynamic>> getDirections(String origin, String destination) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=walking&key=AIzaSyAM2HDUq5-t5UNzFtx0gFTzZO4tsxIfcuY';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load directions');
    }
  }
}
