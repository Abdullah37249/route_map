import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_typeahead/flutter_typeahead.dart';


class MapScreen extends StatefulWidget {
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final mapController = MapController();
  LatLng? startPoint;
  LatLng? endPoint;
  List<LatLng> routePoints = [];
  double distance = 0;
  String duration = '';

  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final FocusNode _startFocus = FocusNode();
  final FocusNode _endFocus = FocusNode();

  // Cache for search results with timestamp for freshness
  final Map<String, _CachedResult> _searchCache = {};

  // Search provider selection
  String _searchProvider = 'nominatim'; // nominatim, photon, or hybrid
  bool _isSearching = false;

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _startFocus.dispose();
    _endFocus.dispose();
    super.dispose();
  }

  // Advanced search with multiple providers and real-time data
  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.isEmpty || query.length < 3) return [];

    // Check cache (valid for 5 minutes)
    final cacheKey = query.toLowerCase();
    if (_searchCache.containsKey(cacheKey)) {
      final cached = _searchCache[cacheKey]!;
      if (DateTime.now().difference(cached.timestamp).inMinutes < 5) {
        return cached.results;
      }
    }

    setState(() => _isSearching = true);

    try {
      List<Map<String, dynamic>> results = [];

      switch (_searchProvider) {
        case 'nominatim':
          results = await _searchNominatim(query);
          break;
        case 'photon':
          results = await _searchPhoton(query);
          break;
        case 'hybrid':
        // Use both services and merge results
          final nominatimResults = await _searchNominatim(query);
          final photonResults = await _searchPhoton(query);
          results = _mergeResults(nominatimResults, photonResults);
          break;
      }

      // Cache the results
      _searchCache[cacheKey] = _CachedResult(
        results: results,
        timestamp: DateTime.now(),
      );

      setState(() => _isSearching = false);
      return results;
    } catch (e) {
      print('Search error: $e');
      setState(() => _isSearching = false);
      return [];
    }
  }

  // Nominatim search (OpenStreetMap) - More comprehensive
  Future<List<Map<String, dynamic>>> _searchNominatim(String query) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?'
              'q=${Uri.encodeQueryComponent(query)}'
              '&format=json'
              '&addressdetails=1'
              '&limit=10'
              '&dedupe=1'
              '&extratags=1'
              '&namedetails=1'
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
            'importance': item['importance'] ?? 0.0,
            'source': 'nominatim',
            'address': item['address'] ?? {},
            'icon': _getIconForType(item['type'] ?? 'unknown'),
          };
        }).toList();
      }
    } catch (e) {
      print('Nominatim search error: $e');
    }
    return [];
  }

  // Photon search (Komoot) - Fast and real-time
  Future<List<Map<String, dynamic>>> _searchPhoton(String query) async {
    try {
      final url = Uri.parse(
          'https://photon.komoot.io/api/?'
              'q=${Uri.encodeQueryComponent(query)}'
              '&limit=10'
              '&lang=en'
      );

      final res = await http.get(url).timeout(Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final features = data['features'] as List? ?? [];

        return features.map((feature) {
          final props = feature['properties'] ?? {};
          final coords = feature['geometry']['coordinates'] as List;

          return {
            'lat': coords[1].toString(),
            'lon': coords[0].toString(),
            'display_name': _formatPhotonName(props),
            'type': props['type'] ?? 'unknown',
            'importance': 0.5, // Photon doesn't provide importance
            'source': 'photon',
            'address': props,
            'icon': _getIconForType(props['type'] ?? 'unknown'),
          };
        }).toList();
      }
    } catch (e) {
      print('Photon search error: $e');
    }
    return [];
  }

  // Merge and deduplicate results from multiple sources
  List<Map<String, dynamic>> _mergeResults(
      List<Map<String, dynamic>> list1,
      List<Map<String, dynamic>> list2,
      ) {
    final merged = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (final result in [...list1, ...list2]) {
      final key = '${result['lat']}_${result['lon']}';
      if (!seen.contains(key)) {
        seen.add(key);
        merged.add(result);
      }
    }

    // Sort by importance
    merged.sort((a, b) {
      final importanceA = (a['importance'] as num?)?.toDouble() ?? 0.0;
      final importanceB = (b['importance'] as num?)?.toDouble() ?? 0.0;
      return importanceB.compareTo(importanceA);
    });

    return merged.take(10).toList();
  }

  // Format Photon result name
  String _formatPhotonName(Map<String, dynamic> props) {
    final parts = <String>[];

    if (props['name'] != null) parts.add(props['name']);
    if (props['street'] != null) parts.add(props['street']);
    if (props['housenumber'] != null) parts.add(props['housenumber']);
    if (props['city'] != null) parts.add(props['city']);
    if (props['state'] != null) parts.add(props['state']);
    if (props['country'] != null) parts.add(props['country']);

    return parts.join(', ');
  }

  // Get appropriate icon for location type
  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'restaurant':
      case 'cafe':
      case 'fast_food':
        return Icons.restaurant;
      case 'hotel':
      case 'motel':
        return Icons.hotel;
      case 'hospital':
      case 'clinic':
      case 'pharmacy':
        return Icons.local_hospital;
      case 'school':
      case 'university':
      case 'college':
        return Icons.school;
      case 'bank':
      case 'atm':
        return Icons.account_balance;
      case 'fuel':
      case 'gas_station':
        return Icons.local_gas_station;
      case 'parking':
        return Icons.local_parking;
      case 'bus_station':
      case 'train_station':
        return Icons.directions_bus;
      case 'airport':
        return Icons.flight;
      case 'park':
        return Icons.park;
      case 'museum':
        return Icons.museum;
      case 'shopping':
      case 'mall':
      case 'supermarket':
        return Icons.shopping_cart;
      default:
        return Icons.location_on;
    }
  }

  // Reverse geocoding for map taps
  Future<String> _reverseGeocode(LatLng point) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?'
              'lat=${point.latitude}'
              '&lon=${point.longitude}'
              '&format=json'
              '&addressdetails=1'
      );

      final res = await http.get(
        url,
        headers: {'User-Agent': 'FlutterMapRoutingApp/1.0'},
      ).timeout(Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['display_name'] ??
            '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
      }
    } catch (e) {
      print('Reverse geocoding error: $e');
    }
    return '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
  }

  void setPoint(Map<String, dynamic> place, bool isStart) {
    final lat = double.tryParse(place['lat'].toString()) ?? 0.0;
    final lon = double.tryParse(place['lon'].toString()) ?? 0.0;

    if (lat == 0.0 || lon == 0.0) return;

    setState(() {
      if (isStart) {
        startPoint = LatLng(lat, lon);
        _startController.text = place['display_name'] ?? '';
      } else {
        endPoint = LatLng(lat, lon);
        _endController.text = place['display_name'] ?? '';
      }
    });

    // Move map to the selected location
    mapController.move(LatLng(lat, lon), 14);
  }

  void onMapTap(TapPosition tapPosition, LatLng point) async {
    setState(() {
      if (startPoint == null) {
        startPoint = point;
        _startController.text = 'Loading address...';
      } else if (endPoint == null) {
        endPoint = point;
        _endController.text = 'Loading address...';
      } else {
        startPoint = point;
        endPoint = null;
        routePoints = [];
        distance = 0;
        duration = '';
        _startController.text = 'Loading address...';
        _endController.clear();
      }
    });

    // Reverse geocode to get address
    final address = await _reverseGeocode(point);
    setState(() {
      if (startPoint == point) {
        _startController.text = address;
      } else if (endPoint == point) {
        _endController.text = address;
      }
    });
  }

  Future<void> calculateRoute() async {
    if (startPoint == null || endPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both start and end points')),
      );
      return;
    }

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 16),
            Text('Calculating route...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final url = Uri.parse(
          "https://router.project-osrm.org/route/v1/driving/"
              "${startPoint!.longitude},${startPoint!.latitude};"
              "${endPoint!.longitude},${endPoint!.latitude}"
              "?overview=full&geometries=geojson&steps=true&annotations=true"
      );

      final res = await http.get(url).timeout(Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coords = route['geometry']['coordinates'] as List;
          final dur = route['duration'];
          final dist = route['distance'];

          setState(() {
            routePoints = coords.map((c) => LatLng(c[1], c[0])).toList();
            distance = dist / 1000;
            duration = _formatDuration(dur);
          });

          // Fit map to route bounds
          _fitMapToRoute();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Route calculated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to calculate route: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

  void _fitMapToRoute() {
    if (routePoints.isEmpty) return;

    double minLat = routePoints[0].latitude;
    double maxLat = routePoints[0].latitude;
    double minLng = routePoints[0].longitude;
    double maxLng = routePoints[0].longitude;

    for (final point in routePoints) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: EdgeInsets.all(50),
      ),
    );
  }

  void openSaveScreen() {
    if (startPoint == null || endPoint == null || routePoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please calculate a route first')),
      );
      return;
    }

    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => SaveRouteScreen(
    //       start: startPoint!,
    //       end: endPoint!,
    //       distance: distance,
    //       duration: duration,
    //     ),
    //   ),
    // );
  }

  void clearRoute() {
    setState(() {
      startPoint = null;
      endPoint = null;
      routePoints = [];
      distance = 0;
      duration = '';
      _startController.clear();
      _endController.clear();
    });
  }

  void _showSearchProviderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search Provider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('Nominatim (OSM)'),
              subtitle: Text('Most comprehensive'),
              value: 'nominatim',
              groupValue: _searchProvider,
              onChanged: (value) {
                setState(() => _searchProvider = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('Photon (Komoot)'),
              subtitle: Text('Fastest response'),
              value: 'photon',
              groupValue: _searchProvider,
              onChanged: (value) {
                setState(() => _searchProvider = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('Hybrid'),
              subtitle: Text('Best results (slower)'),
              value: 'hybrid',
              groupValue: _searchProvider,
              onChanged: (value) {
                setState(() => _searchProvider = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Advanced Route Planner'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _showSearchProviderDialog,
            tooltip: 'Search settings',
          ),
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: clearRoute,
            tooltip: 'Clear route',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: LatLng(32.5, 74.5),
              initialZoom: 7,
              onTap: onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.map_routing',
              ),
              if (startPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: startPoint!,
                      width: 40,
                      height: 40,
                      child: Icon(Icons.location_on, color: Colors.green, size: 40),
                    )
                  ],
                ),
              if (endPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: endPoint!,
                      width: 40,
                      height: 40,
                      child: Icon(Icons.location_on, color: Colors.red, size: 40),
                    )
                  ],
                ),
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: Colors.blue,
                      strokeWidth: 4,
                    )
                  ],
                ),
            ],
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    // Start Point Search
                    TypeAheadField<Map<String, dynamic>>(
                      controller: _startController,
                      focusNode: _startFocus,
                      debounceDuration: Duration(milliseconds: 400),
                      suggestionsCallback: (pattern) async => await searchPlaces(pattern),
                      itemBuilder: (context, suggestion) {
                        return ListTile(
                          leading: Icon(
                            suggestion['icon'] as IconData,
                            color: Colors.green,
                          ),
                          title: Text(
                            suggestion['display_name'] ?? 'Unknown location',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            suggestion['type'] ?? '',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          trailing: suggestion['source'] != null
                              ? Chip(
                            label: Text(
                              suggestion['source'],
                              style: TextStyle(fontSize: 10),
                            ),
                            backgroundColor: Colors.blue.shade100,
                            padding: EdgeInsets.all(2),
                          )
                              : null,
                        );
                      },
                      onSelected: (suggestion) {
                        setPoint(suggestion, true);
                      },
                      builder: (context, controller, focusNode) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            labelText: 'Start Point',
                            hintText: 'Search location, address, or place',
                            prefixIcon: _isSearching && focusNode.hasFocus
                                ? Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                                : Icon(Icons.search),
                            suffixIcon: _startController.text.isNotEmpty
                                ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                controller.clear();
                                setState(() {
                                  startPoint = null;
                                });
                              },
                            )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue, width: 2),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 12),
                    // End Point Search
                    TypeAheadField<Map<String, dynamic>>(
                      controller: _endController,
                      focusNode: _endFocus,
                      debounceDuration: Duration(milliseconds: 400),
                      suggestionsCallback: (pattern) async => await searchPlaces(pattern),
                      itemBuilder: (context, suggestion) {
                        return ListTile(
                          leading: Icon(
                            suggestion['icon'] as IconData,
                            color: Colors.red,
                          ),
                          title: Text(
                            suggestion['display_name'] ?? 'Unknown location',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            suggestion['type'] ?? '',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          trailing: suggestion['source'] != null
                              ? Chip(
                            label: Text(
                              suggestion['source'],
                              style: TextStyle(fontSize: 10),
                            ),
                            backgroundColor: Colors.red.shade100,
                            padding: EdgeInsets.all(2),
                          )
                              : null,
                        );
                      },
                      onSelected: (suggestion) {
                        setPoint(suggestion, false);
                      },
                      builder: (context, controller, focusNode) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            labelText: 'End Point',
                            hintText: 'Search destination',
                            prefixIcon: _isSearching && focusNode.hasFocus
                                ? Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                                : Icon(Icons.search),
                            suffixIcon: _endController.text.isNotEmpty
                                ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                controller.clear();
                                setState(() {
                                  endPoint = null;
                                });
                              },
                            )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.red, width: 2),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: calculateRoute,
                    icon: Icon(Icons.route),
                    label: Text('Calculate'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: openSaveScreen,
                    icon: Icon(Icons.save),
                    label: Text('Save'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (routePoints.isNotEmpty)
            Positioned(
              bottom: 90,
              left: 20,
              right: 20,
              child: Card(
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            "Route Information",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Icon(Icons.straighten, color: Colors.blue),
                              SizedBox(height: 4),
                              Text(
                                "${distance.toStringAsFixed(2)} km",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Distance",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey.shade300,
                          ),
                          Column(
                            children: [
                              Icon(Icons.access_time, color: Colors.orange),
                              SizedBox(height: 4),
                              Text(
                                duration,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Duration",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Cache helper class
class _CachedResult {
  final List<Map<String, dynamic>> results;
  final DateTime timestamp;

  _CachedResult({
    required this.results,
    required this.timestamp,
  });
}