import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:test2/function/record/calendar_screen.dart';
import 'package:intl/intl.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:test2/function/record/record_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '뚜벅뚜벅 기본 경로',
      home: DdubuckMapScreen(),
    );
  }
}


class ExerciseRecord {
  final List<LatLng> route;
  final Duration time;
  final double distance;
  final DateTime date;

  ExerciseRecord({
    required this.route,
    required this.time,
    required this.distance,
    required this.date,
  });
}

List<ExerciseRecord> exerciseRecords = [];

class DdubuckMapScreen extends StatefulWidget {
  @override
  _DdubuckMapScreenState createState() => _DdubuckMapScreenState();
}

class _DdubuckMapScreenState extends State<DdubuckMapScreen> {
  GoogleMapController? _mapController;
  List<LatLng> _walkedRoute = [];
  List<List<LatLng>> _allRoutes = [];
  List<double> _routeDistances = [];
  LocationData? _currentLocation;
  DateTime? _startTime;
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  bool _isTracking = false;
  double _distance = 0.0;
  int _selectedRouteIndex = -1;
  bool _isLoadingRoutes = true;
  final String mapboxApiKey = 'pk.eyJ1IjoiamFlc3NhZW0iLCJhIjoiY20wemR4Z2UwMDQwbTJqczRmcXZvdWk0biJ9.g8tnSPvhGa3kSlZA_hwW8Q';
  final Location _location = Location();


  Widget _buildIconInfo(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 40, color: Colors.blue),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadExerciseRecords();
  }

  Future<void> _saveExerciseRecords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String> recordsAsJson = exerciseRecords.map((record) {
      return jsonEncode({
        'route': record.route.map((latLng) => {'lat': latLng.latitude, 'lng': latLng.longitude}).toList(),
        'time': record.time.inSeconds,
        'distance': record.distance,
        'date': record.date.toIso8601String(),
      });
    }).toList();

    await prefs.setStringList('exercise_records', recordsAsJson);
  }

  Future<void> _loadExerciseRecords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? recordsAsJson = prefs.getStringList('exercise_records');

    if (recordsAsJson != null) {
      setState(() {
        exerciseRecords = recordsAsJson.map((recordJson) {
          Map<String, dynamic> recordMap = jsonDecode(recordJson);
          return ExerciseRecord(
            route: (recordMap['route'] as List).map((point) {
              return LatLng(point['lat'], point['lng']);
            }).toList(),
            time: Duration(seconds: recordMap['time']),
            distance: recordMap['distance'],
            date: DateTime.parse(recordMap['date']),
          );
        }).toList();
      });
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
      _createRandomRoutes();
    });
  }

  List<LatLng> _generateRandomWaypoints(LatLng currentLatLng, double minRadiusKm, double maxRadiusKm, int numWaypoints) {
    final random = Random();
    List<LatLng> waypoints = [];

    for (int i = 0; i < numWaypoints; i++) {
      final double radiusKm = minRadiusKm + random.nextDouble() * (maxRadiusKm - minRadiusKm);
      final double radiusInMeters = radiusKm * 1000;

      final double angle = random.nextDouble() * 2 * pi;
      final double distance = random.nextDouble() * radiusInMeters;

      final double dx = distance * cos(angle);
      final double dy = distance * sin(angle);

      final double deltaLat = dy / 111000;
      final double deltaLng = dx / (111000 * cos(currentLatLng.latitude * pi / 180));

      waypoints.add(LatLng(currentLatLng.latitude + deltaLat, currentLatLng.longitude + deltaLng));
    }

    return waypoints;
  }

  Future<void> _createRandomRoutes() async {
    setState(() {
      _isLoadingRoutes = true;
    });

    if (_currentLocation == null) return;

    LatLng currentLatLng = LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);

    for (int i = 0; i < 4; i++) {
      List<LatLng> waypoints;
      double routeDistanceKm = 0;
      int retryCount = 0;

      do {

        waypoints = _generateRandomWaypoints(currentLatLng, 0.8, 1.2, 3);
        routeDistanceKm = await _createRouteWithWaypoints(currentLatLng, waypoints);
        retryCount++;
      } while ((routeDistanceKm < 3 || routeDistanceKm > 4) && retryCount < 10);

      if (retryCount >= 10 && (routeDistanceKm < 3 || routeDistanceKm > 4)) {
        continue;
      }
    }

    setState(() {
      _isLoadingRoutes = false;
    });
  }


  Future<double> _createRouteWithWaypoints(LatLng startPoint, List<LatLng> waypoints) async {
    String waypointString = waypoints.map((wp) => '${wp.longitude},${wp.latitude}').join(';');
    final String url = 'https://api.mapbox.com/directions/v5/mapbox/walking/'
        '${startPoint.longitude},${startPoint.latitude};$waypointString;'
        '${startPoint.longitude},${startPoint.latitude}?'
        'geometries=polyline&access_token=$mapboxApiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['routes'].isNotEmpty) {
        final route = jsonResponse['routes'][0]['geometry'];
        final List<LatLng> polylinePoints = _decodePolyline(route);

        final double routeDistanceMeters = jsonResponse['routes'][0]['distance'];
        final double routeDistanceKm = routeDistanceMeters / 1000.0;

        setState(() {
          _allRoutes.add(polylinePoints);
          _routeDistances.add(routeDistanceKm);
        });

        return routeDistanceKm;
      }
    } else {
      print('Failed to load directions');
    }
    return 0;
  }

  List<LatLng> _decodePolyline(String polyline) {
    List<LatLng> points = [];
    int index = 0, len = polyline.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  void _showRoute(int index) {
    if (index >= 0 && index < _allRoutes.length) {
      setState(() {
        _selectedRouteIndex = index;
      });
    } else {
      print("Invalid route index: $index");
    }
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

    exerciseRecords.add(
      ExerciseRecord(
        route: List<LatLng>.from(_walkedRoute),
        time: _elapsedTime,
        distance: _distance,
        date: DateTime.now(),
      ),
    );

    _saveExerciseRecords();

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
                  MaterialPageRoute(
                    builder: (context) => CalendarPage(
                      walkedRoute: _walkedRoute,
                      time: _elapsedTime,
                      distance: _distance,
                    ),
                  ),
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


  double _calculateAverageSpeed(double distanceKm, Duration time) {
    double timeInHours = time.inSeconds / 3600.0;
    if (timeInHours > 0) {
      return distanceKm / timeInHours;
    } else {
      return 0.0;
    }
  }


  String calculateEstimatedTime(double distanceKm) {
    const double averageSpeedKmh = 4.0;
    double estimatedTimeHours = distanceKm / averageSpeedKmh;

    int estimatedTimeMinutes = (estimatedTimeHours * 60).round();


    int hours = estimatedTimeMinutes ~/ 60;
    int minutes = estimatedTimeMinutes % 60;


    if (hours > 0) {
      return '$hours hr $minutes min';
    } else {
      return '$minutes min';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_isLoadingRoutes)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/thinking.png', height: 200),
                  SizedBox(height: 20),
                  Text(
                    '지도를 찾고 있어요',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
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
              if (_selectedRouteIndex != -1)
                Polyline(
                  polylineId: PolylineId('route_$_selectedRouteIndex'),
                  points: _allRoutes[_selectedRouteIndex],
                  width: 5,
                  color: Colors.deepPurple,
                ),
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
            right: 10,
            left: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                return ElevatedButton(
                  onPressed: () => _showRoute(index),
                  child: Text('코스 ${index + 1}'),
                );
              }),
            ),
          ),
          Positioned(
            top: 100,
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
            top: 160,
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


                  if (!_isTracking && _selectedRouteIndex != -1) ...[

                    Center(
                      child: Text(
                        '선택된 코스: 코스 ${_selectedRouteIndex + 1}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 예상 거리 섹션
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.map, size: 30, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              '도보 거리:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Text(
                          '${_routeDistances[_selectedRouteIndex].toStringAsFixed(2)} km',
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
                              '예상 소요 시간:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Text(
                          calculateEstimatedTime(_routeDistances[_selectedRouteIndex]),
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
                      child: const Text('Start Exercise'),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (_isTracking) ...[
                    Center(
                      child: Text(
                        '현재 코스: 코스 ${_selectedRouteIndex + 1}',
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
                              '남은 거리:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Text(
                          '${(5.0 - _distance).clamp(0.0, 5.0).toStringAsFixed(2)} km',
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
                          '${_calculateAverageSpeed(_distance, _elapsedTime).toStringAsFixed(1)} km/h',
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
                      child: const Text('Stop Exercise'),
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
          ),
        ],
      ),
    );
  }

}
