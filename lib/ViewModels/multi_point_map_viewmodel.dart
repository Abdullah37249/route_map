import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import '../Database/db_service.dart';


class MultiPointMapViewModel {
  final bool isEditMode;
  final List<Map<String, dynamic>>? existingWaypoints;
  final int? routeId;
  final int? segmentToEdit;

  final List<LatLng> waypoints = [];
  final List<Map<String, dynamic>> waypointInfo = [];
  final List<LatLng> routePoints = [];
  final List<double> segmentDistances = [];
  final List<String> segmentDurations = [];

  double totalDistance = 0;
  String totalDuration = '';

  final List<String> waypointNames = [];

  MultiPointMapViewModel({
    this.isEditMode = false,
    this.existingWaypoints,
    this.routeId,
    this.segmentToEdit,
  }) {
    if (isEditMode && existingWaypoints != null) {
      _loadExistingWaypoints();
    } else {
      // Initialize with 2 waypoints for new route
      waypoints.add(LatLng(0, 0));
      waypoints.add(LatLng(0, 0));
      waypointInfo.add({});
      waypointInfo.add({});
      waypointNames.add('');
      waypointNames.add('');
    }
  }

  void _loadExistingWaypoints() {
    if (existingWaypoints == null) return;

    for (final waypoint in existingWaypoints!) {
      final lat = waypoint['lat'] as double? ?? 0.0;
      final lng = waypoint['lng'] as double? ?? 0.0;

      if (lat != 0.0 && lng != 0.0) {
        waypoints.add(LatLng(lat, lng));
        waypointInfo.add(waypoint);
        waypointNames.add(waypoint['name']?.toString() ?? '');
      }
    }
  }

  void addWaypoint() {
    waypoints.add(LatLng(0, 0));
    waypointInfo.add({});
    waypointNames.add('');
  }

  void removeWaypoint(int index) {
    if (waypoints.length > 2) {
      waypoints.removeAt(index);
      waypointInfo.removeAt(index);
      waypointNames.removeAt(index);
    }
  }

  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.isEmpty || query.length < 3) return [];

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?'
            'q=${Uri.encodeQueryComponent(query)}'
            '&format=json'
            '&addressdetails=1'
            '&limit=10',
      );

      final res = await http.get(
        url,
        headers: {
          'User-Agent': 'FlutterMapRoutingApp/1.0',
          'Accept-Language': 'en',
        },
      ).timeout(Duration(seconds: 5));

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((item) {
          return {
            'lat': item['lat'],
            'lon': item['lon'],
            'display_name': item['display_name'],
            'type': item['type'] ?? 'unknown',
          };
        }).toList();
      }
    } catch (e) {
      print('Search error: $e');
    }
    return [];
  }

  void setWaypoint(int index, Map<String, dynamic> place) {
    final lat = double.tryParse(place['lat'].toString()) ?? 0.0;
    final lon = double.tryParse(place['lon'].toString()) ?? 0.0;

    if (lat == 0.0 || lon == 0.0) return;

    waypoints[index] = LatLng(lat, lon);
    waypointInfo[index] = {
      'lat': lat,
      'lng': lon,
      'name': place['display_name'] ?? 'Waypoint ${index + 1}',
      'address': place['display_name'] ?? '',
    };
    waypointNames[index] = place['display_name'] ?? '';
  }

  Future<void> onMapTap(LatLng point) async {
    int emptyIndex = -1;
    for (int i = 0; i < waypoints.length; i++) {
      if (waypoints[i] == LatLng(0, 0)) {
        emptyIndex = i;
        break;
      }
    }

    if (emptyIndex == -1) {
      addWaypoint();
      emptyIndex = waypoints.length - 1;
    }

    final index = emptyIndex;
    waypoints[index] = point;
    waypointNames[index] = 'Loading address...';

    // Reverse geocode
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?'
            'lat=${point.latitude}'
            '&lon=${point.longitude}'
            '&format=json'
            '&addressdetails=1',
      );

      final res = await http
          .get(url, headers: {'User-Agent': 'FlutterMapRoutingApp/1.0'})
          .timeout(Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final address = data['display_name'] ??
            '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';

        waypointInfo[index] = {
          'lat': point.latitude,
          'lng': point.longitude,
          'name': 'Waypoint ${index + 1}',
          'address': address,
        };
        waypointNames[index] = address;
      }
    } catch (e) {
      print('Reverse geocoding error: $e');
      waypointInfo[index] = {
        'lat': point.latitude,
        'lng': point.longitude,
        'name': 'Waypoint ${index + 1}',
        'address': '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
      };
      waypointNames[index] = '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
    }
  }

  Future<void> calculateRoute() async {
    final validWaypoints = waypoints.where((point) => point != LatLng(0, 0)).toList();
    if (validWaypoints.length < 2) {
      throw Exception('Please select at least 2 points');
    }

    try {
      segmentDistances.clear();
      segmentDurations.clear();
      routePoints.clear();
      List<LatLng> allRoutePoints = [];
      double cumulativeDistance = 0;

      for (int i = 0; i < validWaypoints.length - 1; i++) {
        final start = validWaypoints[i];
        final end = validWaypoints[i + 1];

        final segmentResult = await _calculateSegment(start, end);
        if (segmentResult != null) {
          final points = segmentResult['points'] as List<LatLng>;
          final distance = segmentResult['distance'] as double;
          final duration = segmentResult['duration'] as String;

          allRoutePoints.addAll(points);
          cumulativeDistance += distance;
          segmentDistances.add(distance);
          segmentDurations.add(duration);
        }
      }

      int totalSeconds = 0;
      for (final duration in segmentDurations) {
        totalSeconds += _durationToSeconds(duration);
      }

      routePoints.addAll(allRoutePoints);
      totalDistance = cumulativeDistance;
      totalDuration = _formatDuration(totalSeconds.toDouble());
    } catch (e) {
      print('Error calculating route: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _calculateSegment(LatLng start, LatLng end) async {
    try {
      final url = Uri.parse(
        "https://router.project-osrm.org/route/v1/driving/"
            "${start.longitude},${start.latitude};"
            "${end.longitude},${end.latitude}"
            "?overview=full&geometries=geojson&steps=true&annotations=true",
      );

      final res = await http.get(url).timeout(Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coords = route['geometry']['coordinates'] as List;
          final dur = route['duration'];
          final dist = route['distance'];

          final points = coords.map((c) => LatLng(c[1], c[0])).toList();
          final distance = dist / 1000;
          final duration = _formatDuration(dur);

          return {'points': points, 'distance': distance, 'duration': duration};
        }
      }
    } catch (e) {
      print('Segment calculation error: $e');
    }
    return null;
  }

  int _durationToSeconds(String duration) {
    try {
      if (duration.contains('h')) {
        final parts = duration.split('h');
        final hours = int.tryParse(parts[0].trim()) ?? 0;
        final minutesStr = parts[1].replaceAll('min', '').trim();
        final minutes = int.tryParse(minutesStr) ?? 0;
        return (hours * 3600) + (minutes * 60);
      } else {
        final minutesStr = duration.replaceAll('min', '').trim();
        final minutes = int.tryParse(minutesStr) ?? 0;
        return minutes * 60;
      }
    } catch (e) {
      return 0;
    }
  }

  String _formatDuration(double seconds) {
    final hours = (seconds / 3600).floor();
    final minutes = ((seconds % 3600) / 60).floor();

    if (hours > 0) {
      return '$hours h ${minutes} min';
    }
    return '$minutes min';
  }

  Future<void> saveEditedRoute() async {
    if (!isEditMode || routeId == null) {
      throw Exception('Not in edit mode or routeId is null');
    }

    final validWaypoints = waypoints.where((point) => point != LatLng(0, 0)).toList();
    if (validWaypoints.length < 2 || routePoints.isEmpty || segmentDistances.isEmpty) {
      throw Exception('Please calculate a route first');
    }

    await DBHelper.deleteLocalRoute(routeId!);

    final List<Map<String, dynamic>> waypointData = [];
    for (int i = 0; i < validWaypoints.length; i++) {
      final point = validWaypoints[i];
      final info = waypointInfo[i];

      waypointData.add({
        'name': info['name'] ?? 'Waypoint ${i + 1}',
        'lat': point.latitude,
        'lng': point.longitude,
        'address': info['address'] ?? '',
      });
    }

    final newRouteId = await DBHelper.insertMultiPointRoute(
      waypoints: waypointData,
      segmentDistances: segmentDistances,
      segmentDurations: segmentDurations,
      totalDistance: totalDistance,
      totalDuration: totalDuration,
      province: 'Punjab',
      city: 'Sialkot',
      date: DateTime.now().toIso8601String().split('T')[0],
    );

    // Return new route ID or true for success
  }

  void clearAll() {
    waypoints.clear();
    waypointInfo.clear();
    routePoints.clear();
    segmentDistances.clear();
    segmentDurations.clear();
    waypointNames.clear();
    totalDistance = 0;
    totalDuration = '';

    if (isEditMode && existingWaypoints != null) {
      _loadExistingWaypoints();
    } else {
      waypoints.add(LatLng(0, 0));
      waypoints.add(LatLng(0, 0));
      waypointInfo.add({});
      waypointInfo.add({});
      waypointNames.add('');
      waypointNames.add('');
    }
  }

  void reorderWaypoint(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;

    final waypoint = waypoints.removeAt(oldIndex);
    final info = waypointInfo.removeAt(oldIndex);
    final name = waypointNames.removeAt(oldIndex);

    waypoints.insert(newIndex, waypoint);
    waypointInfo.insert(newIndex, info);
    waypointNames.insert(newIndex, name);
  }

  String getWaypointName(int index) => waypointNames[index];
  void setWaypointName(int index, String name) => waypointNames[index] = name;
}