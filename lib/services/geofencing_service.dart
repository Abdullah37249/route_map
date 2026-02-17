// lib/geofancing/geofencing_service.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class GeofencingService {
  static final GeofencingService _instance = GeofencingService._internal();
  factory GeofencingService() => _instance;
  GeofencingService._internal();

  final GeolocatorPlatform _geolocator = GeolocatorPlatform.instance;

  bool _isMonitoring = false;
  List<LatLng> _routePoints = [];
  double _routeBufferDistance = 50.0; // meters
  StreamSubscription<Position>? _positionStream;

  // Notifiers for UI
  ValueNotifier<bool> isOnRoute = ValueNotifier<bool>(false);
  ValueNotifier<double> distanceToRoute = ValueNotifier<double>(0.0);
  ValueNotifier<String> geofenceStatus = ValueNotifier<String>('Idle');

  // Callbacks
  Function(String)? _onStatusChange;
  Function(String, String)? _onRouteChange;

  // Set callback for status updates (general)
  void setStatusCallback(Function(String) callback) => _onStatusChange = callback;

  // Set callback for on/off route updates (status, message)
  void setRouteChangeCallback(Function(String, String) callback) => _onRouteChange = callback;

  // Update buffer (meters)
  void updateBufferDistance(double bufferDistance) {
    _routeBufferDistance = bufferDistance;
  }

  bool get isMonitoring => _isMonitoring;

  List<LatLng> get routePoints => List.from(_routePoints);

  // Convert lat/lng to planar meters using equirectangular approx (good for small areas)
  void _latLngToMeters(LatLng p, double latRefRad, double R, List<double> out) {
    final latRad = p.latitude * pi / 180.0;
    final lonRad = p.longitude * pi / 180.0;
    out[0] = R * lonRad * cos(latRefRad);
    out[1] = R * latRad;
  }

  // Distance from point to segment in meters (planar)
  double _distanceToSegment(LatLng point, LatLng a, LatLng b) {
    const double R = 6371000.0;
    final latRefRad = ((point.latitude + a.latitude + b.latitude) / 3.0) * pi / 180.0;

    final pXY = [0.0, 0.0];
    final aXY = [0.0, 0.0];
    final bXY = [0.0, 0.0];

    _latLngToMeters(point, latRefRad, R, pXY);
    _latLngToMeters(a, latRefRad, R, aXY);
    _latLngToMeters(b, latRefRad, R, bXY);

    final px = pXY[0], py = pXY[1];
    final ax = aXY[0], ay = aXY[1];
    final bx = bXY[0], by = bXY[1];

    final vx = bx - ax;
    final vy = by - ay;
    final wx = px - ax;
    final wy = py - ay;

    final segLen2 = vx * vx + vy * vy;
    if (segLen2 == 0) {
      final dx = px - ax;
      final dy = py - ay;
      return sqrt(dx * dx + dy * dy);
    }

    final t = ((wx * vx) + (wy * vy)) / segLen2;
    if (t <= 0) {
      final dx = px - ax;
      final dy = py - ay;
      return sqrt(dx * dx + dy * dy);
    } else if (t >= 1) {
      final dx = px - bx;
      final dy = py - by;
      return sqrt(dx * dx + dy * dy);
    } else {
      final closestX = ax + t * vx;
      final closestY = ay + t * vy;
      final dx = px - closestX;
      final dy = py - closestY;
      return sqrt(dx * dx + dy * dy);
    }
  }

  // Minimum perpendicular distance (meters) from point to polyline
  double _findMinDistanceToRoute(LatLng point) {
    if (_routePoints.length < 2) return double.infinity;
    double minDistance = double.infinity;
    for (int i = 0; i < _routePoints.length - 1; i++) {
      final d = _distanceToSegment(point, _routePoints[i], _routePoints[i + 1]);
      if (d < minDistance) minDistance = d;
    }
    return minDistance;
  }

  // Start monitoring: routePoints must be the exact polyline (no modification)
  Future<void> startMonitoringRoute(List<LatLng> routePoints, {double bufferDistance = 50.0}) async {
    if (routePoints.isEmpty) throw Exception('Route polyline cannot be empty');

    // permissions
    LocationPermission permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        throw Exception('Location permission not granted');
      }
    }

    await stopMonitoring(); // stop previous

    _routePoints = List.from(routePoints);
    _routeBufferDistance = bufferDistance;
    _isMonitoring = true;
    geofenceStatus.value = 'Monitoring';
    _onStatusChange?.call('Geofencing started');

    // position stream (low distanceFilter for responsiveness)
    _positionStream = _geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    ).listen((Position pos) {
      final current = LatLng(pos.latitude, pos.longitude);
      final distance = _findMinDistanceToRoute(current);

      distanceToRoute.value = distance;

      final previouslyOnRoute = isOnRoute.value;
      final nowOnRoute = distance <= _routeBufferDistance;

      isOnRoute.value = nowOnRoute;

      if (!previouslyOnRoute && nowOnRoute) {
        geofenceStatus.value = 'On Route';
        _onRouteChange?.call('On Route', 'Back on the route');
      } else if (previouslyOnRoute && !nowOnRoute) {
        geofenceStatus.value = 'Off Route';
        _onRouteChange?.call('Off Route', 'You are off the route');
      }
    }, onError: (e) {
      _onStatusChange?.call('Geofencing error: $e');
    });
  }

  Future<void> stopMonitoring() async {
    await _positionStream?.cancel();
    _positionStream = null;
    _isMonitoring = false;
    _routePoints = [];
    isOnRoute.value = false;
    distanceToRoute.value = 0.0;
    geofenceStatus.value = 'Idle';
    _onStatusChange?.call('Geofencing stopped');
  }

  Map<String, dynamic> getStatus() {
    return {
      'isMonitoring': _isMonitoring,
      'isOnRoute': isOnRoute.value,
      'distanceToRoute': distanceToRoute.value,
      'status': geofenceStatus.value,
      'routePointsCount': _routePoints.length,
      'bufferDistance': _routeBufferDistance,
    };
  }
}