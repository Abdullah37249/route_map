// file: lib/screens/route_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../Database/db_service.dart';
import 'multi_point_map_screen.dart';
import '../services/geofencing_service.dart';


class RouteTrackingScreen extends StatefulWidget {
  final int routeId;
  final String routeName;

  const RouteTrackingScreen({
    super.key,
    required this.routeId,
    this.routeName = 'Route Tracking',
  });

  @override
  State<RouteTrackingScreen> createState() => _RouteTrackingScreenState();
}

class _RouteTrackingScreenState extends State<RouteTrackingScreen> {
  final GeofencingService _geofencingService = GeofencingService();
  List<LatLng> _routePoints = [];
  bool _isLoading = true;
  bool _isTracking = false;
  double _geofenceBuffer = 50.0;
  String _routeDescription = '';
  String _statusMessage = '';
  Color _statusColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _loadRoute();

    // Set up callbacks
    _geofencingService.setRouteChangeCallback((status, message) {
      setState(() {
        _statusMessage = message;
        _statusColor = status == 'On Route' ? Colors.green : Colors.orange;
      });

      // Show a snackbar for route changes
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _statusColor,
          duration: Duration(seconds: 2),
        ),
      );
    });

    _geofencingService.setStatusCallback((message) {
      setState(() {
        _statusMessage = message;
      });
    });
  }

  @override
  void dispose() {
    _geofencingService.stopMonitoring();
    super.dispose();
  }

  Future<void> _loadRoute() async {
    try {
      final segments = await DBHelper.getSegmentsByRouteId(widget.routeId);

      if (segments.isNotEmpty) {
        _routeDescription = segments.first['start_name']?.toString() ?? '';
        if (segments.last['end_name'] != null) {
          _routeDescription += ' to ${segments.last['end_name']}';
        }
      }

      // Extract route points from segments
      for (final segment in segments) {
        final startLat = segment['start_lat'] as double?;
        final startLng = segment['start_lng'] as double?;
        final endLat = segment['end_lat'] as double?;
        final endLng = segment['end_lng'] as double?;

        if (startLat != null && startLng != null) {
          _routePoints.add(LatLng(startLat, startLng));
        }
        if (endLat != null && endLng != null && segment == segments.last) {
          _routePoints.add(LatLng(endLat, endLng));
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading route: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      await _geofencingService.stopMonitoring();
      setState(() {
        _isTracking = false;
      });
    } else {
      if (_routePoints.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No route points available'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      try {
        await _geofencingService.startMonitoringRoute(
          _routePoints,
          bufferDistance: _geofenceBuffer,
        );
        setState(() {
          _isTracking = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Route tracking started'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start tracking: $e'),
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

    // Update the geofencing service
    _geofencingService.updateBufferDistance(_geofenceBuffer);
  }

  void _editRoute() async {
    final segments = await DBHelper.getSegmentsByRouteId(widget.routeId);
    final waypoints = <Map<String, dynamic>>[];

    for (final segment in segments) {
      waypoints.add({
        'name': segment['start_name'] ?? 'Start',
        'lat': segment['start_lat'] ?? 0.0,
        'lng': segment['start_lng'] ?? 0.0,
      });
    }

    // Add the last end point
    if (segments.isNotEmpty) {
      final lastSegment = segments.last;
      waypoints.add({
        'name': lastSegment['end_name'] ?? 'End',
        'lat': lastSegment['end_lat'] ?? 0.0,
        'lng': lastSegment['end_lng'] ?? 0.0,
      });
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiPointMapScreen.editMode(
          existingWaypoints: waypoints,
          routeId: widget.routeId,
        ),
      ),
    );

    if (result == true) {
      // Route was edited, reload
      setState(() {
        _isLoading = true;
        _routePoints.clear();
      });
      await _loadRoute();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.routeName),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white),
            onPressed: _editRoute,
            tooltip: 'Edit Route',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading route...'),
          ],
        ),
      )
          : Column(
        children: [
          // Status display
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.route, color: Colors.blue, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _routeDescription,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_routePoints.length} points',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Tracking status
                ValueListenableBuilder<String>(
                  valueListenable: _geofencingService.geofenceStatus,
                  builder: (context, status, child) {
                    return Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: status == 'On Route'
                            ? Colors.green.withOpacity(0.1)
                            : status == 'Off Route'
                            ? Colors.red.withOpacity(0.1)
                            : status == 'Monitoring'
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: status == 'On Route'
                              ? Colors.green
                              : status == 'Off Route'
                              ? Colors.red
                              : status == 'Monitoring'
                              ? Colors.blue
                              : Colors.grey,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            status == 'On Route'
                                ? Icons.check_circle
                                : status == 'Off Route'
                                ? Icons.warning
                                : status == 'Monitoring'
                                ? Icons.location_on
                                : Icons.location_off,
                            color: status == 'On Route'
                                ? Colors.green
                                : status == 'Off Route'
                                ? Colors.red
                                : status == 'Monitoring'
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: status == 'On Route'
                                        ? Colors.green.shade800
                                        : status == 'Off Route'
                                        ? Colors.red.shade800
                                        : status == 'Monitoring'
                                        ? Colors.blue.shade800
                                        : Colors.grey.shade800,
                                  ),
                                ),
                                ValueListenableBuilder<double>(
                                  valueListenable: _geofencingService.distanceToRoute,
                                  builder: (context, distance, child) {
                                    return Text(
                                      'Distance: ${distance.toStringAsFixed(1)}m',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(height: 16),

                // Progress indicator
                ValueListenableBuilder<double>(
                  valueListenable: _geofencingService.distanceToRoute,
                  builder: (context, distance, child) {
                    final double progressValue = distance.clamp(0, 100) / 100;
                    return Column(
                      children: [
                        LinearProgressIndicator(
                          value: progressValue,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            distance <= _geofenceBuffer ? Colors.green : Colors.red,
                          ),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'On Route',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                              ),
                            ),
                            Text(
                              '${distance.toStringAsFixed(1)}m',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: distance <= _geofenceBuffer
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                            Text(
                              'Off Route',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Geofence settings
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.settings, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Geofence Settings',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text('Buffer Distance: ${_geofenceBuffer.round()}m'),
                Slider(
                  value: _geofenceBuffer,
                  min: 10,
                  max: 200,
                  divisions: 19,
                  onChanged: _updateGeofenceBuffer,
                  label: '${_geofenceBuffer.round()}m',
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('10m', style: TextStyle(fontSize: 12)),
                    Text('100m', style: TextStyle(fontSize: 12)),
                    Text('200m', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          // Status message
          if (_statusMessage.isNotEmpty)
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _statusColor),
              ),
              child: Row(
                children: [
                  Icon(
                    _statusColor == Colors.green ? Icons.check_circle :
                    _statusColor == Colors.red ? Icons.error : Icons.info,
                    color: _statusColor,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(color: Colors.grey.shade800),
                    ),
                  ),
                ],
              ),
            ),

          Spacer(),

          // Control buttons
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _toggleTracking,
                    icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                    label: Text(_isTracking ? 'Stop Tracking' : 'Start Tracking'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTracking ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}