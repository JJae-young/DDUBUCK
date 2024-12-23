import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test2/function/record/record_page.dart';

class DdubuckMapii extends StatefulWidget {
  final List<LatLng>? route;
  final Duration? time;
  final double? distance;

  DdubuckMapii({this.route, this.time, this.distance});

  @override
  _DdubuckMapiiState createState() => _DdubuckMapiiState();
}

class _DdubuckMapiiState extends State<DdubuckMapii> {
  GoogleMapController? _mapController;
  List<LatLng> _walkedRoute = [];
  LocationData? _currentLocation;
  DateTime? _startTime;
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  bool _isTracking = false;
  double _distance = 0.0;
  final Location _location = Location();

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    if (widget.route != null) {
      _walkedRoute = widget.route!;
    }
  }

  Future<void> _getUserLocation() async {
    LocationData locationData = await _location.getLocation();
    setState(() {
      _currentLocation = locationData;
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(locationData.latitude!, locationData.longitude!),
            zoom: 14.0,
          ),
        ),
      );
    });
  }

  void _startExercise() {
    setState(() {
      _isTracking = true;
      _walkedRoute.clear();
      _distance = 0.0;
      _startTime = DateTime.now();
      _elapsedTime = Duration.zero;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = DateTime.now().difference(_startTime!);
      });
    });

    _location.onLocationChanged.listen((locationData) {
      if (_walkedRoute.isNotEmpty) {
        final lastPoint = _walkedRoute.last;
        final distanceBetween = _calculateDistance(lastPoint, LatLng(locationData.latitude!, locationData.longitude!));
        setState(() {
          _distance += distanceBetween;
        });
      }

      setState(() {
        _walkedRoute.add(LatLng(locationData.latitude!, locationData.longitude!));
      });
    });
  }

  void _stopExercise() {
    _timer?.cancel();
    setState(() {
      _isTracking = false;
    });

    if (widget.route == null) {
      SharedPreferences.getInstance().then((prefs) {
        List<String> recordsAsJson = prefs.getStringList('exercise_records') ?? [];
        recordsAsJson.add(jsonEncode({
          'route': _walkedRoute.map((latLng) => {'lat': latLng.latitude, 'lng': latLng.longitude}).toList(),
          'time': _elapsedTime.inSeconds,
          'distance': _distance,
          'date': DateTime.now().toIso8601String(),
        }));
        prefs.setStringList('exercise_records', recordsAsJson);
      });
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('운동 완료!'),
          content: Text('수고하셨습니다!!\n기록하였습니다'),
          actions: <Widget>[
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('기록 보기'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RecordPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadiusKm = 6371;
    final double dLat = _degreeToRadian(end.latitude - start.latitude);
    final double dLon = _degreeToRadian(end.longitude - start.longitude);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreeToRadian(start.latitude)) *
            cos(_degreeToRadian(end.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreeToRadian(double degree) {
    return degree * pi / 180;
  }

  double _calculateAverageSpeed() {
    if (_elapsedTime.inSeconds == 0) return 0.0;
    double timeInHours = _elapsedTime.inSeconds / 3600.0;
    return _distance / timeInHours;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  myLocationButtonEnabled: false,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_currentLocation?.latitude ?? 0, _currentLocation?.longitude ?? 0),
                    zoom: 14.0,
                  ),
                  polylines: {
                    if (_walkedRoute.isNotEmpty)
                      Polyline(
                        polylineId: PolylineId('walkedRoute'),
                        points: _walkedRoute,
                        width: 5,
                        color: Colors.blue,
                      ),
                  },
                  myLocationEnabled: true,
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: FloatingActionButton(
                    heroTag: "btn1",
                    backgroundColor: Colors.green,
                    child: Icon(
                        Icons.my_location,
                        color: Colors.white,),
                    onPressed: _getUserLocation,
                  ),
                ),
                Positioned(
                  top: 100,
                  right: 20,
                  child: FloatingActionButton(
                    heroTag: "btn2",
                    backgroundColor: Colors.green,
                    child: Icon(
                      Icons.calendar_today,
                      color: Colors.white,),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RecordPage()),
                      );
                    },
                  ),
                ),
                SlidingUpPanel(
                  panel: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        Container(
                          width: 50,
                          height: 5,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(height: 16),


                        if (!_isTracking) ...[
                          Center(
                            child: Text(
                              '일단 뚜벅',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.map, size: 30, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(
                                    '할 수 있는 만큼 뚜벅',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Text(
                                '',
                                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),


                          ElevatedButton(
                            onPressed: _startExercise,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              textStyle: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: const Text('운동 시작'),
                          ),
                          const SizedBox(height: 12),
                        ],


                        if (_isTracking) ...[

                          Center(
                            child: Text(
                              '일단 뚜벅',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.directions_walk, size: 30, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(
                                    '움직인 거리:',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Text(
                                '${_distance.toStringAsFixed(2)} km',
                                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.timer, size: 30, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    '운동 시간:',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Text(
                                '${_elapsedTime.inMinutes}:${(_elapsedTime.inSeconds % 60).toString().padLeft(2, '0')}',
                                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),


                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.speed, size: 30, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Text(
                                    '평균 속도:',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Text(
                                '${_calculateAverageSpeed().toStringAsFixed(2)} km/h',
                                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          ElevatedButton(
                            onPressed: _stopExercise,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              textStyle: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: const Text('운동 종료'),
                          ),
                          const SizedBox(height: 20),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  minHeight: 90,
                  maxHeight: 400,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  body: Container(),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
