// lib/geofancing/real_time_navigation_screen.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'package:routing_0sm/geofencing/routes_add_shop_model.dart';
import 'package:routing_0sm/geofencing/shop_service.dart';
import 'dart:convert';

import '../Database/db_service.dart';

import 'geofencing_service.dart';
import 'navigation_theme.dart';
import 'off_route_address_screen.dart';
// 🆕 IMPORT SHOP MODEL

class RealTimeNavigationScreen extends StatefulWidget {
  final int routeId;
  final List<LatLng>? routePolyline;
  final String routeName;

  const RealTimeNavigationScreen({
    super.key,
    required this.routeId,
    this.routePolyline,
    this.routeName = 'Real-Time Navigation',
  });

  @override
  State<RealTimeNavigationScreen> createState() => _RealTimeNavigationScreenState();
}

class _RealTimeNavigationScreenState extends State<RealTimeNavigationScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final GeofencingService _geofencingService = GeofencingService();
  final Distance _distance = Distance();
  final RouteDurationTracker _durationTracker = RouteDurationTracker();

  // 🆕 SHOPS VARIABLES
  List<AddShopModel> _oracleShops = [];
  List<AddShopModel> _nearbyShops = [];
  bool _loadingShops = false;
  double _shopFilterRadius = 500.0; // meters
  bool _showShops = true;

  List<LatLng> _route = [];
  List<Map<String, dynamic>> _waypoints = [];
  LatLng? _currentPosition;
  StreamSubscription<Position>? _positionSub;
  Timer? _durationUpdateTimer;

  bool _loading = true;
  bool _isNavigating = false;
  String _statusText = 'Ready to Start';

  bool _isFollowing = true;
  LatLng? _mapCenter;
  double _currentZoom = 16.0;
  double _geofenceBuffer = 50.0;
  double _totalRouteMeters = 0.0;
  double _heading = 0.0;
  double _accuracy = 0.0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ===== NEW: OFF-ROUTE ADDRESS HANDLING =====
  String? _offRouteAddress;
  DateTime? _lastAddressFetch;
  LatLng? _lastAddressCoord;
  final Duration _addressFetchInterval = const Duration(seconds: 10);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _durationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isNavigating && mounted) {
        setState(() {});
      }
    });

    _initRoute();
    _fetchOracleShops(); // 🆕 GET SHOPS FROM ORACLE

    _geofencingService.setRouteChangeCallback((status, message) {
      if (!mounted) return;

      // Show the same snackbar as before
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(status == 'On Route' ? Icons.check_circle : Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
            ],
          ),
          backgroundColor: status == 'On Route' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );

      // 🆕 If we transitioned to Off Route, attempt to fetch address for current location
      if (status != 'On Route') {
        if (_currentPosition != null) {
          _fetchOffRouteAddress(_currentPosition!);
        }
      } else {
        // On route: clear off-route address
        setState(() {
          _offRouteAddress = null;
        });
      }
    });

    _geofencingService.setStatusCallback((message) {
      print('Geofencing status: $message');
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _durationUpdateTimer?.cancel();
    _stopNavigation();
    _geofencingService.stopMonitoring();
    super.dispose();
  }

  // ============== 🆕 ORACLE GET API ==============
// 🟢 YEH METHOD CHANGE KARO
  Future<void> _fetchOracleShops() async {
    setState(() => _loadingShops = true);

    // 🔴 ROUTE ID PASS KARO
    final shops = await ShopService.fetchShopsByRouteId(widget.routeId);

    setState(() {
      _oracleShops = shops;
      _nearbyShops = shops; // ✅ Already filtered by route ID from API
      _loadingShops = false;
    });

    print('🏪 Route ke liye ${shops.length} shops aye');
  }

  // ============== 🆕 FILTER SHOPS NEAR ROUTE ==============
  void _filterNearbyShops() {
    if (_route.isEmpty || _oracleShops.isEmpty) return;

    final nearby = ShopService.filterShopsNearRoute(
      allShops: _oracleShops,
      routePoints: _route,
      bufferMeters: _shopFilterRadius,
    );

    setState(() {
      _nearbyShops = nearby;
    });

    print('📍 Route ke along ${nearby.length} shops milli');
  }

  // ============== 🆕 SHOW SHOP DETAILS ==============
  void _showShopDetails(AddShopModel shop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(shop.shop_name ?? 'Shop Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (shop.shop_address != null)
              Text('📍 Address: ${shop.shop_address}'),
            if (shop.latitude != null)
              Text('🌐 Lat: ${shop.latitude}'),
            if (shop.longitude != null)
              Text('🌐 Lng: ${shop.longitude}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _navigateToShop(AddShopModel shop) {
    final lat = shop.lat;
    final lng = shop.lng;

    if (lat == null || lng == null) return;

    final shopLocation = LatLng(lat, lng);
    _animateMapMove(shopLocation, durationMs: 800);
  }

  // ============== 🆕 SHOP CONTROLS WIDGET ==============
  Widget _buildShopControls() {
    return Positioned(
      left: 16,
      bottom: 100,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _showShops = !_showShops),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _showShops ? const Color(0xFFF59E0B) : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.store,
                      color: _showShops ? Colors.white : Colors.grey.shade700,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_nearbyShops.length} Shops Nearby',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _showShops ? Colors.black87 : Colors.grey,
                  ),
                ),
                if (_loadingShops) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF59E0B)),
                  ),
                ],
              ],
            ),
            if (_showShops) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.social_distance, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text('Radius:', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: Slider(
                      value: _shopFilterRadius,
                      min: 100,
                      max: 2000,
                      divisions: 19,
                      activeColor: const Color(0xFFF59E0B),
                      label: '${_shopFilterRadius.round()}m',
                      onChanged: (value) {
                        setState(() => _shopFilterRadius = value);
                        _filterNearbyShops();
                      },
                    ),
                  ),
                  Text(
                    '${_shopFilterRadius.round()}m',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============== ROUTE INITIALIZATION ==============
  Future<void> _initRoute() async {
    try {
      if (widget.routePolyline != null && widget.routePolyline!.isNotEmpty) {
        _route = List.from(widget.routePolyline!);
      } else {
        final segments = await DBHelper.getSegmentsByRouteId(widget.routeId);

        if (segments.isNotEmpty && segments.first['waypoints'] != null) {
          final waypointsJson = segments.first['waypoints'] as String?;
          if (waypointsJson != null && waypointsJson.isNotEmpty) {
            final waypoints = jsonDecode(waypointsJson) as List<dynamic>;
            if (waypoints.length >= 2) {
              await _calculateFullRouteFromWaypoints(waypoints);
            }
          }
        }

        if (_route.isEmpty && segments.isNotEmpty) {
          final tmp = <LatLng>[];
          for (final s in segments) {
            final startLat = s['start_lat'] as double?;
            final startLng = s['start_lng'] as double?;
            final endLat = s['end_lat'] as double?;
            final endLng = s['end_lng'] as double?;

            if (startLat != null && startLng != null) tmp.add(LatLng(startLat, startLng));
            if (endLat != null && endLng != null && s == segments.last) {
              tmp.add(LatLng(endLat, endLng));
            }
          }

          if (tmp.length >= 2) {
            await _calculateFullRouteFromPoints(tmp);
          } else {
            _route = tmp;
          }
        }
      }

      if (_route.isEmpty) {
        if (mounted) {
          setState(() {
            _loading = false;
            _statusText = 'No route polyline available';
          });
        }
        return;
      }

      _totalRouteMeters = 0.0;
      for (int i = 0; i < _route.length - 1; i++) {
        _totalRouteMeters += _distance(_route[i], _route[i + 1]);
      }

      _mapCenter = _route.first;
      await _loadWaypoints();

      if (mounted) {
        setState(() {
          _loading = false;
          _statusText = 'Ready to Start';
        });

        // 🆕 FILTER SHOPS AFTER ROUTE LOADED
        if (_oracleShops.isNotEmpty) {
          _filterNearbyShops();
        }
      }
    } catch (e) {
      print('Error loading route: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _statusText = 'Failed to load route';
        });
      }
    }
  }

  Future<void> _loadWaypoints() async {
    try {
      final segments = await DBHelper.getSegmentsByRouteId(widget.routeId);
      if (segments.isNotEmpty) {
        for (int i = 0; i < segments.length; i++) {
          final segment = segments[i];
          final startLat = segment['start_lat'] as double?;
          final startLng = segment['start_lng'] as double?;
          final startName = segment['start_name']?.toString() ?? 'Point ${i + 1}';

          if (startLat != null && startLng != null) {
            _waypoints.add({
              'lat': startLat,
              'lng': startLng,
              'name': startName,
              'index': i,
            });
          }
        }

        final lastSegment = segments.last;
        final endLat = lastSegment['end_lat'] as double?;
        final endLng = lastSegment['end_lng'] as double?;
        final endName = lastSegment['end_name']?.toString() ?? 'End Point';

        if (endLat != null && endLng != null) {
          _waypoints.add({
            'lat': endLat,
            'lng': endLng,
            'name': endName,
            'index': segments.length,
          });
        }
      }
    } catch (e) {
      print('Error loading waypoints: $e');
    }
  }

  Future<void> _calculateFullRouteFromWaypoints(List<dynamic> waypoints) async {
    try {
      final List<LatLng> latLngWaypoints = [];
      for (final wp in waypoints) {
        if (wp is Map<String, dynamic>) {
          final lat = (wp['lat'] is double) ? wp['lat'] : double.tryParse(wp['lat'].toString());
          final lng = (wp['lng'] is double) ? wp['lng'] : double.tryParse(wp['lng'].toString());
          if (lat != null && lng != null) latLngWaypoints.add(LatLng(lat, lng));
        }
      }
      if (latLngWaypoints.length >= 2) {
        await _calculateFullRouteFromPoints(latLngWaypoints);
      }
    } catch (e) {
      print('Error processing waypoints: $e');
    }
  }

  Future<void> _calculateFullRouteFromPoints(List<LatLng> points) async {
    try {
      final List<LatLng> fullRoute = [];
      for (int i = 0; i < points.length - 1; i++) {
        final start = points[i];
        final end = points[i + 1];
        final segmentRoute = await _fetchOSRMRoute(start, end);
        if (segmentRoute.isNotEmpty) {
          if (i == 0) {
            fullRoute.addAll(segmentRoute);
          } else {
            fullRoute.addAll(segmentRoute.sublist(1));
          }
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (fullRoute.isNotEmpty) {
        setState(() {
          _route = fullRoute;
        });
      }
    } catch (e) {
      print('Error calculating full route: $e');
    }
  }

  Future<List<LatLng>> _fetchOSRMRoute(LatLng start, LatLng end) async {
    try {
      final url = Uri.parse(
        "https://router.project-osrm.org/route/v1/driving/"
            "${start.longitude},${start.latitude};${end.longitude},${end.latitude}"
            "?overview=full&geometries=geojson&steps=true",
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coords = route['geometry']['coordinates'] as List;
          return coords.map((c) => LatLng(c[1], c[0])).toList();
        }
      }
    } catch (e) {
      print('OSRM API error: $e');
    }
    return [start, end];
  }

  // ============== POSITION STREAM ==============
  Future<void> _startPositionStream() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
      return;
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    ).listen((Position pos) {
      _onNewPosition(pos);
    });
  }

  void _onNewPosition(Position pos) {
    final newPos = LatLng(pos.latitude, pos.longitude);
    _currentPosition = newPos;
    _heading = (pos.heading.isNaN) ? _heading : pos.heading;
    _accuracy = pos.accuracy;
    _updateRouteDuration();
    if (_isFollowing && _isNavigating) _animateMapMove(newPos, durationMs: 600);

    // ===== NEW: fetch off-route address when off-route, but rate-limit =====
    final bool isOnRoute = _geofencingService.isOnRoute.value;
    if (_isNavigating && !isOnRoute) {
      _fetchOffRouteAddress(newPos);
    }

    if (mounted) setState(() {});
  }

  void _updateRouteDuration() {
    if (_isNavigating) {
      _durationTracker.updateStatus(_geofencingService.isOnRoute.value);
    }
  }

  // ===== NEW: reverse geocode (Nominatim) =====
  Future<void> _fetchOffRouteAddress(LatLng pos) async {
    try {
      final now = DateTime.now();

      // Rate-limit requests to avoid hammering the service
      if (_lastAddressFetch != null && now.difference(_lastAddressFetch!) < _addressFetchInterval) {
        // If coordinates haven't changed much, skip
        if (_lastAddressCoord != null) {
          final dist = _distance(pos, _lastAddressCoord!);
          if (dist < 10) return; // less than 10 meters change
        }
      }

      _lastAddressFetch = now;
      _lastAddressCoord = pos;

      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${pos.latitude}&lon=${pos.longitude}&addressdetails=1');
      final response = await http.get(url, headers: {'User-Agent': 'routing_0sm_app/1.0 (+https://example.com)'}).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? displayName = data['display_name'] as String?;
        if (displayName == null || displayName.isEmpty) {
          // Try to assemble from address components
          final address = data['address'] as Map<String, dynamic>?;
          if (address != null) {
            final parts = <String>[];
            for (final key in ['road', 'neighbourhood', 'suburb', 'city', 'county', 'state', 'postcode', 'country']) {
              if (address[key] != null) parts.add(address[key].toString());
            }
            displayName = parts.join(', ');
          }
        }

        if (mounted) {
          setState(() {
            _offRouteAddress = (displayName != null && displayName.isNotEmpty) ? displayName : 'Address not found';
          });
        }
      } else {
        if (mounted) setState(() => _offRouteAddress = 'Unable to determine address');
      }
    } catch (e) {
      if (mounted) setState(() => _offRouteAddress = 'Unable to determine address');
      print('Reverse geocode error: $e');
    }
  }

  // ============== MAP ANIMATION ==============
  void _animateMapMove(LatLng target, {int durationMs = 500}) {
    try {
      final steps = 8;
      final stepMs = max(16, (durationMs / steps).round());
      int step = 0;
      final currentCenter = _mapCenter ?? (_currentPosition ?? _route.first);
      final latDelta = (target.latitude - currentCenter.latitude) / steps;
      final lngDelta = (target.longitude - currentCenter.longitude) / steps;
      Timer.periodic(Duration(milliseconds: stepMs), (t) {
        step++;
        final lat = currentCenter.latitude + latDelta * step;
        final lng = currentCenter.longitude + lngDelta * step;
        final newCenter = LatLng(lat, lng);
        _mapController.move(newCenter, _currentZoom);
        _mapCenter = newCenter;
        if (step >= steps) t.cancel();
      });
    } catch (_) {
      _mapController.move(target, _currentZoom);
      _mapCenter = target;
    }
  }

  void _fitMapToRoute() {
    if (_route.isEmpty) return;
    double minLat = _route[0].latitude, maxLat = _route[0].latitude;
    double minLng = _route[0].longitude, maxLng = _route[0].longitude;
    for (final point in _route) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)));
  }

  // ============== NAVIGATION CONTROL ==============
  Future<void> _toggleNavigation() async {
    if (_isNavigating) {
      _stopNavigation();
      setState(() => _isNavigating = false);
    } else {
      try {
        await _startNavigation();
        setState(() => _isNavigating = true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start navigation: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  Future<void> _startNavigation() async {
    if (_route.isEmpty) throw Exception('Route polyline not available');
    _durationTracker.reset();
    _durationTracker.startTracking(_geofencingService.isOnRoute.value);
    await _geofencingService.startMonitoringRoute(_route, bufferDistance: _geofenceBuffer);
    _geofencingService.isOnRoute.value = false;
    await _startPositionStream();
    _durationUpdateTimer?.cancel();
    _durationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isNavigating && mounted) setState(() {});
    });
    if (mounted) setState(() => _statusText = '✅ Navigating...');
  }

  void _stopNavigation() {
    _positionSub?.cancel();
    _positionSub = null;
    _geofencingService.stopMonitoring();
    _durationTracker.stopTracking();
    _durationUpdateTimer?.cancel();
    if (mounted) {
      setState(() {
        _heading = 0.0;
        _accuracy = 0.0;
        _currentPosition = null;
        _statusText = 'Ready to Start';
        _offRouteAddress = null; // clear on stop
      });
    }
  }

  // ============== UI COMPONENTS ==============
  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isNavigating
              ? [const Color(0xFF3B82F6), const Color(0xFF2563EB), const Color(0xFF1D4ED8)]
              : [const Color(0xFF64748B), const Color(0xFF475569)],
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context), padding: const EdgeInsets.all(8)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.routeName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                        const SizedBox(height: 4),
                        ValueListenableBuilder<bool>(
                          valueListenable: _geofencingService.isOnRoute,
                          builder: (context, isOnRoute, child) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _isNavigating
                                        ? (isOnRoute ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFFEF4444).withOpacity(0.3))
                                        : Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _isNavigating ? (isOnRoute ? const Color(0xFF10B981) : const Color(0xFFEF4444)) : Colors.white70)),
                                      const SizedBox(width: 6),
                                      Text(_isNavigating ? (isOnRoute ? 'On Route' : 'Off Route') : 'Stopped', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),

                                // ===== NEW: Show Off-Route Address & Duration =====
                                if (_isNavigating && !isOnRoute) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            // only navigate if we have an address to show
                                            if (_offRouteAddress != null && _offRouteAddress!.isNotEmpty) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      OffRouteAddressPage(
                                                    name: widget.routeName, // send route name (or change to another source if you want)
                                                    address: _offRouteAddress!,
                                                  ),
                                                ),
                                              );
                                            } else {
                                              // optional: show temporary message when address not ready
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Address is not ready yet')),
                                              );
                                            }
                                          },
                                          child: Text(
                                            _offRouteAddress ?? 'Determining address...',
                                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),


                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text('Off Route', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                            const SizedBox(height: 2),
                                            Text(_durationTracker.formattedOffRouteDuration, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ValueListenableBuilder<bool>(
                valueListenable: _geofencingService.isOnRoute,
                builder: (context, isOnRoute, child) {
                  return Row(
                    children: [
                      Expanded(child: _buildStatCard(icon: Icons.check_circle_rounded, label: 'On Route', value: _durationTracker.formattedOnRouteDuration, color: const Color(0xFF10B981), isActive: _isNavigating && isOnRoute)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(icon: Icons.warning_rounded, label: 'Off Route', value: _durationTracker.formattedOffRouteDuration, color: const Color(0xFFEF4444), isActive: _isNavigating && !isOnRoute)),
                      const SizedBox(width: 12),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String label, required String value, required Color color, required bool isActive}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isActive ? 0.25 : 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(isActive ? 0.4 : 0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildNavigationButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: (_isNavigating ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleNavigation,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isNavigating ? [const Color(0xFFEF4444), const Color(0xFFDC2626)] : [const Color(0xFF10B981), const Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isNavigating ? _pulseAnimation.value : 1.0,
                      child: Icon(_isNavigating ? Icons.stop_circle : Icons.play_circle_filled, color: Colors.white, size: 28),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Text(_isNavigating ? 'STOP NAVIGATION' : 'START NAVIGATION', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingControls() {
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).padding.top + 220,
      child: Column(
        children: [
          _buildControlButton(
            icon: Icons.zoom_in,
            onPressed: () {
              setState(() => _currentZoom = min(_currentZoom + 1, 18));
              _mapController.move(_mapCenter ?? _route.first, _currentZoom);
            },
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 12),
          _buildControlButton(
            icon: Icons.zoom_out,
            onPressed: () {
              setState(() => _currentZoom = max(_currentZoom - 1, 10));
              _mapController.move(_mapCenter ?? _route.first, _currentZoom);
            },
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 12),
          _buildControlButton(
            icon: Icons.store,
            onPressed: () {
              setState(() => _showShops = !_showShops);
              if (_showShops && _nearbyShops.isEmpty && _oracleShops.isNotEmpty) {
                _filterNearbyShops();
              }
            },
            isActive: _showShops,
            color: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required VoidCallback onPressed, bool isActive = false, required Color color}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: isActive ? color : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(width: 54, height: 54, alignment: Alignment.center, child: Icon(icon, color: isActive ? Colors.white : color, size: 26)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _loading
          ? Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              ),
              const SizedBox(height: 24),
              const Text('Loading route...', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Text('Please wait', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
            ],
          ),
        ),
      )
          : Stack(
        children: [
          // 🗺️ MAP
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _route.isNotEmpty ? _route.first : LatLng(0, 0),
                initialZoom: _currentZoom,
                onMapReady: () {
                  if (_route.isNotEmpty) _fitMapToRoute();
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.map_routing',
                ),

                // 🟦 ROUTE POLYLINE
                if (_route.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _route,
                        color: _isNavigating ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8),
                        strokeWidth: 5,
                        borderColor: Colors.white,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),

                // 🟢🔵🔴 WAYPOINTS
                if (_waypoints.isNotEmpty)
                  MarkerLayer(
                    markers: _waypoints.map((wp) {
                      final index = wp['index'] as int;
                      final name = wp['name'] as String;
                      final lat = wp['lat'] as double;
                      final lng = wp['lng'] as double;
                      final isFirst = index == 0;
                      final isLast = index == _waypoints.length - 1;

                      return Marker(
                        point: LatLng(lat, lng),
                        width: 80,
                        height: 100,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isFirst
                                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                      : isLast
                                      ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                                      : [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
                              ),
                              child: Icon(isFirst ? Icons.flag_rounded : isLast ? Icons.location_on : Icons.place_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(height: 8),
                            if (name.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: Text(name.length > 12 ? '${name.substring(0, 12)}...' : name, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                // 🟠🟡 SHOP MARKERS - ORACLE GET API SE FETCHED
                // 🟠 SHOP MARKERS - YEH CODE FlutterMap KE children MEIN HAI
                if (_showShops && _nearbyShops.isNotEmpty)
                  MarkerLayer(
                    markers: _nearbyShops.map((shop) {
                      final lat = shop.lat;
                      final lng = shop.lng;

                      if (lat == null || lng == null) return const Marker(point: LatLng(0, 0), width: 0, height: 0, child: SizedBox());

                      return Marker(
                        point: LatLng(lat, lng),
                        width: 80,
                        height: 90,
                        child: GestureDetector(
                          onTap: () => _showShopDetails(shop),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF59E0B).withOpacity(0.5),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.store, color: Colors.white, size: 22),
                              ),
                              const SizedBox(height: 4),
                              if (shop.shop_name != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                                  ),
                                  child: Text(
                                    shop.shop_name!.length > 12
                                        ? '${shop.shop_name!.substring(0, 12)}...'
                                        : shop.shop_name!,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFF59E0B)
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                // ⚪ ACCURACY CIRCLE
                if (_currentPosition != null && _accuracy > 0 && _isNavigating)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _currentPosition!,
                        radius: _accuracy / 1.5,
                        useRadiusInMeter: true,
                        color: const Color(0xFF3B82F6).withOpacity(0.15),
                        borderStrokeWidth: 1,
                        borderColor: const Color(0xFF3B82F6).withOpacity(0.3),
                      ),
                    ],
                  ),

                // 🧭 CURRENT POSITION
                if (_currentPosition != null && _isNavigating)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentPosition!,
                        width: 60,
                        height: 60,
                        child: Transform.rotate(
                          angle: _heading * pi / 180,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.5), blurRadius: 16, offset: const Offset(0, 4))],
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 32),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // 🎯 TOP BAR
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),

          // 🎛️ FLOATING CONTROLS
          _buildFloatingControls(),

          // 🏪 SHOP CONTROLS - ORACLE GET API
          _buildShopControls(),

          // 🟢 BOTTOM NAVIGATION BUTTON
          Positioned(left: 0, right: 0, bottom: 20, child: Column(children: [_buildNavigationButton()])),
        ],
      ),
    );
  }
}