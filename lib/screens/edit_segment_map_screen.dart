import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditSegmentMapScreen extends StatefulWidget {
  final Map<String, dynamic> segment;
  final int segmentNumber;

  EditSegmentMapScreen({
    required this.segment,
    required this.segmentNumber,
  });

  @override
  State<EditSegmentMapScreen> createState() => _EditSegmentMapScreenState();
}

class _EditSegmentMapScreenState extends State<EditSegmentMapScreen> {
  late MapController mapController;
  LatLng? startPoint;
  LatLng? endPoint;
  List<LatLng> routePoints = [];
  double? distance;
  String? duration;
  String startName = '';
  String endName = '';
  bool _isLoadingRoute = false;
  bool _showDetailsCard = true;

  @override
  void initState() {
    super.initState();
    mapController = MapController();

    // Initialize with existing segment data
    startPoint = LatLng(
      widget.segment['start_lat'] as double,
      widget.segment['start_lng'] as double,
    );
    endPoint = LatLng(
      widget.segment['end_lat'] as double,
      widget.segment['end_lng'] as double,
    );
    startName = widget.segment['start_name'] ?? '';
    endName = widget.segment['end_name'] ?? '';
    distance = widget.segment['segment_distance'] as double;
    duration = widget.segment['segment_duration'] as String;
  }

  void onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      if (startPoint == null) {
        startPoint = point;
        _fetchLocationName(point, true);
      } else if (endPoint == null) {
        endPoint = point;
        _fetchLocationName(point, false);
        _fetchRoute();
      } else {
        // Reset and start over
        startPoint = point;
        endPoint = null;
        routePoints.clear();
        distance = null;
        duration = null;
        _fetchLocationName(point, true);
      }
    });
  }

  Future<void> _fetchLocationName(LatLng point, bool isStart) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?'
            'lat=${point.latitude}&lon=${point.longitude}&format=json',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'FlutterMapApp'},
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final name = data['display_name'] ?? 'Unknown Location';

        setState(() {
          if (isStart) {
            startName = _getShortLocation(name);
          } else {
            endName = _getShortLocation(name);
          }
        });
      }
    } catch (e) {
      print('Error fetching location name: $e');
      setState(() {
        if (isStart) {
          startName = 'Location ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
        } else {
          endName = 'Location ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
        }
      });
    }
  }

  String _getShortLocation(String fullAddress) {
    final parts = fullAddress.split(',');
    if (parts.length >= 2) {
      return '${parts[0].trim()}, ${parts[1].trim()}';
    }
    return fullAddress.length > 50
        ? '${fullAddress.substring(0, 47)}...'
        : fullAddress;
  }

  Future<void> _fetchRoute() async {
    if (startPoint == null || endPoint == null) return;

    setState(() {
      _isLoadingRoute = true;
      routePoints.clear();
    });

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
            '${startPoint!.longitude},${startPoint!.latitude};'
            '${endPoint!.longitude},${endPoint!.latitude}'
            '?overview=full&geometries=geojson',
      );

      final response = await http.get(url).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coords = route['geometry']['coordinates'] as List;

          setState(() {
            routePoints = coords
                .map((coord) => LatLng(coord[1] as double, coord[0] as double))
                .toList();

            distance = (route['distance'] as num) / 1000.0;
            final durationSec = (route['duration'] as num).toInt();
            duration = _formatDuration(durationSec);
          });

          // Fit map to show the route
          if (routePoints.isNotEmpty) {
            final bounds = LatLngBounds.fromPoints(routePoints);
            mapController.fitCamera(
              CameraFit.bounds(
                bounds: bounds,
                padding: EdgeInsets.all(50),
              ),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching route: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return minutes > 0 ? '$hours hr $minutes min' : '$hours hr';
    }
    return '$minutes min';
  }

  void _saveSegment() {
    if (startPoint == null || endPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select both start and end points'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (distance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Route calculation is required'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Return the updated segment data
    Navigator.pop(context, {
      'start_name': startName,
      'start_lat': startPoint!.latitude,
      'start_lng': startPoint!.longitude,
      'end_name': endName,
      'end_lat': endPoint!.latitude,
      'end_lng': endPoint!.longitude,
      'distance': distance,
      'duration': duration,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Edit Segment ${widget.segmentNumber}'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (startPoint != null && endPoint != null && distance != null)
            IconButton(
              icon: Icon(Icons.check_circle),
              onPressed: _saveSegment,
              tooltip: 'Save Segment',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: startPoint ?? LatLng(32.5007, 74.5260),
              initialZoom: 13.0,
              onTap: onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              // Route polyline
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: Colors.blue.shade700,
                      strokeWidth: 5.0,
                    ),
                  ],
                ),
              // Markers
              MarkerLayer(
                markers: [
                  if (startPoint != null)
                    Marker(
                      point: startPoint!,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                  if (endPoint != null)
                    Marker(
                      point: endPoint!,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Loading indicator
          if (_isLoadingRoute)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Calculating route...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Top Instructions Card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.edit_location,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Segment ${widget.segmentNumber}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    if (startPoint == null)
                      _buildInstructionRow(
                        '📍 Tap on map to set START point',
                        Colors.green.shade700,
                      )
                    else if (endPoint == null)
                      _buildInstructionRow(
                        '📍 Tap on map to set END point',
                        Colors.red.shade700,
                      )
                    else if (distance != null && duration != null)
                        _buildSuccessRow(),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Details Card
          if (_showDetailsCard && startPoint != null && endPoint != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Locations
                      _buildLocationRow(
                        Icons.circle,
                        Colors.green,
                        startName.isEmpty ? 'Start Point' : startName,
                      ),
                      SizedBox(height: 8),
                      _buildLocationRow(
                        Icons.circle,
                        Colors.red,
                        endName.isEmpty ? 'End Point' : endName,
                      ),

                      if (distance != null && duration != null) ...[
                        Divider(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                Icons.straighten,
                                '${distance!.toStringAsFixed(2)} km',
                                'Distance',
                                Colors.blue,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                Icons.access_time,
                                duration!,
                                'Duration',
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: (startPoint != null && endPoint != null && distance != null)
          ? FloatingActionButton.extended(
        onPressed: _saveSegment,
        icon: Icon(Icons.save),
        label: Text('Save Changes'),
        backgroundColor: Colors.green,
      )
          : null,
    );
  }

  Widget _buildInstructionRow(String text, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.touch_app, color: color, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessRow() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '✅ Route calculated successfully',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}