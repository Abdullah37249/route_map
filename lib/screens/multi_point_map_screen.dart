// file: lib/screens/multi_point_map_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_typeahead/flutter_typeahead.dart';



import '../services/geofencing_service.dart';
import 'real_time_navigation_screen.dart';
import 'save_multi_route_screen.dart';
import '../Database/db_service.dart';


class MultiPointMapScreen extends StatefulWidget {
  final bool isEditMode;
  final List<Map<String, dynamic>>? existingWaypoints;
  final int? routeId;
  final int? segmentToEdit;

  const MultiPointMapScreen({
    super.key,
    this.isEditMode = false,
    this.existingWaypoints,
    this.routeId,
    this.segmentToEdit,
  });

  factory MultiPointMapScreen.editMode({
    required List<Map<String, dynamic>> existingWaypoints,
    required int routeId,
    int? segmentToEdit,
  }) {
    return MultiPointMapScreen(
      isEditMode: true,
      existingWaypoints: existingWaypoints,
      routeId: routeId,
      segmentToEdit: segmentToEdit,
    );
  }

  @override
  State<MultiPointMapScreen> createState() => _MultiPointMapScreenState();
}

class _MultiPointMapScreenState extends State<MultiPointMapScreen> {
  final mapController = MapController();
  List<LatLng> waypoints = [];
  List<Map<String, dynamic>> waypointInfo = [];
  List<LatLng> routePoints = [];
  double totalDistance = 0;
  String totalDuration = '';
  List<double> segmentDistances = [];
  List<String> segmentDurations = [];
  String routeName = 'Unnamed Route'; // Added

  final List<TextEditingController> _waypointControllers = [];
  final List<FocusNode> _waypointFocusNodes = [];

  // Panel states
  bool _isPanelExpanded = true;
  bool _isCalculated = false;
  bool _isCalculating = false;
  bool _showRouteInfo = false;
  bool _showSaveButton = false;

  // Geofencing variables
  final GeofencingService _geofencingService = GeofencingService();
  bool _isGeofencingActive = false;
  double _geofenceBuffer = 50.0; // meters

  final List<Color> waypointColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEF4444), // Red
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
    Color(0xFFF97316), // Orange
    Color(0xFF8B5CF6), // Purple
  ];

  final List<IconData> waypointIcons = [
    Icons.location_on,
    Icons.flag,
    Icons.pin_drop,
    Icons.place,
    Icons.location_city,
    Icons.local_hotel,
    Icons.restaurant,
    Icons.shopping_cart,
    Icons.coffee,
    Icons.directions_car,
  ];

  @override
  void initState() {
    super.initState();

    if (widget.isEditMode && widget.existingWaypoints != null) {
      _loadExistingWaypoints();
    } else {
      _addWaypointField();
      _addWaypointField();
    }

    _initializeGeofencing();
  }

  @override
  void dispose() {
    for (var controller in _waypointControllers) {
      controller.dispose();
    }
    for (var focusNode in _waypointFocusNodes) {
      focusNode.dispose();
    }
    _geofencingService.stopMonitoring();
    super.dispose();
  }

  Future<void> _initializeGeofencing() async {
    // No initialization needed since we removed notifications
    // Set up callbacks for geofencing status updates
    _geofencingService.setRouteChangeCallback((status, message) {
      // Show snackbar for route status changes
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: status == 'On Route' ? Colors.green : Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    });

    _geofencingService.setStatusCallback((message) {
      // You can handle general status messages here if needed
      print('Geofencing status: $message');
    });
  }

  Future<void> _toggleGeofencing() async {
    if (_isGeofencingActive) {
      await _geofencingService.stopMonitoring();
      setState(() {
        _isGeofencingActive = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Geofencing stopped'),
          backgroundColor: Colors.blue,
        ),
      );
    } else {
      if (routePoints.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please calculate a route first'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      try {
        await _geofencingService.startMonitoringRoute(
          routePoints,
          bufferDistance: _geofenceBuffer,
        );

        setState(() {
          _isGeofencingActive = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Geofencing activated for route'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start geofencing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateGeofenceBuffer(double value) {
    setState(() {
      _geofenceBuffer = value;
    });
    // Update the buffer distance in the geofencing service
    _geofencingService.updateBufferDistance(value);
  }

  Future<void> _showGeofenceSettings() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Geofence Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Buffer Distance: ${_geofenceBuffer.round()}m'),
            Slider(
              value: _geofenceBuffer,
              min: 10,
              max: 200,
              divisions: 19,
              onChanged: _updateGeofenceBuffer,
              label: '${_geofenceBuffer.round()}m',
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Small (20m)'),
                Text('Medium (50m)'),
                Text('Large (100m)'),
              ],
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('Geofencing Active'),
              value: _isGeofencingActive,
              onChanged: (value) => _toggleGeofencing(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _loadExistingWaypoints() {
    if (widget.existingWaypoints == null) return;

    setState(() {
      for (final waypoint in widget.existingWaypoints!) {
        final lat = waypoint['lat'] as double? ?? 0.0;
        final lng = waypoint['lng'] as double? ?? 0.0;

        if (lat != 0.0 && lng != 0.0) {
          waypoints.add(LatLng(lat, lng));
          waypointInfo.add(waypoint);

          _waypointControllers.add(
            TextEditingController(text: waypoint['name']?.toString() ?? ''),
          );
          _waypointFocusNodes.add(FocusNode());
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _invalidateCalculation();
      _autoCalculateIfReady();
      // If editing existing route, show route info
      if (widget.isEditMode) {
        setState(() {
          _showRouteInfo = true;
          _showSaveButton = true;
        });
      }
    });
  }

  void _addWaypointField() {
    setState(() {
      _waypointControllers.add(TextEditingController());
      _waypointFocusNodes.add(FocusNode());
      waypoints.add(LatLng(0, 0));
      waypointInfo.add({});
      _invalidateCalculation();
      _showSaveButton = false;
    });
  }

  void _removeWaypointField(int index) {
    if (_waypointControllers.length > 2) {
      setState(() {
        _waypointControllers[index].dispose();
        _waypointFocusNodes[index].dispose();
        _waypointControllers.removeAt(index);
        _waypointFocusNodes.removeAt(index);
        waypoints.removeAt(index);
        waypointInfo.removeAt(index);
        _invalidateCalculation();
      });

      _autoCalculateIfReady();
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

      final res = await http
          .get(
        url,
        headers: {
          'User-Agent': 'FlutterMapRoutingApp/1.0',
          'Accept-Language': 'en',
        },
      )
          .timeout(const Duration(seconds: 5));

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
      debugPrint('Search error: $e');
    }
    return [];
  }

  void setWaypoint(int index, Map<String, dynamic> place) {
    final lat = double.tryParse(place['lat'].toString()) ?? 0.0;
    final lon = double.tryParse(place['lon'].toString()) ?? 0.0;

    if (lat == 0.0 || lon == 0.0) return;

    setState(() {
      waypoints[index] = LatLng(lat, lon);
      waypointInfo[index] = {
        'lat': lat,
        'lng': lon,
        'name': place['display_name'] ?? 'Waypoint ${index + 1}', // This should use the address
        'address': place['display_name'] ?? '',
      };
      _waypointControllers[index].text = place['display_name'] ?? '';
      _invalidateCalculation();
    });

    mapController.move(LatLng(lat, lon), 14);
    _autoCalculateIfReady();

    // Auto-collapse panel when waypoint is selected
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isPanelExpanded = false;
        });
      }
    });
  }

  void onMapTap(TapPosition tapPosition, LatLng point) async {
    int emptyIndex = -1;
    for (int i = 0; i < waypoints.length; i++) {
      if (waypoints[i] == LatLng(0, 0)) {
        emptyIndex = i;
        break;
      }
    }

    if (emptyIndex == -1) {
      _addWaypointField();
      emptyIndex = waypoints.length - 1;
    }

    final index = emptyIndex;
    setState(() {
      waypoints[index] = point;
      _waypointControllers[index].text = 'Loading address...';
      _invalidateCalculation();
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?'
            'lat=${point.latitude}&lon=${point.longitude}'
            '&format=json&addressdetails=1',
      );

      final res = await http
          .get(url, headers: {'User-Agent': 'FlutterMapRoutingApp/1.0'})
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final address = data['display_name'] ??
            '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';

        setState(() {
          waypointInfo[index] = {
            'lat': point.latitude,
            'lng': point.longitude,
            'name': address, // Changed from 'Waypoint ${index + 1}' to use the actual address
            'address': address,
          };
          _waypointControllers[index].text = address;
        });
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
      final fallbackAddress = '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
      setState(() {
        waypointInfo[index] = {
          'lat': point.latitude,
          'lng': point.longitude,
          'name': fallbackAddress, // Changed from 'Waypoint ${index + 1}' to use coordinates
          'address': fallbackAddress,
        };
        _waypointControllers[index].text = fallbackAddress;
      });
    }

    _autoCalculateIfReady();

    // Auto-collapse panel when map is tapped
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isPanelExpanded = false;
        });
      }
    });
  }

  bool get _allWaypointsSet {
    if (waypoints.length < 2) return false;
    for (final p in waypoints) {
      if (p == LatLng(0, 0)) return false;
    }
    return true;
  }

  void _autoCalculateIfReady() {
    if (!_allWaypointsSet) return;
    if (_isCalculating) return;

    _isCalculating = true;
    calculateRoute().whenComplete(() {
      _isCalculating = false;
    });
  }

  void _invalidateCalculation() {
    if (mounted) {
      setState(() {
        _isCalculated = false;
        _showRouteInfo = false;
        _showSaveButton = false;
      });
    }
  }

  Future<void> calculateRoute() async {
    final validWaypoints =
    waypoints.where((p) => p != LatLng(0, 0)).toList();
    if (validWaypoints.length < 2) {
      if (mounted) {
        setState(() {
          _isCalculated = false;
          _showRouteInfo = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _showRouteInfo = true;
      });
    }

    try {
      segmentDistances.clear();
      segmentDurations.clear();
      List<LatLng> allRoutePoints = [];
      double cumulativeDistance = 0;

      for (int i = 0; i < validWaypoints.length - 1; i++) {
        final start = validWaypoints[i];
        final end = validWaypoints[i + 1];

        final segment = await _calculateSegment(start, end);
        if (segment != null) {
          allRoutePoints.addAll(segment['points'] as List<LatLng>);
          cumulativeDistance += segment['distance'] as double;
          segmentDistances.add(segment['distance'] as double);
          segmentDurations.add(segment['duration'] as String);
        } else {
          if (mounted) {
            setState(() {
              _isCalculated = false;
              _showRouteInfo = false;
            });
          }
          return;
        }
      }

      int totalSeconds = 0;
      for (final dur in segmentDurations) {
        totalSeconds += _durationToSeconds(dur);
      }

      if (mounted) {
        setState(() {
          routePoints = allRoutePoints;
          totalDistance = cumulativeDistance;
          totalDuration = _formatDuration(totalSeconds.toDouble());
          _isCalculated = true;
          _showSaveButton = true;
        });
      }

      _fitMapToRoute();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Route calculated successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCalculated = false;
          _showRouteInfo = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to calculate route'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _calculateSegment(LatLng start, LatLng end) async {
    try {
      final url = Uri.parse(
        "https://router.project-osrm.org/route/v1/driving/"
            "${start.longitude},${start.latitude};${end.longitude},${end.latitude}"
            "?overview=full&geometries=geojson&steps=true&annotations=true",
      );

      final res = await http.get(url).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coords = route['geometry']['coordinates'] as List;
          final dur = route['duration'] as num;
          final dist = route['distance'] as num;

          final points = coords.map((c) => LatLng(c[1], c[0])).toList();

          return {
            'points': points,
            'distance': dist / 1000,
            'duration': _formatDuration(dur.toDouble()),
          };
        }
      }
    } catch (e) {
      debugPrint('Segment error: $e');
    }
    return null;
  }

  int _durationToSeconds(String duration) {
    try {
      if (duration.contains('h')) {
        final parts = duration.split('h');
        final h = int.tryParse(parts[0].trim()) ?? 0;
        final mStr = parts[1].replaceAll('min', '').trim();
        final m = int.tryParse(mStr) ?? 0;
        return (h * 3600) + (m * 60);
      } else {
        final m = int.tryParse(duration.replaceAll('min', '').trim()) ?? 0;
        return m * 60;
      }
    } catch (_) {
      return 0;
    }
  }

  String _formatDuration(double seconds) {
    final h = (seconds / 3600).floor();
    final m = ((seconds % 3600) / 60).floor();
    if (h > 0) return '$h h $m min';
    return '$m min';
  }

  void _fitMapToRoute() {
    if (routePoints.isEmpty) return;

    double minLat = routePoints[0].latitude;
    double maxLat = routePoints[0].latitude;
    double minLng = routePoints[0].longitude;
    double maxLng = routePoints[0].longitude;

    for (final p in routePoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  List<Polyline> _buildSegmentPolylines() {
    if (routePoints.isEmpty || segmentDistances.isEmpty) return [];

    final List<Polyline> polylines = [];
    final segmentColors = waypointColors;

    int startIndex = 0;
    final pointsPerSegment = (routePoints.length / segmentDistances.length).ceil();

    for (int i = 0; i < segmentDistances.length; i++) {
      int endIndex = (startIndex + pointsPerSegment).clamp(0, routePoints.length);

      if (endIndex > startIndex) {
        final segmentPoints = routePoints.sublist(startIndex, endIndex);

        polylines.add(
          Polyline(
            points: segmentPoints,
            color: segmentColors[i % segmentColors.length],
            strokeWidth: 5.0,
            borderColor: Colors.white.withOpacity(0.8),
            borderStrokeWidth: 1.5,
          ),
        );
      }

      startIndex = endIndex;
    }

    if (startIndex < routePoints.length) {
      polylines.add(
        Polyline(
          points: routePoints.sublist(startIndex),
          color: segmentColors.last,
          strokeWidth: 5.0,
          borderColor: Colors.white.withOpacity(0.8),
          borderStrokeWidth: 1.5,
        ),
      );
    }

    return polylines;
  }

  Future<void> _saveEditedRoute() async {
    final validWaypoints = waypoints.where((p) => p != LatLng(0, 0)).toList();
    if (validWaypoints.length < 2 || routePoints.isEmpty || segmentDistances.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please calculate a route first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!widget.isEditMode || widget.routeId == null) return;

    final routeId = widget.routeId!;

    final List<Map<String, dynamic>> waypointData = [];
    for (int i = 0; i < validWaypoints.length; i++) {
      final point = validWaypoints[i];
      final info = (i < waypointInfo.length) ? waypointInfo[i] : {};
      waypointData.add({
        'name': info['name'] ?? 'Waypoint ${i + 1}',
        'lat': point.latitude,
        'lng': point.longitude,
        'address': info['address'] ?? '',
      });
    }

    String province = 'Punjab';
    String city = 'Sialkot';
    String date = DateTime.now().toIso8601String().split('T')[0];
    String routeName = this.routeName; // Use current route name

    try {
      final existingSegments = await DBHelper.getSegmentsByRouteId(routeId);
      if (existingSegments.isNotEmpty) {
        province = existingSegments.first['province']?.toString() ?? province;
        city = existingSegments.first['city']?.toString() ?? city;
        date = existingSegments.first['date']?.toString() ?? date;
        routeName = existingSegments.first['route_name']?.toString() ?? routeName;
      }

      final success = await DBHelper.editMultiPointRoute(
        routeId: routeId,
        waypoints: waypointData,
        segmentDistances: List<double>.from(segmentDistances),
        segmentDurations: List<String>.from(segmentDurations),
        totalDistance: totalDistance,
        totalDuration: totalDuration,
        province: province,
        city: city,
        date: date,
        routeName: routeName,
      );

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save updated route locally'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      bool deleted = await DBHelper.deleteRouteFromServer(routeId);
      if (!deleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: failed to delete previous route on server. Will still attempt to upload.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      final uploadResult = await DBHelper.saveRouteSegmentsToServer(routeId);

      if (uploadResult['success'] == true && (uploadResult['failed_segments'] ?? 0) == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Route updated successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        final failed = uploadResult['failed_segments'] ?? 0;
        final sent = uploadResult['sent_segments'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload result: sent $sent, failed $failed'),
            backgroundColor: failed == 0 ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving edited route: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving edited route: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void openSaveScreen() {
    if (!_isCalculated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait until route is calculated before saving'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (widget.isEditMode) {
      _saveEditedRoute();
      return;
    }

    final validWaypoints = waypoints.where((p) => p != LatLng(0, 0)).toList();
    if (validWaypoints.length < 2 || routePoints.isEmpty || segmentDistances.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please calculate a route first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SaveMultiRouteScreen(
          waypoints: waypointInfo.where((info) => info.isNotEmpty).toList(),
          segmentDistances: segmentDistances,
          segmentDurations: segmentDurations,
          totalDistance: totalDistance,
          totalDuration: totalDuration,
          initialRouteName: routeName, // Pass initial route name
        ),
      ),
    ).then((result) {
      // If a route name was provided from the save screen, update it
      if (result != null && result is String) {
        setState(() {
          routeName = result;
        });
      }
    });
  }

// lib/screens/multi_point_map_screen.dart
// Only small change shown: pass the exact generated route polyline to RealTimeNavigationScreen
// (replace the existing _startNavigationFromMultiPoint implementation with this snippet)

  void _startNavigationFromMultiPoint() async {
    if (!_isCalculated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please calculate a route first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (routePoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No route available for navigation'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Save route temporarily for navigation (existing behavior)
    final List<Map<String, dynamic>> waypointData = [];
    final validWaypoints = waypoints.where((p) => p != LatLng(0, 0)).toList();

    for (int i = 0; i < validWaypoints.length; i++) {
      final point = validWaypoints[i];
      final info = (i < waypointInfo.length) ? waypointInfo[i] : {};
      waypointData.add({
        'name': info['name'] ?? 'Waypoint ${i + 1}',
        'lat': point.latitude,
        'lng': point.longitude,
        'address': info['address'] ?? '',
      });
    }

    try {
      // Save to temporary route (still keep saving for history)
      final tempRouteId = await DBHelper.insertMultiPointRoute(
        waypoints: waypointData,
        segmentDistances: segmentDistances,
        segmentDurations: segmentDurations,
        totalDistance: totalDistance,
        totalDuration: totalDuration,
        province: 'Punjab',
        city: 'Sialkot',
        date: DateTime.now().toIso8601String().split('T')[0],
        routeName: routeName,
      );

      // IMPORTANT: pass the exact routePoints polyline to the navigation screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RealTimeNavigationScreen(
            routeId: tempRouteId,
            routePolyline: List<LatLng>.from(routePoints), // <-- exact polyline
            routeName: routeName,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start navigation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void clearAll() {
    setState(() {
      waypoints.clear();
      waypointInfo.clear();
      routePoints.clear();
      totalDistance = 0;
      totalDuration = '';
      segmentDistances.clear();
      segmentDurations.clear();
      routeName = 'Unnamed Route'; // Reset route name

      for (var c in _waypointControllers) c.dispose();
      for (var f in _waypointFocusNodes) f.dispose();
      _waypointControllers.clear();
      _waypointFocusNodes.clear();

      if (widget.isEditMode && widget.existingWaypoints != null) {
        _loadExistingWaypoints();
      } else {
        _addWaypointField();
        _addWaypointField();
      }

      _invalidateCalculation();
      _isPanelExpanded = true;
      _isGeofencingActive = false;
    });

    _geofencingService.stopMonitoring();
  }

  void _reorderWaypoint(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final w = waypoints.removeAt(oldIndex);
      final c = _waypointControllers.removeAt(oldIndex);
      final f = _waypointFocusNodes.removeAt(oldIndex);
      final info = waypointInfo.removeAt(oldIndex);

      waypoints.insert(newIndex, w);
      _waypointControllers.insert(newIndex, c);
      _waypointFocusNodes.insert(newIndex, f);
      waypointInfo.insert(newIndex, info);

      _invalidateCalculation();
    });

    _autoCalculateIfReady();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: const LatLng(32.5, 74.5),
              initialZoom: 7.5,
              onTap: (tapPosition, point) => onMapTap(tapPosition, point),
            ),
            children: [
              // TileLayer کو یوں update کریں:
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.map_routing',
                // subdomains کو remove کریں یا comment کریں
                // subdomains: ['a', 'b', 'c'], // یہ لائن remove کریں
              ),
              MarkerLayer(
                markers: List.generate(waypoints.length, (i) {
                  final point = waypoints[i];
                  if (point == LatLng(0, 0)) return const Marker(point: LatLng(0,0), width: 0, height: 0, child: SizedBox());

                  final color = waypointColors[i % waypointColors.length];

                  return Marker(
                    point: point,
                    width: 60,
                    height: 80,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            waypointIcons[i % waypointIcons.length],
                            color: color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                            ],
                          ),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: _buildSegmentPolylines(),
                ),
            ],
          ),

          // Top App Bar with Geofencing Button
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.isEditMode ? 'Edit Route' : 'Create Route',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Geofencing Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isGeofencingActive ? Icons.location_on : Icons.location_off,
                        color: _isGeofencingActive ? Colors.green : Colors.grey,
                      ),
                      onPressed: _toggleGeofencing,
                      tooltip: 'Toggle Geofencing',
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.add_location_alt,
                    label: 'Add',
                    onPressed: _addWaypointField,
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.delete_outline,
                    label: 'Clear',
                    onPressed: clearAll,
                    color: Colors.red.shade400,
                  ),
                ],
              ),
            ),
          ),

          // Geofencing Status Display
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: ValueListenableBuilder<String>(
              valueListenable: _geofencingService.geofenceStatus,
              builder: (context, status, child) {
                if (status == 'Idle') return SizedBox.shrink();

                return Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: status == 'On Route'
                          ? Colors.green.withOpacity(0.1)
                          : status == 'Off Route'
                          ? Colors.red.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: status == 'On Route'
                            ? Colors.green
                            : status == 'Off Route'
                            ? Colors.red
                            : Colors.blue,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: status == 'On Route'
                                ? Colors.green
                                : status == 'Off Route'
                                ? Colors.red
                                : Colors.blue,
                          ),
                          child: Center(
                            child: Icon(
                              status == 'On Route'
                                  ? Icons.check_circle
                                  : status == 'Off Route'
                                  ? Icons.warning
                                  : Icons.location_on,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                status,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: status == 'On Route'
                                      ? Colors.green.shade800
                                      : status == 'Off Route'
                                      ? Colors.red.shade800
                                      : Colors.blue.shade800,
                                ),
                              ),
                              ValueListenableBuilder<double>(
                                valueListenable: _geofencingService.distanceToRoute,
                                builder: (context, distance, child) {
                                  if (distance > 0) {
                                    return Text(
                                      'Distance to route: ${distance.toStringAsFixed(1)}m',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    );
                                  }
                                  return SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.settings),
                          onPressed: _showGeofenceSettings,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Waypoints Panel - Minimal when collapsed
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: _isPanelExpanded ? 320 : 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(_isPanelExpanded ? 24 : 16),
                  topRight: Radius.circular(_isPanelExpanded ? 24 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle & Minimal Info when collapsed
                  GestureDetector(
                    onTap: () => setState(() => _isPanelExpanded = !_isPanelExpanded),
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          // Drag Handle
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Waypoint counter when collapsed
                          if (!_isPanelExpanded)
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF6366F1).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.route,
                                        color: Color(0xFF6366F1),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${waypoints.where((p) => p != LatLng(0, 0)).length} waypoints',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      if (_showRouteInfo)
                                        Text(
                                          '${totalDistance.toStringAsFixed(1)} km • $totalDuration',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                          const Spacer(),

                          // Expand/Collapse Icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPanelExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                              color: Colors.grey.shade700,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Waypoints List (only when expanded)
                  if (_isPanelExpanded)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            // Waypoints title
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Text(
                                    'Waypoints',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF6366F1).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${waypoints.where((p) => p != LatLng(0, 0)).length} selected',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF6366F1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Waypoints list
                            Expanded(
                              child: ReorderableListView.builder(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                itemCount: _waypointControllers.length,
                                itemBuilder: (context, index) {
                                  final color = waypointColors[index % waypointColors.length];
                                  return Container(
                                    key: ValueKey(index),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.grey.shade200, width: 1),
                                    ),
                                    child: Row(
                                      children: [
                                        // Drag Handle
                                        Container(
                                          width: 44,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(16),
                                              bottomLeft: Radius.circular(16),
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.drag_handle,
                                              color: color,
                                              size: 20,
                                            ),
                                          ),
                                        ),

                                        // Waypoint Number
                                        Container(
                                          width: 44,
                                          height: 56,
                                          color: color.withOpacity(0.05),
                                          child: Center(
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: color,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${index + 1}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Search Field
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: TypeAheadField<Map<String, dynamic>>(
                                              controller: _waypointControllers[index],
                                              focusNode: _waypointFocusNodes[index],
                                              debounceDuration: const Duration(milliseconds: 350),
                                              suggestionsCallback: searchPlaces,
                                              itemBuilder: (context, suggestion) => ListTile(
                                                leading: Icon(Icons.location_on, color: color),
                                                title: Text(
                                                  suggestion['display_name'] ?? 'Unknown',
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                              ),
                                              onSelected: (suggestion) => setWaypoint(index, suggestion),
                                              builder: (context, controller, focusNode) => TextField(
                                                controller: controller,
                                                focusNode: focusNode,
                                                decoration: InputDecoration(
                                                  hintText: 'Search location or tap map...',
                                                  border: InputBorder.none,
                                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                                  suffixIcon: _waypointControllers.length > 2
                                                      ? IconButton(
                                                    icon: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                                                    onPressed: () => _removeWaypointField(index),
                                                  )
                                                      : null,
                                                ),
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                onReorder: _reorderWaypoint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Add Waypoint Button (only when expanded)
                  if (_isPanelExpanded)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        onPressed: _addWaypointField,
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Add Another Waypoint'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Floating Navigation and Save Buttons
          if (_showSaveButton)
            Positioned(
              bottom: _isPanelExpanded ? 340 : 80,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  // Save Button
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: (_isCalculated ? Color(0xFF10B981) : Colors.grey).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isCalculated ? openSaveScreen : null,
                      icon: Icon(
                        widget.isEditMode ? Icons.save_outlined : Icons.save_alt_outlined,
                        size: 22,
                      ),
                      label: Text(
                        widget.isEditMode ? 'Save Changes' : 'Save Route',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCalculated ? Color(0xFF10B981) : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Floating Route Info (when route is calculated)
          if (_showRouteInfo && routePoints.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 20,
              right: 20,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Route Icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.route,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Route Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Route Calculated',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${totalDistance.toStringAsFixed(1)} km • $totalDuration • ${segmentDistances.length} segments',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Close button
                    IconButton(
                      icon: Icon(Icons.close, size: 20, color: Colors.grey.shade500),
                      onPressed: () {
                        setState(() {
                          _showRouteInfo = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

          // Calculation Indicator
          if (_isCalculating)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Calculating route...',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: color ?? Color(0xFF6366F1), size: 20),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}