// lib/function/ddubuck/screens/map_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:test2/function/ddubuck/services/directions_service.dart';
import 'package:test2/function/ddubuck/utils/location_utils.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LocationData? _currentLocation;
  LatLng? _currentLatLng;
  Set<Marker> _markers = Set<Marker>();
  Set<Polyline> _polylines = Set<Polyline>();
  List<LatLng> _polylinePoints = [];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    Location location = Location();
    LocationData locationData = await location.getLocation();

    if (locationData.latitude != null && locationData.longitude != null) {
      setState(() {
        _currentLocation = locationData;
        _currentLatLng = LatLng(locationData.latitude!, locationData.longitude!);

        // 현재 위치에 마커 추가
        _markers.add(
          Marker(
            markerId: MarkerId('currentLocation'),
            position: _currentLatLng!,
            infoWindow: InfoWindow(title: 'Current Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );

        // 지도 카메라를 현재 위치로 이동
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentLatLng!,
              zoom: 14.0,
            ),
          ),
        );
      });
    }
  }

  Future<void> _createRandomRoute() async {
    if (_currentLatLng != null) {
      LocationUtils locationUtils = LocationUtils();
      LatLng randomDestination = locationUtils.generateRandomLocation(
        _currentLatLng!,
        2.5, // 2.5km 반경
      );

      DirectionsService directionsService = DirectionsService();
      var directions = await directionsService.getDirections(
        '${_currentLatLng!.latitude},${_currentLatLng!.longitude}',
        '${randomDestination.latitude},${randomDestination.longitude}',
      );

      setState(() {
        // 기존 경로 초기화
        _polylines.clear();
        _polylinePoints = _decodePolyline(directions['routes'][0]['overview_polyline']['points']);
        _addPolyline(_polylinePoints);

        // 목적지에 마커 추가
        _markers.add(
          Marker(
            markerId: MarkerId('destination'),
            position: randomDestination,
            infoWindow: InfoWindow(title: 'Destination'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      });
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }

  void _addPolyline(List<LatLng> polylinePoints) {
    Polyline polyline = Polyline(
      polylineId: PolylineId('route'),
      points: polylinePoints,
      width: 5,
      color: Colors.blue,
    );

    setState(() {
      _polylines.add(polyline);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Walking Route'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(37.7749, -122.4194), // 기본 위치 (샌프란시스코)
              zoom: 14.0,
            ),
            markers: _markers,
            polylines: _polylines,
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _createRandomRoute,  // 버튼을 눌러 경로 생성
              child: Icon(Icons.directions),
              tooltip: 'Create Route',
            ),
          ),
        ],
      ),
    );
  }
}
