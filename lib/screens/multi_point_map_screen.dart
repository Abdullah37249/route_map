// //
// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_map/flutter_map.dart';
// // import 'package:latlong2/latlong.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:flutter_typeahead/flutter_typeahead.dart';
// // import 'save_multi_route_screen.dart';
// // import '../Database/db_service.dart';
// //
// // class MultiPointMapScreen extends StatefulWidget {
// //   final bool isEditMode;
// //   final List<Map<String, dynamic>>? existingWaypoints;
// //   final int? routeId;
// //   final int? segmentToEdit;
// //
// //   const MultiPointMapScreen({
// //     super.key,
// //     this.isEditMode = false,
// //     this.existingWaypoints,
// //     this.routeId,
// //     this.segmentToEdit,
// //   });
// //
// //   factory MultiPointMapScreen.editMode({
// //     required List<Map<String, dynamic>> existingWaypoints,
// //     required int routeId,
// //     int? segmentToEdit,
// //   }) {
// //     return MultiPointMapScreen(
// //       isEditMode: true,
// //       existingWaypoints: existingWaypoints,
// //       routeId: routeId,
// //       segmentToEdit: segmentToEdit,
// //     );
// //   }
// //
// //   @override
// //   State<MultiPointMapScreen> createState() => _MultiPointMapScreenState();
// // }
// //
// // class _MultiPointMapScreenState extends State<MultiPointMapScreen> {
// //   final mapController = MapController();
// //   List<LatLng> waypoints = [];
// //   List<Map<String, dynamic>> waypointInfo = [];
// //   List<LatLng> routePoints = [];
// //   double totalDistance = 0;
// //   String totalDuration = '';
// //   List<double> segmentDistances = [];
// //   List<String> segmentDurations = [];
// //
// //   final List<TextEditingController> _waypointControllers = [];
// //   final List<FocusNode> _waypointFocusNodes = [];
// //
// //   bool _isPanelExpanded = true;
// //
// //   // Colors for different waypoints & segments
// //   final List<Color> waypointColors = [
// //     Colors.green,
// //     Colors.blue,
// //     Colors.orange,
// //     Colors.purple,
// //     Colors.teal,
// //     Colors.pink,
// //     Colors.indigo,
// //     Colors.amber.shade700,
// //     Colors.cyan,
// //     Colors.deepOrange,
// //   ];
// //
// //   final List<IconData> waypointIcons = [
// //     Icons.location_on,
// //     Icons.flag,
// //     Icons.pin_drop,
// //     Icons.place,
// //     Icons.location_city,
// //     Icons.local_hotel,
// //     Icons.restaurant,
// //     Icons.shopping_cart,
// //     Icons.coffee,
// //     Icons.directions_car,
// //   ];
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //
// //     if (widget.isEditMode && widget.existingWaypoints != null) {
// //       _loadExistingWaypoints();
// //     } else {
// //       _addWaypointField();
// //       _addWaypointField();
// //     }
// //   }
// //
// //   void _loadExistingWaypoints() {
// //     if (widget.existingWaypoints == null) return;
// //
// //     setState(() {
// //       for (final waypoint in widget.existingWaypoints!) {
// //         final lat = waypoint['lat'] as double? ?? 0.0;
// //         final lng = waypoint['lng'] as double? ?? 0.0;
// //
// //         if (lat != 0.0 && lng != 0.0) {
// //           waypoints.add(LatLng(lat, lng));
// //           waypointInfo.add(waypoint);
// //
// //           _waypointControllers.add(
// //             TextEditingController(text: waypoint['name']?.toString() ?? ''),
// //           );
// //           _waypointFocusNodes.add(FocusNode());
// //         }
// //       }
// //     });
// //
// //     if (waypoints.length >= 2) {
// //       WidgetsBinding.instance.addPostFrameCallback((_) {
// //         calculateRoute();
// //       });
// //     }
// //   }
// //
// //   @override
// //   void dispose() {
// //     for (var controller in _waypointControllers) {
// //       controller.dispose();
// //     }
// //     for (var focusNode in _waypointFocusNodes) {
// //       focusNode.dispose();
// //     }
// //     super.dispose();
// //   }
// //
// //   void _addWaypointField() {
// //     setState(() {
// //       _waypointControllers.add(TextEditingController());
// //       _waypointFocusNodes.add(FocusNode());
// //       waypoints.add(LatLng(0, 0));
// //       waypointInfo.add({});
// //     });
// //   }
// //
// //   void _removeWaypointField(int index) {
// //     if (_waypointControllers.length > 2) {
// //       setState(() {
// //         _waypointControllers[index].dispose();
// //         _waypointFocusNodes[index].dispose();
// //         _waypointControllers.removeAt(index);
// //         _waypointFocusNodes.removeAt(index);
// //         waypoints.removeAt(index);
// //         waypointInfo.removeAt(index);
// //
// //         if (waypoints.length >= 2) {
// //           calculateRoute();
// //         }
// //       });
// //     }
// //   }
// //
// //   Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
// //     if (query.isEmpty || query.length < 3) return [];
// //
// //     try {
// //       final url = Uri.parse(
// //         'https://nominatim.openstreetmap.org/search?'
// //             'q=${Uri.encodeQueryComponent(query)}'
// //             '&format=json'
// //             '&addressdetails=1'
// //             '&limit=10',
// //       );
// //
// //       final res = await http
// //           .get(
// //         url,
// //         headers: {
// //           'User-Agent': 'FlutterMapRoutingApp/1.0',
// //           'Accept-Language': 'en',
// //         },
// //       )
// //           .timeout(const Duration(seconds: 5));
// //
// //       if (res.statusCode == 200) {
// //         final List<dynamic> data = jsonDecode(res.body);
// //         return data.map((item) {
// //           return {
// //             'lat': item['lat'],
// //             'lon': item['lon'],
// //             'display_name': item['display_name'],
// //             'type': item['type'] ?? 'unknown',
// //           };
// //         }).toList();
// //       }
// //     } catch (e) {
// //       debugPrint('Search error: $e');
// //     }
// //     return [];
// //   }
// //
// //   void setWaypoint(int index, Map<String, dynamic> place) {
// //     final lat = double.tryParse(place['lat'].toString()) ?? 0.0;
// //     final lon = double.tryParse(place['lon'].toString()) ?? 0.0;
// //
// //     if (lat == 0.0 || lon == 0.0) return;
// //
// //     setState(() {
// //       waypoints[index] = LatLng(lat, lon);
// //       waypointInfo[index] = {
// //         'lat': lat,
// //         'lng': lon,
// //         'name': place['display_name'] ?? 'Waypoint ${index + 1}',
// //         'address': place['display_name'] ?? '',
// //       };
// //       _waypointControllers[index].text = place['display_name'] ?? '';
// //     });
// //
// //     mapController.move(LatLng(lat, lon), 14);
// //   }
// //
// //   void onMapTap(TapPosition tapPosition, LatLng point) async {
// //     int emptyIndex = -1;
// //     for (int i = 0; i < waypoints.length; i++) {
// //       if (waypoints[i] == LatLng(0, 0)) {
// //         emptyIndex = i;
// //         break;
// //       }
// //     }
// //
// //     if (emptyIndex == -1) {
// //       _addWaypointField();
// //       emptyIndex = waypoints.length - 1;
// //     }
// //
// //     final index = emptyIndex;
// //     setState(() {
// //       waypoints[index] = point;
// //       _waypointControllers[index].text = 'Loading address...';
// //     });
// //
// //     try {
// //       final url = Uri.parse(
// //         'https://nominatim.openstreetmap.org/reverse?'
// //             'lat=${point.latitude}&lon=${point.longitude}'
// //             '&format=json&addressdetails=1',
// //       );
// //
// //       final res = await http
// //           .get(url, headers: {'User-Agent': 'FlutterMapRoutingApp/1.0'})
// //           .timeout(const Duration(seconds: 4));
// //
// //       if (res.statusCode == 200) {
// //         final data = jsonDecode(res.body);
// //         final address = data['display_name'] ??
// //             '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
// //
// //         setState(() {
// //           waypointInfo[index] = {
// //             'lat': point.latitude,
// //             'lng': point.longitude,
// //             'name': 'Waypoint ${index + 1}',
// //             'address': address,
// //           };
// //           _waypointControllers[index].text = address;
// //         });
// //       }
// //     } catch (e) {
// //       debugPrint('Reverse geocoding error: $e');
// //       setState(() {
// //         waypointInfo[index] = {
// //           'lat': point.latitude,
// //           'lng': point.longitude,
// //           'name': 'Waypoint ${index + 1}',
// //           'address':
// //           '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
// //         };
// //         _waypointControllers[index].text =
// //         '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
// //       });
// //     }
// //   }
// //
// //   Future<void> calculateRoute() async {
// //     final validWaypoints =
// //     waypoints.where((p) => p != LatLng(0, 0)).toList();
// //     if (validWaypoints.length < 2) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Please select at least 2 points')),
// //       );
// //       return;
// //     }
// //
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       const SnackBar(
// //         content: Row(
// //           children: [
// //             SizedBox(
// //               width: 20,
// //               height: 20,
// //               child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
// //             ),
// //             SizedBox(width: 16),
// //             Text('Calculating multi-point route...'),
// //           ],
// //         ),
// //         duration: Duration(seconds: 4),
// //       ),
// //     );
// //
// //     try {
// //       segmentDistances.clear();
// //       segmentDurations.clear();
// //       List<LatLng> allRoutePoints = [];
// //       double cumulativeDistance = 0;
// //
// //       for (int i = 0; i < validWaypoints.length - 1; i++) {
// //         final start = validWaypoints[i];
// //         final end = validWaypoints[i + 1];
// //
// //         final segment = await _calculateSegment(start, end);
// //         if (segment != null) {
// //           allRoutePoints.addAll(segment['points'] as List<LatLng>);
// //           cumulativeDistance += segment['distance'] as double;
// //           segmentDistances.add(segment['distance'] as double);
// //           segmentDurations.add(segment['duration'] as String);
// //         }
// //       }
// //
// //       int totalSeconds = 0;
// //       for (final dur in segmentDurations) {
// //         totalSeconds += _durationToSeconds(dur);
// //       }
// //
// //       setState(() {
// //         routePoints = allRoutePoints;
// //         totalDistance = cumulativeDistance;
// //         totalDuration = _formatDuration(totalSeconds.toDouble());
// //       });
// //
// //       _fitMapToRoute();
// //
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text('Route calculated: ${segmentDistances.length} segments'),
// //           backgroundColor: Colors.green,
// //           duration: const Duration(seconds: 2),
// //         ),
// //       );
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Failed to calculate route: $e'), backgroundColor: Colors.red),
// //       );
// //     }
// //   }
// //
// //   Future<Map<String, dynamic>?> _calculateSegment(LatLng start, LatLng end) async {
// //     try {
// //       final url = Uri.parse(
// //         "https://router.project-osrm.org/route/v1/driving/"
// //             "${start.longitude},${start.latitude};${end.longitude},${end.latitude}"
// //             "?overview=full&geometries=geojson&steps=true&annotations=true",
// //       );
// //
// //       final res = await http.get(url).timeout(const Duration(seconds: 10));
// //
// //       if (res.statusCode == 200) {
// //         final data = jsonDecode(res.body);
// //         if (data['routes'] != null && data['routes'].isNotEmpty) {
// //           final route = data['routes'][0];
// //           final coords = route['geometry']['coordinates'] as List;
// //           final dur = route['duration'] as num;
// //           final dist = route['distance'] as num;
// //
// //           final points = coords.map((c) => LatLng(c[1], c[0])).toList();
// //
// //           return {
// //             'points': points,
// //             'distance': dist / 1000,
// //             'duration': _formatDuration(dur.toDouble()),
// //           };
// //         }
// //       }
// //     } catch (e) {
// //       debugPrint('Segment error: $e');
// //     }
// //     return null;
// //   }
// //
// //   int _durationToSeconds(String duration) {
// //     try {
// //       if (duration.contains('h')) {
// //         final parts = duration.split('h');
// //         final h = int.tryParse(parts[0].trim()) ?? 0;
// //         final mStr = parts[1].replaceAll('min', '').trim();
// //         final m = int.tryParse(mStr) ?? 0;
// //         return (h * 3600) + (m * 60);
// //       } else {
// //         final m = int.tryParse(duration.replaceAll('min', '').trim()) ?? 0;
// //         return m * 60;
// //       }
// //     } catch (_) {
// //       return 0;
// //     }
// //   }
// //
// //   String _formatDuration(double seconds) {
// //     final h = (seconds / 3600).floor();
// //     final m = ((seconds % 3600) / 60).floor();
// //     if (h > 0) return '$h h $m min';
// //     return '$m min';
// //   }
// //
// //   void _fitMapToRoute() {
// //     if (routePoints.isEmpty) return;
// //
// //     double minLat = routePoints[0].latitude;
// //     double maxLat = routePoints[0].latitude;
// //     double minLng = routePoints[0].longitude;
// //     double maxLng = routePoints[0].longitude;
// //
// //     for (final p in routePoints) {
// //       if (p.latitude < minLat) minLat = p.latitude;
// //       if (p.latitude > maxLat) maxLat = p.latitude;
// //       if (p.longitude < minLng) minLng = p.longitude;
// //       if (p.longitude > maxLng) maxLng = p.longitude;
// //     }
// //
// //     final bounds = LatLngBounds(
// //       LatLng(minLat, minLng),
// //       LatLng(maxLat, maxLng),
// //     );
// //
// //     mapController.fitCamera(
// //       CameraFit.bounds(
// //         bounds: bounds,
// //         padding: const EdgeInsets.all(60),
// //       ),
// //     );
// //   }
// //
// //   List<Polyline> _buildSegmentPolylines() {
// //     if (routePoints.isEmpty || segmentDistances.isEmpty) return [];
// //
// //     final List<Polyline> polylines = [];
// //     final segmentColors = waypointColors; // reuse same color list
// //
// //     int startIndex = 0;
// //
// //     // Very approximate split — works reasonably well for most cases
// //     final pointsPerSegment = (routePoints.length / segmentDistances.length).ceil();
// //
// //     for (int i = 0; i < segmentDistances.length; i++) {
// //       int endIndex = (startIndex + pointsPerSegment).clamp(0, routePoints.length);
// //
// //       if (endIndex > startIndex) {
// //         final segmentPoints = routePoints.sublist(startIndex, endIndex);
// //
// //         polylines.add(
// //           Polyline(
// //             points: segmentPoints,
// //             color: segmentColors[i % segmentColors.length],
// //             strokeWidth: 5.5,
// //             borderColor: Colors.white.withOpacity(0.7),
// //             borderStrokeWidth: 2.2,
// //           ),
// //         );
// //       }
// //
// //       startIndex = endIndex;
// //     }
// //
// //     // Remaining points go to last segment
// //     if (startIndex < routePoints.length) {
// //       polylines.add(
// //         Polyline(
// //           points: routePoints.sublist(startIndex),
// //           color: segmentColors.last,
// //           strokeWidth: 5.5,
// //           borderColor: Colors.white.withOpacity(0.7),
// //           borderStrokeWidth: 2.2,
// //         ),
// //       );
// //     }
// //
// //     return polylines;
// //   }
// //
// //   Future<void> _saveEditedRoute() async {
// //     final validWaypoints = waypoints.where((p) => p != LatLng(0, 0)).toList();
// //     if (validWaypoints.length < 2 || routePoints.isEmpty || segmentDistances.isEmpty) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Please calculate a route first')),
// //       );
// //       return;
// //     }
// //
// //     if (!widget.isEditMode || widget.routeId == null) return;
// //
// //     // First, get the existing segments to preserve other data
// //     final existingSegments = await DBHelper.getSegmentsByRouteId(widget.routeId!);
// //     if (existingSegments.isEmpty) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Route not found locally')),
// //       );
// //       return;
// //     }
// //
// //     // Get the first segment to preserve route info
// //     final firstSegment = existingSegments.first;
// //
// //     // Prepare waypoint info with proper data
// //     final List<Map<String, dynamic>> waypointData = [];
// //     for (int i = 0; i < validWaypoints.length; i++) {
// //       final point = validWaypoints[i];
// //       final info = waypointInfo[i];
// //
// //       waypointData.add({
// //         'name': info['name'] ?? 'Waypoint ${i + 1}',
// //         'lat': point.latitude,
// //         'lng': point.longitude,
// //         'address': info['address'] ?? '',
// //       });
// //     }
// //
// //     // Delete old segments for this route
// //     await DBHelper.deleteLocalRoute(widget.routeId!);
// //
// //     // Create a new first segment with the SAME route_id
// //     final db = await DBHelper.getDatabase();
// //
// //     // Insert first segment with existing route_id
// //     final firstSegmentId = await db.insert('map_routes', {
// //       'route_id': widget.routeId, // Keep the same route ID
// //       'sr_no': 1,
// //       'start_name': waypointData[0]['name'] ?? 'Start Point',
// //       'start_lat': waypointData[0]['lat'] ?? 0.0,
// //       'start_lng': waypointData[0]['lng'] ?? 0.0,
// //       'end_name': waypointData[1]['name'] ?? 'Point 2',
// //       'end_lat': waypointData[1]['lat'] ?? 0.0,
// //       'end_lng': waypointData[1]['lng'] ?? 0.0,
// //       'segment_distance': segmentDistances[0],
// //       'segment_duration': segmentDurations[0],
// //       'total_distance': totalDistance,
// //       'total_duration': totalDuration,
// //       'waypoints': jsonEncode(waypointData),
// //       'province': firstSegment['province'] ?? 'Punjab', // Preserve existing
// //       'city': firstSegment['city'] ?? 'Sialkot', // Preserve existing
// //       'date': firstSegment['date'] ?? DateTime.now().toIso8601String().split('T')[0], // Preserve existing
// //       'created_at': DateTime.now().toIso8601String(),
// //     });
// //
// //     // Insert remaining segments with the SAME route_id
// //     for (int i = 1; i < waypointData.length - 1; i++) {
// //       await db.insert('map_routes', {
// //         'route_id': widget.routeId, // Keep the same route ID
// //         'sr_no': i + 1,
// //         'start_name': waypointData[i]['name'] ?? 'Point ${i + 1}',
// //         'start_lat': waypointData[i]['lat'] ?? 0.0,
// //         'start_lng': waypointData[i]['lng'] ?? 0.0,
// //         'end_name': waypointData[i + 1]['name'] ?? 'Point ${i + 2}',
// //         'end_lat': waypointData[i + 1]['lat'] ?? 0.0,
// //         'end_lng': waypointData[i + 1]['lng'] ?? 0.0,
// //         'segment_distance': segmentDistances[i],
// //         'segment_duration': segmentDurations[i],
// //         'total_distance': totalDistance,
// //         'total_duration': totalDuration,
// //         'waypoints': jsonEncode(waypointData),
// //         'province': firstSegment['province'] ?? 'Punjab', // Preserve existing
// //         'city': firstSegment['city'] ?? 'Sialkot', // Preserve existing
// //         'date': firstSegment['date'] ?? DateTime.now().toIso8601String().split('T')[0], // Preserve existing
// //         'created_at': DateTime.now().toIso8601String(),
// //       });
// //     }
// //
// //     if (mounted) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text('Route updated successfully (ID: ${widget.routeId})'),
// //           backgroundColor: Colors.green,
// //         ),
// //       );
// //       Navigator.pop(context, true);
// //     }
// //   }
// //
// //   void openSaveScreen() {
// //     if (widget.isEditMode) {
// //       _saveEditedRoute();
// //       return;
// //     }
// //
// //     final validWaypoints = waypoints.where((p) => p != LatLng(0, 0)).toList();
// //     if (validWaypoints.length < 2 || routePoints.isEmpty || segmentDistances.isEmpty) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Please calculate a route first')),
// //       );
// //       return;
// //     }
// //
// //     Navigator.push(
// //       context,
// //       MaterialPageRoute(
// //         builder: (_) => SaveMultiRouteScreen(
// //           waypoints: waypointInfo.where((info) => info.isNotEmpty).toList(),
// //           segmentDistances: segmentDistances,
// //           segmentDurations: segmentDurations,
// //           totalDistance: totalDistance,
// //           totalDuration: totalDuration,
// //         ),
// //       ),
// //     );
// //   }
// //
// //   void clearAll() {
// //     setState(() {
// //       waypoints.clear();
// //       waypointInfo.clear();
// //       routePoints.clear();
// //       totalDistance = 0;
// //       totalDuration = '';
// //       segmentDistances.clear();
// //       segmentDurations.clear();
// //
// //       for (var c in _waypointControllers) c.dispose();
// //       for (var f in _waypointFocusNodes) f.dispose();
// //       _waypointControllers.clear();
// //       _waypointFocusNodes.clear();
// //
// //       if (widget.isEditMode && widget.existingWaypoints != null) {
// //         _loadExistingWaypoints();
// //       } else {
// //         _addWaypointField();
// //         _addWaypointField();
// //       }
// //     });
// //   }
// //
// //   void _reorderWaypoint(int oldIndex, int newIndex) {
// //     if (newIndex > oldIndex) newIndex--;
// //     setState(() {
// //       final w = waypoints.removeAt(oldIndex);
// //       final c = _waypointControllers.removeAt(oldIndex);
// //       final f = _waypointFocusNodes.removeAt(oldIndex);
// //       final info = waypointInfo.removeAt(oldIndex);
// //
// //       waypoints.insert(newIndex, w);
// //       _waypointControllers.insert(newIndex, c);
// //       _waypointFocusNodes.insert(newIndex, f);
// //       waypointInfo.insert(newIndex, info);
// //     });
// //
// //     if (waypoints.where((p) => p != LatLng(0, 0)).length >= 2) {
// //       calculateRoute();
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text(widget.isEditMode ? 'Edit Route' : 'Multi-Point Route'),
// //         actions: [
// //           IconButton(
// //             icon: const Icon(Icons.add_location_alt),
// //             tooltip: 'Add waypoint',
// //             onPressed: _addWaypointField,
// //           ),
// //           IconButton(
// //             icon: const Icon(Icons.clear_all),
// //             tooltip: 'Clear all',
// //             onPressed: clearAll,
// //           ),
// //         ],
// //       ),
// //       body: Stack(
// //         children: [
// //           FlutterMap(
// //             mapController: mapController,
// //             options: MapOptions(
// //               initialCenter: const LatLng(32.5, 74.5),
// //               initialZoom: 7.5,
// //               onTap: (tapPosition, point) => onMapTap(tapPosition, point),
// //               // or shorter (using _ for unused parameter):
// //               // onTap: (_, point) => onMapTap(_, point),
// //             ),
// //             children: [
// //               TileLayer(
// //                 urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
// //                 userAgentPackageName: 'com.example.map_routing',
// //               ),
// //               MarkerLayer(
// //                 markers: List.generate(waypoints.length, (i) {
// //                   final point = waypoints[i];
// //                   if (point == LatLng(0, 0)) return const Marker(point: LatLng(0,0), width: 0, height: 0, child: SizedBox());
// //
// //                   final color = waypointColors[i % waypointColors.length];
// //
// //                   return Marker(
// //                     point: point,
// //                     width: 52,
// //                     height: 70,
// //                     child: Column(
// //                       mainAxisSize: MainAxisSize.min,
// //                       children: [
// //                         Container(
// //                           padding: const EdgeInsets.all(8),
// //                           decoration: BoxDecoration(
// //                             color: color,
// //                             shape: BoxShape.circle,
// //                             boxShadow: [
// //                               BoxShadow(
// //                                 color: Colors.black.withOpacity(0.35),
// //                                 blurRadius: 6,
// //                                 offset: const Offset(0, 3),
// //                               ),
// //                             ],
// //                           ),
// //                           child: Icon(
// //                             waypointIcons[i % waypointIcons.length],
// //                             color: Colors.white,
// //                             size: 28,
// //                           ),
// //                         ),
// //                         const SizedBox(height: 6),
// //                         Container(
// //                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
// //                           decoration: BoxDecoration(
// //                             color: Colors.white,
// //                             borderRadius: BorderRadius.circular(16),
// //                             boxShadow: [
// //                               BoxShadow(color: Colors.black12, blurRadius: 4),
// //                             ],
// //                           ),
// //                           child: Text(
// //                             '${i + 1}',
// //                             style: TextStyle(
// //                               fontSize: 15,
// //                               fontWeight: FontWeight.bold,
// //                               color: color,
// //                             ),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   );
// //                 }),
// //               ),
// //               if (routePoints.isNotEmpty)
// //                 PolylineLayer(
// //                   polylines: _buildSegmentPolylines(),
// //                 ),
// //             ],
// //           ),
// //
// //           // Collapsible Waypoints Panel
// //           Positioned(
// //             top: 10,
// //             left: 10,
// //             right: 10,
// //             child: Card(
// //               elevation: 6,
// //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
// //               child: Column(
// //                 mainAxisSize: MainAxisSize.min,
// //                 children: [
// //                   // Header
// //                   InkWell(
// //                     onTap: () => setState(() => _isPanelExpanded = !_isPanelExpanded),
// //                     borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
// //                     child: Container(
// //                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// //                       decoration: BoxDecoration(
// //                         color: Colors.blue.shade50,
// //                         borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
// //                       ),
// //                       child: Row(
// //                         children: [
// //                           const Icon(Icons.route, color: Colors.blue),
// //                           const SizedBox(width: 12),
// //                           const Expanded(
// //                             child: Text(
// //                               'Waypoints',
// //                               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
// //                             ),
// //                           ),
// //                           Icon(
// //                             _isPanelExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
// //                             color: Colors.blue.shade800,
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                   ),
// //
// //                   // Content
// //                   AnimatedContainer(
// //                     duration: const Duration(milliseconds: 280),
// //                     curve: Curves.easeInOut,
// //                     height: _isPanelExpanded
// //                         ? null
// //                         : 0,
// //                     child: ConstrainedBox(
// //                       constraints: const BoxConstraints(maxHeight: 340),
// //                       child: SingleChildScrollView(
// //                         child: Padding(
// //                           padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
// //                           child: Column(
// //                             children: [
// //                               ReorderableListView.builder(
// //                                 shrinkWrap: true,
// //                                 physics: const NeverScrollableScrollPhysics(),
// //                                 itemCount: _waypointControllers.length,
// //                                 itemBuilder: (context, index) {
// //                                   final color = waypointColors[index % waypointColors.length];
// //                                   return Container(
// //                                     key: ValueKey(index),
// //                                     margin: const EdgeInsets.only(bottom: 10),
// //                                     child: Row(
// //                                       crossAxisAlignment: CrossAxisAlignment.start,
// //                                       children: [
// //                                         Container(
// //                                           width: 38,
// //                                           height: 38,
// //                                           decoration: BoxDecoration(
// //                                             color: color,
// //                                             shape: BoxShape.circle,
// //                                           ),
// //                                           child: const Center(
// //                                             child: Icon(Icons.drag_handle, color: Colors.white, size: 20),
// //                                           ),
// //                                         ),
// //                                         const SizedBox(width: 10),
// //                                         Expanded(
// //                                           child: TypeAheadField<Map<String, dynamic>>(
// //                                             controller: _waypointControllers[index],
// //                                             focusNode: _waypointFocusNodes[index],
// //                                             debounceDuration: const Duration(milliseconds: 350),
// //                                             suggestionsCallback: searchPlaces,
// //                                             itemBuilder: (context, suggestion) => ListTile(
// //                                               leading: const Icon(Icons.location_on),
// //                                               title: Text(
// //                                                 suggestion['display_name'] ?? 'Unknown',
// //                                                 maxLines: 2,
// //                                                 overflow: TextOverflow.ellipsis,
// //                                               ),
// //                                             ),
// //                                             onSelected: (suggestion) => setWaypoint(index, suggestion),
// //                                             builder: (context, controller, focusNode) => TextField(
// //                                               controller: controller,
// //                                               focusNode: focusNode,
// //                                               decoration: InputDecoration(
// //                                                 filled: true,
// //                                                 fillColor: Colors.white,
// //                                                 labelText: 'Waypoint ${index + 1}',
// //                                                 hintText: 'Search or tap map...',
// //                                                 prefixIcon: Icon(Icons.location_on, color: color),
// //                                                 suffixIcon: _waypointControllers.length > 2
// //                                                     ? IconButton(
// //                                                   icon: const Icon(Icons.close, size: 20),
// //                                                   onPressed: () => _removeWaypointField(index),
// //                                                 )
// //                                                     : null,
// //                                                 border: OutlineInputBorder(
// //                                                   borderRadius: BorderRadius.circular(12),
// //                                                 ),
// //                                                 contentPadding: const EdgeInsets.symmetric(vertical: 14),
// //                                               ),
// //                                             ),
// //                                           ),
// //                                         ),
// //                                       ],
// //                                     ),
// //                                   );
// //                                 },
// //                                 onReorder: _reorderWaypoint,
// //                               ),
// //                               const SizedBox(height: 12),
// //                               TextButton.icon(
// //                                 onPressed: _addWaypointField,
// //                                 icon: const Icon(Icons.add_location_alt),
// //                                 label: const Text('Add Another Waypoint'),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //
// //           // Bottom action buttons
// //           Positioned(
// //             bottom: 20,
// //             left: 20,
// //             right: 20,
// //             child: Row(
// //               children: [
// //                 Expanded(
// //                   child: ElevatedButton.icon(
// //                     onPressed: calculateRoute,
// //                     icon: const Icon(Icons.route),
// //                     label: const Text('Calculate Route'),
// //                     style: ElevatedButton.styleFrom(
// //                       padding: const EdgeInsets.symmetric(vertical: 14),
// //                       backgroundColor: Colors.blue,
// //                       foregroundColor: Colors.white,
// //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //                     ),
// //                   ),
// //                 ),
// //                 const SizedBox(width: 12),
// //                 Expanded(
// //                   child: ElevatedButton.icon(
// //                     onPressed: openSaveScreen,
// //                     icon: Icon(widget.isEditMode ? Icons.save : Icons.save),
// //                     label: Text(widget.isEditMode ? 'Save Changes' : 'Save Route'),
// //                     style: ElevatedButton.styleFrom(
// //                       padding: const EdgeInsets.symmetric(vertical: 14),
// //                       backgroundColor: Colors.green,
// //                       foregroundColor: Colors.white,
// //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //
// //           // Summary card
// //           if (routePoints.isNotEmpty)
// //             Positioned(
// //               bottom: 90,
// //               left: 20,
// //               right: 20,
// //               child: Card(
// //                 elevation: 6,
// //                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
// //                 child: Padding(
// //                   padding: const EdgeInsets.all(16),
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     mainAxisSize: MainAxisSize.min,
// //                     children: [
// //                       Row(
// //                         children: [
// //                           const Icon(Icons.route, color: Colors.blue),
// //                           const SizedBox(width: 8),
// //                           Text(
// //                             widget.isEditMode ? "Editing Route" : "Route Preview",
// //                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
// //                           ),
// //                           const Spacer(),
// //                           Chip(
// //                             label: Text('${waypoints.where((p) => p != LatLng(0, 0)).length} points'),
// //                             backgroundColor: Colors.blue.shade100,
// //                           ),
// //                         ],
// //                       ),
// //                       const Divider(height: 24),
// //                       Row(
// //                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //                         children: [
// //                           _buildStatColumn(
// //                             icon: Icons.straighten,
// //                             color: Colors.blue,
// //                             value: "${totalDistance.toStringAsFixed(1)} km",
// //                             label: "Distance",
// //                           ),
// //                           _buildStatColumn(
// //                             icon: Icons.access_time,
// //                             color: Colors.orange,
// //                             value: totalDuration.isEmpty ? '-' : totalDuration,
// //                             label: "Duration",
// //                           ),
// //                         ],
// //                       ),
// //                       if (segmentDistances.isNotEmpty)
// //                         Padding(
// //                           padding: const EdgeInsets.only(top: 12),
// //                           child: Text(
// //                             'Segments: ${segmentDistances.length}',
// //                             style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
// //                           ),
// //                         ),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //             ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _buildStatColumn({
// //     required IconData icon,
// //     required Color color,
// //     required String value,
// //     required String label,
// //   }) {
// //     return Column(
// //       children: [
// //         Icon(icon, color: color, size: 28),
// //         const SizedBox(height: 6),
// //         Text(
// //           value,
// //           style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
// //         ),
// //         Text(
// //           label,
// //           style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
// //         ),
// //       ],
// //     );
// //   }
// // }
//
// // Updated MultiPointMapScreen with improved _saveEditedRoute:
// // - Uses DBHelper.editMultiPointRoute to write local rows (preserving route_id).
// // - Deletes previous route on server (DBHelper.deleteRouteFromServer).
// // - Reposts updated segments to server (DBHelper.saveRouteSegmentsToServer).
// //
// // Note: this file is the full screen file with only the _saveEditedRoute flow adjusted
// // to implement the requested "edit on server" behavior.
//
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter_typeahead/flutter_typeahead.dart';
// import 'save_multi_route_screen.dart';
// import '../Database/db_service.dart';
//
// class MultiPointMapScreen extends StatefulWidget {
//   final bool isEditMode;
//   final List<Map<String, dynamic>>? existingWaypoints;
//   final int? routeId;
//   final int? segmentToEdit;
//
//   const MultiPointMapScreen({
//     super.key,
//     this.isEditMode = false,
//     this.existingWaypoints,
//     this.routeId,
//     this.segmentToEdit,
//   });
//
//   factory MultiPointMapScreen.editMode({
//     required List<Map<String, dynamic>> existingWaypoints,
//     required int routeId,
//     int? segmentToEdit,
//   }) {
//     return MultiPointMapScreen(
//       isEditMode: true,
//       existingWaypoints: existingWaypoints,
//       routeId: routeId,
//       segmentToEdit: segmentToEdit,
//     );
//   }
//
//   @override
//   State<MultiPointMapScreen> createState() => _MultiPointMapScreenState();
// }
//
// class _MultiPointMapScreenState extends State<MultiPointMapScreen> {
//   final mapController = MapController();
//   List<LatLng> waypoints = [];
//   List<Map<String, dynamic>> waypointInfo = [];
//   List<LatLng> routePoints = [];
//   double totalDistance = 0;
//   String totalDuration = '';
//   List<double> segmentDistances = [];
//   List<String> segmentDurations = [];
//
//   final List<TextEditingController> _waypointControllers = [];
//   final List<FocusNode> _waypointFocusNodes = [];
//
//   bool _isPanelExpanded = true;
//
//   // Colors for different waypoints & segments
//   final List<Color> waypointColors = [
//     Colors.green,
//     Colors.blue,
//     Colors.orange,
//     Colors.purple,
//     Colors.teal,
//     Colors.pink,
//     Colors.indigo,
//     Colors.amber.shade700,
//     Colors.cyan,
//     Colors.deepOrange,
//   ];
//
//   final List<IconData> waypointIcons = [
//     Icons.location_on,
//     Icons.flag,
//     Icons.pin_drop,
//     Icons.place,
//     Icons.location_city,
//     Icons.local_hotel,
//     Icons.restaurant,
//     Icons.shopping_cart,
//     Icons.coffee,
//     Icons.directions_car,
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//
//     if (widget.isEditMode && widget.existingWaypoints != null) {
//       _loadExistingWaypoints();
//     } else {
//       _addWaypointField();
//       _addWaypointField();
//     }
//   }
//
//   void _loadExistingWaypoints() {
//     if (widget.existingWaypoints == null) return;
//
//     setState(() {
//       for (final waypoint in widget.existingWaypoints!) {
//         final lat = waypoint['lat'] as double? ?? 0.0;
//         final lng = waypoint['lng'] as double? ?? 0.0;
//
//         if (lat != 0.0 && lng != 0.0) {
//           waypoints.add(LatLng(lat, lng));
//           waypointInfo.add(waypoint);
//
//           _waypointControllers.add(
//             TextEditingController(text: waypoint['name']?.toString() ?? ''),
//           );
//           _waypointFocusNodes.add(FocusNode());
//         }
//       }
//     });
//
//     if (waypoints.length >= 2) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         calculateRoute();
//       });
//     }
//   }
//
//   @override
//   void dispose() {
//     for (var controller in _waypointControllers) {
//       controller.dispose();
//     }
//     for (var focusNode in _waypointFocusNodes) {
//       focusNode.dispose();
//     }
//     super.dispose();
//   }
//
//   void _addWaypointField() {
//     setState(() {
//       _waypointControllers.add(TextEditingController());
//       _waypointFocusNodes.add(FocusNode());
//       waypoints.add(LatLng(0, 0));
//       waypointInfo.add({});
//     });
//   }
//
//   void _removeWaypointField(int index) {
//     if (_waypointControllers.length > 2) {
//       setState(() {
//         _waypointControllers[index].dispose();
//         _waypointFocusNodes[index].dispose();
//         _waypointControllers.removeAt(index);
//         _waypointFocusNodes.removeAt(index);
//         waypoints.removeAt(index);
//         waypointInfo.removeAt(index);
//
//         if (waypoints.length >= 2) {
//           calculateRoute();
//         }
//       });
//     }
//   }
//
//   Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
//     if (query.isEmpty || query.length < 3) return [];
//
//     try {
//       final url = Uri.parse(
//         'https://nominatim.openstreetmap.org/search?'
//             'q=${Uri.encodeQueryComponent(query)}'
//             '&format=json'
//             '&addressdetails=1'
//             '&limit=10',
//       );
//
//       final res = await http
//           .get(
//         url,
//         headers: {
//           'User-Agent': 'FlutterMapRoutingApp/1.0',
//           'Accept-Language': 'en',
//         },
//       )
//           .timeout(const Duration(seconds: 5));
//
//       if (res.statusCode == 200) {
//         final List<dynamic> data = jsonDecode(res.body);
//         return data.map((item) {
//           return {
//             'lat': item['lat'],
//             'lon': item['lon'],
//             'display_name': item['display_name'],
//             'type': item['type'] ?? 'unknown',
//           };
//         }).toList();
//       }
//     } catch (e) {
//       debugPrint('Search error: $e');
//     }
//     return [];
//   }
//
//   void setWaypoint(int index, Map<String, dynamic> place) {
//     final lat = double.tryParse(place['lat'].toString()) ?? 0.0;
//     final lon = double.tryParse(place['lon'].toString()) ?? 0.0;
//
//     if (lat == 0.0 || lon == 0.0) return;
//
//     setState(() {
//       waypoints[index] = LatLng(lat, lon);
//       waypointInfo[index] = {
//         'lat': lat,
//         'lng': lon,
//         'name': place['display_name'] ?? 'Waypoint ${index + 1}',
//         'address': place['display_name'] ?? '',
//       };
//       _waypointControllers[index].text = place['display_name'] ?? '';
//     });
//
//     mapController.move(LatLng(lat, lon), 14);
//   }
//
//   void onMapTap(TapPosition tapPosition, LatLng point) async {
//     int emptyIndex = -1;
//     for (int i = 0; i < waypoints.length; i++) {
//       if (waypoints[i] == LatLng(0, 0)) {
//         emptyIndex = i;
//         break;
//       }
//     }
//
//     if (emptyIndex == -1) {
//       _addWaypointField();
//       emptyIndex = waypoints.length - 1;
//     }
//
//     final index = emptyIndex;
//     setState(() {
//       waypoints[index] = point;
//       _waypointControllers[index].text = 'Loading address...';
//     });
//
//     try {
//       final url = Uri.parse(
//         'https://nominatim.openstreetmap.org/reverse?'
//             'lat=${point.latitude}&lon=${point.longitude}'
//             '&format=json&addressdetails=1',
//       );
//
//       final res = await http
//           .get(url, headers: {'User-Agent': 'FlutterMapRoutingApp/1.0'})
//           .timeout(const Duration(seconds: 4));
//
//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         final address = data['display_name'] ??
//             '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
//
//         setState(() {
//           waypointInfo[index] = {
//             'lat': point.latitude,
//             'lng': point.longitude,
//             'name': 'Waypoint ${index + 1}',
//             'address': address,
//           };
//           _waypointControllers[index].text = address;
//         });
//       }
//     } catch (e) {
//       debugPrint('Reverse geocoding error: $e');
//       setState(() {
//         waypointInfo[index] = {
//           'lat': point.latitude,
//           'lng': point.longitude,
//           'name': 'Waypoint ${index + 1}',
//           'address':
//           '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
//         };
//         _waypointControllers[index].text =
//         '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
//       });
//     }
//   }
//
//   Future<void> calculateRoute() async {
//     final validWaypoints =
//     waypoints.where((p) => p != LatLng(0, 0)).toList();
//     if (validWaypoints.length < 2) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select at least 2 points')),
//       );
//       return;
//     }
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Row(
//           children: [
//             SizedBox(
//               width: 20,
//               height: 20,
//               child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
//             ),
//             SizedBox(width: 16),
//             Text('Calculating multi-point route...'),
//           ],
//         ),
//         duration: Duration(seconds: 4),
//       ),
//     );
//
//     try {
//       segmentDistances.clear();
//       segmentDurations.clear();
//       List<LatLng> allRoutePoints = [];
//       double cumulativeDistance = 0;
//
//       for (int i = 0; i < validWaypoints.length - 1; i++) {
//         final start = validWaypoints[i];
//         final end = validWaypoints[i + 1];
//
//         final segment = await _calculateSegment(start, end);
//         if (segment != null) {
//           allRoutePoints.addAll(segment['points'] as List<LatLng>);
//           cumulativeDistance += segment['distance'] as double;
//           segmentDistances.add(segment['distance'] as double);
//           segmentDurations.add(segment['duration'] as String);
//         }
//       }
//
//       int totalSeconds = 0;
//       for (final dur in segmentDurations) {
//         totalSeconds += _durationToSeconds(dur);
//       }
//
//       setState(() {
//         routePoints = allRoutePoints;
//         totalDistance = cumulativeDistance;
//         totalDuration = _formatDuration(totalSeconds.toDouble());
//       });
//
//       _fitMapToRoute();
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Route calculated: ${segmentDistances.length} segments'),
//           backgroundColor: Colors.green,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to calculate route: $e'), backgroundColor: Colors.red),
//       );
//     }
//   }
//
//   Future<Map<String, dynamic>?> _calculateSegment(LatLng start, LatLng end) async {
//     try {
//       final url = Uri.parse(
//         "https://router.project-osrm.org/route/v1/driving/"
//             "${start.longitude},${start.latitude};${end.longitude},${end.latitude}"
//             "?overview=full&geometries=geojson&steps=true&annotations=true",
//       );
//
//       final res = await http.get(url).timeout(const Duration(seconds: 10));
//
//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         if (data['routes'] != null && data['routes'].isNotEmpty) {
//           final route = data['routes'][0];
//           final coords = route['geometry']['coordinates'] as List;
//           final dur = route['duration'] as num;
//           final dist = route['distance'] as num;
//
//           final points = coords.map((c) => LatLng(c[1], c[0])).toList();
//
//           return {
//             'points': points,
//             'distance': dist / 1000,
//             'duration': _formatDuration(dur.toDouble()),
//           };
//         }
//       }
//     } catch (e) {
//       debugPrint('Segment error: $e');
//     }
//     return null;
//   }
//
//   int _durationToSeconds(String duration) {
//     try {
//       if (duration.contains('h')) {
//         final parts = duration.split('h');
//         final h = int.tryParse(parts[0].trim()) ?? 0;
//         final mStr = parts[1].replaceAll('min', '').trim();
//         final m = int.tryParse(mStr) ?? 0;
//         return (h * 3600) + (m * 60);
//       } else {
//         final m = int.tryParse(duration.replaceAll('min', '').trim()) ?? 0;
//         return m * 60;
//       }
//     } catch (_) {
//       return 0;
//     }
//   }
//
//   String _formatDuration(double seconds) {
//     final h = (seconds / 3600).floor();
//     final m = ((seconds % 3600) / 60).floor();
//     if (h > 0) return '$h h $m min';
//     return '$m min';
//   }
//
//   void _fitMapToRoute() {
//     if (routePoints.isEmpty) return;
//
//     double minLat = routePoints[0].latitude;
//     double maxLat = routePoints[0].latitude;
//     double minLng = routePoints[0].longitude;
//     double maxLng = routePoints[0].longitude;
//
//     for (final p in routePoints) {
//       if (p.latitude < minLat) minLat = p.latitude;
//       if (p.latitude > maxLat) maxLat = p.latitude;
//       if (p.longitude < minLng) minLng = p.longitude;
//       if (p.longitude > maxLng) maxLng = p.longitude;
//     }
//
//     final bounds = LatLngBounds(
//       LatLng(minLat, minLng),
//       LatLng(maxLat, maxLng),
//     );
//
//     mapController.fitCamera(
//       CameraFit.bounds(
//         bounds: bounds,
//         padding: const EdgeInsets.all(60),
//       ),
//     );
//   }
//
//   List<Polyline> _buildSegmentPolylines() {
//     if (routePoints.isEmpty || segmentDistances.isEmpty) return [];
//
//     final List<Polyline> polylines = [];
//     final segmentColors = waypointColors; // reuse same color list
//
//     int startIndex = 0;
//
//     // Very approximate split — works reasonably well for most cases
//     final pointsPerSegment = (routePoints.length / segmentDistances.length).ceil();
//
//     for (int i = 0; i < segmentDistances.length; i++) {
//       int endIndex = (startIndex + pointsPerSegment).clamp(0, routePoints.length);
//
//       if (endIndex > startIndex) {
//         final segmentPoints = routePoints.sublist(startIndex, endIndex);
//
//         polylines.add(
//           Polyline(
//             points: segmentPoints,
//             color: segmentColors[i % segmentColors.length],
//             strokeWidth: 5.5,
//             borderColor: Colors.white.withOpacity(0.7),
//             borderStrokeWidth: 2.2,
//           ),
//         );
//       }
//
//       startIndex = endIndex;
//     }
//
//     // Remaining points go to last segment
//     if (startIndex < routePoints.length) {
//       polylines.add(
//         Polyline(
//           points: routePoints.sublist(startIndex),
//           color: segmentColors.last,
//           strokeWidth: 5.5,
//           borderColor: Colors.white.withOpacity(0.7),
//           borderStrokeWidth: 2.2,
//         ),
//       );
//     }
//
//     return polylines;
//   }
//
//   // Updated save flow for edit mode:
//   // - uses DBHelper.editMultiPointRoute to write the updated segments locally (keeps same route_id)
//   // - tries to delete previous route from server (DBHelper.deleteRouteFromServer)
//   // - uploads local segments to server (DBHelper.saveRouteSegmentsToServer)
//   Future<void> _saveEditedRoute() async {
//     final validWaypoints = waypoints.where((p) => p != LatLng(0, 0)).toList();
//     if (validWaypoints.length < 2 || routePoints.isEmpty || segmentDistances.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please calculate a route first')),
//       );
//       return;
//     }
//
//     if (!widget.isEditMode || widget.routeId == null) return;
//
//     final routeId = widget.routeId!;
//
//     // Build waypointData for storing
//     final List<Map<String, dynamic>> waypointData = [];
//     for (int i = 0; i < validWaypoints.length; i++) {
//       final point = validWaypoints[i];
//       final info = (i < waypointInfo.length) ? waypointInfo[i] : {};
//       waypointData.add({
//         'name': info['name'] ?? 'Waypoint ${i + 1}',
//         'lat': point.latitude,
//         'lng': point.longitude,
//         'address': info['address'] ?? '',
//       });
//     }
//
//     // Try to preserve province/city/date if available locally (from existing DB)
//     String province = 'Punjab';
//     String city = 'Sialkot';
//     String date = DateTime.now().toIso8601String().split('T')[0];
//
//     try {
//       final existingSegments = await DBHelper.getSegmentsByRouteId(routeId);
//       if (existingSegments.isNotEmpty) {
//         province = existingSegments.first['province']?.toString() ?? province;
//         city = existingSegments.first['city']?.toString() ?? city;
//         date = existingSegments.first['date']?.toString() ?? date;
//       }
//
//       // Write updated route locally using DBHelper.editMultiPointRoute (keeps same route_id)
//       final success = await DBHelper.editMultiPointRoute(
//         routeId: routeId,
//         waypoints: waypointData,
//         segmentDistances: List<double>.from(segmentDistances),
//         segmentDurations: List<String>.from(segmentDurations),
//         totalDistance: totalDistance,
//         totalDuration: totalDuration,
//         province: province,
//         city: city,
//         date: date,
//       );
//
//       if (!success) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to save updated route locally'), backgroundColor: Colors.red),
//         );
//         return;
//       }
//
//       // Delete previous route from server first
//       bool deleted = await DBHelper.deleteRouteFromServer(routeId);
//       if (!deleted) {
//         // Show a warning but continue to attempt upload (server might accept overwrites)
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Warning: failed to delete previous route on server. Will still attempt to upload.'),
//             backgroundColor: Colors.orange,
//           ),
//         );
//       }
//
//       // Upload segments from local DB to server
//       final uploadResult = await DBHelper.saveRouteSegmentsToServer(routeId);
//
//       if (uploadResult['success'] == true && (uploadResult['failed_segments'] ?? 0) == 0) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Route updated and reposted on server (ID: $routeId)'), backgroundColor: Colors.green),
//           );
//           Navigator.pop(context, true);
//         }
//       } else {
//         final failed = uploadResult['failed_segments'] ?? 0;
//         final sent = uploadResult['sent_segments'] ?? 0;
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Upload result: sent $sent, failed $failed'),
//             backgroundColor: failed == 0 ? Colors.green : Colors.orange,
//           ),
//         );
//         if (mounted) Navigator.pop(context, true);
//       }
//     } catch (e) {
//       debugPrint('Error saving edited route: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error saving edited route: $e'), backgroundColor: Colors.red),
//       );
//     }
//   }
//
//   Future<void> _saveEditedRoute_Old() async {
//     // kept for historical reference (not used). The new implementation above is used.
//   }
//
//   void openSaveScreen() {
//     if (widget.isEditMode) {
//       _saveEditedRoute();
//       return;
//     }
//
//     final validWaypoints = waypoints.where((p) => p != LatLng(0, 0)).toList();
//     if (validWaypoints.length < 2 || routePoints.isEmpty || segmentDistances.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please calculate a route first')),
//       );
//       return;
//     }
//
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => SaveMultiRouteScreen(
//           waypoints: waypointInfo.where((info) => info.isNotEmpty).toList(),
//           segmentDistances: segmentDistances,
//           segmentDurations: segmentDurations,
//           totalDistance: totalDistance,
//           totalDuration: totalDuration,
//         ),
//       ),
//     );
//   }
//
//   void clearAll() {
//     setState(() {
//       waypoints.clear();
//       waypointInfo.clear();
//       routePoints.clear();
//       totalDistance = 0;
//       totalDuration = '';
//       segmentDistances.clear();
//       segmentDurations.clear();
//
//       for (var c in _waypointControllers) c.dispose();
//       for (var f in _waypointFocusNodes) f.dispose();
//       _waypointControllers.clear();
//       _waypointFocusNodes.clear();
//
//       if (widget.isEditMode && widget.existingWaypoints != null) {
//         _loadExistingWaypoints();
//       } else {
//         _addWaypointField();
//         _addWaypointField();
//       }
//     });
//   }
//
//   void _reorderWaypoint(int oldIndex, int newIndex) {
//     if (newIndex > oldIndex) newIndex--;
//     setState(() {
//       final w = waypoints.removeAt(oldIndex);
//       final c = _waypointControllers.removeAt(oldIndex);
//       final f = _waypointFocusNodes.removeAt(oldIndex);
//       final info = waypointInfo.removeAt(oldIndex);
//
//       waypoints.insert(newIndex, w);
//       _waypointControllers.insert(newIndex, c);
//       _waypointFocusNodes.insert(newIndex, f);
//       waypointInfo.insert(newIndex, info);
//     });
//
//     if (waypoints.where((p) => p != LatLng(0, 0)).length >= 2) {
//       calculateRoute();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.isEditMode ? 'Edit Route' : 'Multi-Point Route'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add_location_alt),
//             tooltip: 'Add waypoint',
//             onPressed: _addWaypointField,
//           ),
//           IconButton(
//             icon: const Icon(Icons.clear_all),
//             tooltip: 'Clear all',
//             onPressed: clearAll,
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           FlutterMap(
//             mapController: mapController,
//             options: MapOptions(
//               initialCenter: const LatLng(32.5, 74.5),
//               initialZoom: 7.5,
//               onTap: (tapPosition, point) => onMapTap(tapPosition, point),
//             ),
//             children: [
//               TileLayer(
//                 urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//                 userAgentPackageName: 'com.example.map_routing',
//               ),
//               MarkerLayer(
//                 markers: List.generate(waypoints.length, (i) {
//                   final point = waypoints[i];
//                   if (point == LatLng(0, 0)) return const Marker(point: LatLng(0,0), width: 0, height: 0, child: SizedBox());
//
//                   final color = waypointColors[i % waypointColors.length];
//
//                   return Marker(
//                     point: point,
//                     width: 52,
//                     height: 70,
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                             color: color,
//                             shape: BoxShape.circle,
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.35),
//                                 blurRadius: 6,
//                                 offset: const Offset(0, 3),
//                               ),
//                             ],
//                           ),
//                           child: Icon(
//                             waypointIcons[i % waypointIcons.length],
//                             color: Colors.white,
//                             size: 28,
//                           ),
//                         ),
//                         const SizedBox(height: 6),
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(16),
//                             boxShadow: [
//                               BoxShadow(color: Colors.black12, blurRadius: 4),
//                             ],
//                           ),
//                           child: Text(
//                             '${i + 1}',
//                             style: TextStyle(
//                               fontSize: 15,
//                               fontWeight: FontWeight.bold,
//                               color: color,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }),
//               ),
//               if (routePoints.isNotEmpty)
//                 PolylineLayer(
//                   polylines: _buildSegmentPolylines(),
//                 ),
//             ],
//           ),
//
//           // Collapsible Waypoints Panel
//           Positioned(
//             top: 10,
//             left: 10,
//             right: 10,
//             child: Card(
//               elevation: 6,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Header
//                   InkWell(
//                     onTap: () => setState(() => _isPanelExpanded = !_isPanelExpanded),
//                     borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                       decoration: BoxDecoration(
//                         color: Colors.blue.shade50,
//                         borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
//                       ),
//                       child: Row(
//                         children: [
//                           const Icon(Icons.route, color: Colors.blue),
//                           const SizedBox(width: 12),
//                           const Expanded(
//                             child: Text(
//                               'Waypoints',
//                               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                             ),
//                           ),
//                           Icon(
//                             _isPanelExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
//                             color: Colors.blue.shade800,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//
//                   // Content
//                   AnimatedContainer(
//                     duration: const Duration(milliseconds: 280),
//                     curve: Curves.easeInOut,
//                     height: _isPanelExpanded
//                         ? null
//                         : 0,
//                     child: ConstrainedBox(
//                       constraints: const BoxConstraints(maxHeight: 340),
//                       child: SingleChildScrollView(
//                         child: Padding(
//                           padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
//                           child: Column(
//                             children: [
//                               ReorderableListView.builder(
//                                 shrinkWrap: true,
//                                 physics: const NeverScrollableScrollPhysics(),
//                                 itemCount: _waypointControllers.length,
//                                 itemBuilder: (context, index) {
//                                   final color = waypointColors[index % waypointColors.length];
//                                   return Container(
//                                     key: ValueKey(index),
//                                     margin: const EdgeInsets.only(bottom: 10),
//                                     child: Row(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Container(
//                                           width: 38,
//                                           height: 38,
//                                           decoration: BoxDecoration(
//                                             color: color,
//                                             shape: BoxShape.circle,
//                                           ),
//                                           child: const Center(
//                                             child: Icon(Icons.drag_handle, color: Colors.white, size: 20),
//                                           ),
//                                         ),
//                                         const SizedBox(width: 10),
//                                         Expanded(
//                                           child: TypeAheadField<Map<String, dynamic>>(
//                                             controller: _waypointControllers[index],
//                                             focusNode: _waypointFocusNodes[index],
//                                             debounceDuration: const Duration(milliseconds: 350),
//                                             suggestionsCallback: searchPlaces,
//                                             itemBuilder: (context, suggestion) => ListTile(
//                                               leading: const Icon(Icons.location_on),
//                                               title: Text(
//                                                 suggestion['display_name'] ?? 'Unknown',
//                                                 maxLines: 2,
//                                                 overflow: TextOverflow.ellipsis,
//                                               ),
//                                             ),
//                                             onSelected: (suggestion) => setWaypoint(index, suggestion),
//                                             builder: (context, controller, focusNode) => TextField(
//                                               controller: controller,
//                                               focusNode: focusNode,
//                                               decoration: InputDecoration(
//                                                 filled: true,
//                                                 fillColor: Colors.white,
//                                                 labelText: 'Waypoint ${index + 1}',
//                                                 hintText: 'Search or tap map...',
//                                                 prefixIcon: Icon(Icons.location_on, color: color),
//                                                 suffixIcon: _waypointControllers.length > 2
//                                                     ? IconButton(
//                                                   icon: const Icon(Icons.close, size: 20),
//                                                   onPressed: () => _removeWaypointField(index),
//                                                 )
//                                                     : null,
//                                                 border: OutlineInputBorder(
//                                                   borderRadius: BorderRadius.circular(12),
//                                                 ),
//                                                 contentPadding: const EdgeInsets.symmetric(vertical: 14),
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   );
//                                 },
//                                 onReorder: _reorderWaypoint,
//                               ),
//                               const SizedBox(height: 12),
//                               TextButton.icon(
//                                 onPressed: _addWaypointField,
//                                 icon: const Icon(Icons.add_location_alt),
//                                 label: const Text('Add Another Waypoint'),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           // Bottom action buttons
//           Positioned(
//             bottom: 20,
//             left: 20,
//             right: 20,
//             child: Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: calculateRoute,
//                     icon: const Icon(Icons.route),
//                     label: const Text('Calculate Route'),
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       backgroundColor: Colors.blue,
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: openSaveScreen,
//                     icon: Icon(widget.isEditMode ? Icons.save : Icons.save),
//                     label: Text(widget.isEditMode ? 'Save Changes' : 'Save Route'),
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       backgroundColor: Colors.green,
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // Summary card
//           if (routePoints.isNotEmpty)
//             Positioned(
//               bottom: 90,
//               left: 20,
//               right: 20,
//               child: Card(
//                 elevation: 6,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Row(
//                         children: [
//                           const Icon(Icons.route, color: Colors.blue),
//                           const SizedBox(width: 8),
//                           Text(
//                             widget.isEditMode ? "Editing Route" : "Route Preview",
//                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                           ),
//                           const Spacer(),
//                           Chip(
//                             label: Text('${waypoints.where((p) => p != LatLng(0, 0)).length} points'),
//                             backgroundColor: Colors.blue.shade100,
//                           ),
//                         ],
//                       ),
//                       const Divider(height: 24),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           _buildStatColumn(
//                             icon: Icons.straighten,
//                             color: Colors.blue,
//                             value: "${totalDistance.toStringAsFixed(1)} km",
//                             label: "Distance",
//                           ),
//                           _buildStatColumn(
//                             icon: Icons.access_time,
//                             color: Colors.orange,
//                             value: totalDuration.isEmpty ? '-' : totalDuration,
//                             label: "Duration",
//                           ),
//                         ],
//                       ),
//                       if (segmentDistances.isNotEmpty)
//                         Padding(
//                           padding: const EdgeInsets.only(top: 12),
//                           child: Text(
//                             'Segments: ${segmentDistances.length}',
//                             style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatColumn({
//     required IconData icon,
//     required Color color,
//     required String value,
//     required String label,
//   }) {
//     return Column(
//       children: [
//         Icon(icon, color: color, size: 28),
//         const SizedBox(height: 6),
//         Text(
//           value,
//           style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
//         ),
//         Text(
//           label,
//           style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
//         ),
//       ],
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_typeahead/flutter_typeahead.dart';
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

  final List<TextEditingController> _waypointControllers = [];
  final List<FocusNode> _waypointFocusNodes = [];

  // Panel states
  bool _isPanelExpanded = true;
  bool _isCalculated = false;
  bool _isCalculating = false;
  bool _showRouteInfo = false;
  bool _showSaveButton = false;

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

  @override
  void dispose() {
    for (var controller in _waypointControllers) {
      controller.dispose();
    }
    for (var focusNode in _waypointFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
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
        'name': place['display_name'] ?? 'Waypoint ${index + 1}',
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
            'name': 'Waypoint ${index + 1}',
            'address': address,
          };
          _waypointControllers[index].text = address;
        });
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
      setState(() {
        waypointInfo[index] = {
          'lat': point.latitude,
          'lng': point.longitude,
          'name': 'Waypoint ${index + 1}',
          'address':
          '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
        };
        _waypointControllers[index].text =
        '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
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

    try {
      final existingSegments = await DBHelper.getSegmentsByRouteId(routeId);
      if (existingSegments.isNotEmpty) {
        province = existingSegments.first['province']?.toString() ?? province;
        city = existingSegments.first['city']?.toString() ?? city;
        date = existingSegments.first['date']?.toString() ?? date;
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
    if (! _isCalculated) {
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
        ),
      ),
    );
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
    });
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
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.map_routing',
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

          // Top App Bar
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

          // Floating Save Button (always at bottom)
          if (_showSaveButton)
            Positioned(
              bottom: _isPanelExpanded ? 340 : 80,
              left: 20,
              right: 20,
              child: Container(
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