// lib/record/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CalendarPage extends StatelessWidget {
  final List<LatLng> walkedRoute;
  final Duration time;
  final double distance;

  CalendarPage({
    required this.walkedRoute,
    required this.time,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('뚜벅기록'),
      ),
      body: Column(
        children: [
          Text('운동 시간: ${time.inMinutes}:${(time.inSeconds % 60).toString().padLeft(2, '0')}'),
          Text('운동 거리: ${distance.toStringAsFixed(2)} km'),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: walkedRoute.first,
                zoom: 14.0,
              ),
              polylines: {
                Polyline(
                  polylineId: PolylineId('walkedRoute'),
                  points: walkedRoute,
                  width: 5,
                  color: Colors.blue,
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
