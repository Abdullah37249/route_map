import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:routing_0sm/screens/real_time_navigation_screen.dart';
import 'package:routing_0sm/screens/route_tracking_screen.dart';
import '../Database/db_service.dart';


/// RouteSelectionScreen that displays routes fetched from a remote GET API.
/// Only routes returned by the API are shown. This version groups rows by
/// route_id so a route appears exactly once and contains all its combined segments.
class RouteSelectionScreen extends StatelessWidget {
  final bool isForNavigation; // true for navigation, false for tracking

  const RouteSelectionScreen({
    Key? key,
    required this.isForNavigation,
  }) : super(key: key);

  /// Fetch routes from the provided API.
  /// Uses several fallback parsing strategies to return a List<Map<String, dynamic>>.
  static Future<List<Map<String, dynamic>>> _fetchRoutesFromApi() async {
    const String url =
        "https://cloud.metaxperts.net:8443/erp/valor_trading/maproutesget/get/";

    final uri = Uri.parse(url);
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('API request failed with status: ${response.statusCode}');
    }

    dynamic jsonBody;
    try {
      jsonBody = json.decode(response.body);
    } catch (e) {
      throw Exception('Failed to decode API response: $e');
    }

    // If API returns a JSON array directly
    if (jsonBody is List) {
      return jsonBody
          .map<Map<String, dynamic>>(
              (e) => (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{})
          .toList();
    }

    // If API returns an object, attempt to find the array inside common keys
    if (jsonBody is Map) {
      // Common keys to check for the array payload
      const possibleKeys = ['data', 'routes', 'result', 'items', 'rows'];

      for (final key in possibleKeys) {
        if (jsonBody.containsKey(key) && jsonBody[key] is List) {
          return (jsonBody[key] as List)
              .map<Map<String, dynamic>>((e) =>
          (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{})
              .toList();
        }
      }

      // If none of the common keys match, try to find any List value inside the map
      for (final entry in jsonBody.entries) {
        if (entry.value is List) {
          final list = entry.value as List;
          if (list.isNotEmpty && list.first is Map) {
            return list
                .map<Map<String, dynamic>>((e) =>
            (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{})
                .toList();
          }
        }
      }
    }

    // Fallback: can't find a route list
    throw Exception('API returned unexpected JSON structure.');
  }

  /// Extracts coordinate points from a single API row.
  /// Supports various shapes: lat/lng fields, nested 'point', 'coordinates', or 'segments' list.
  static List<Map<String, double>> _extractPointsFromRow(Map<String, dynamic> row) {
    final List<Map<String, double>> pts = [];

    double? tryToDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v);
      if (v is num) return v.toDouble();
      return null;
    }

    // Single lat/lng fields
    final latKeys = ['lat', 'latitude'];
    final lngKeys = ['lng', 'longitude', 'long'];

    double? lat;
    double? lng;

    for (final k in latKeys) {
      if (row.containsKey(k)) {
        lat = tryToDouble(row[k]);
        break;
      }
    }
    for (final k in lngKeys) {
      if (row.containsKey(k)) {
        lng = tryToDouble(row[k]);
        break;
      }
    }
    if (lat != null && lng != null) {
      pts.add({'lat': lat, 'lng': lng});
    }

    // 'point' object with lat/lng
    if (row.containsKey('point') && row['point'] is Map) {
      final p = Map<String, dynamic>.from(row['point']);
      final plat = tryToDouble(p['lat'] ?? p['latitude']);
      final plng = tryToDouble(p['lng'] ?? p['longitude']);
      if (plat != null && plng != null) pts.add({'lat': plat, 'lng': plng});
    }

    // 'coordinates' array [lng, lat] or [lat, lng]
    if (row.containsKey('coordinates') && row['coordinates'] is List) {
      final coords = row['coordinates'] as List;
      if (coords.length >= 2) {
        // Try detect order: if values are within lat/lng ranges
        final c0 = tryToDouble(coords[0]);
        final c1 = tryToDouble(coords[1]);
        if (c0 != null && c1 != null) {
          // Heuristic: lat is between -90..90
          if (c0.abs() <= 90 && c1.abs() <= 180) {
            // assume [lat, lng]
            pts.add({'lat': c0, 'lng': c1});
          } else if (c1.abs() <= 90 && c0.abs() <= 180) {
            // assume [lng, lat]
            pts.add({'lat': c1, 'lng': c0});
          } else {
            // push both as best-effort
            pts.add({'lat': c0, 'lng': c1});
          }
        }
      }
    }

    // 'segments' field as list of point objects
    if (row.containsKey('segments') && row['segments'] is List) {
      for (final s in (row['segments'] as List)) {
        if (s is Map) {
          final plat = tryToDouble(s['lat'] ?? s['latitude']);
          final plng = tryToDouble(s['lng'] ?? s['longitude']);
          if (plat != null && plng != null) pts.add({'lat': plat, 'lng': plng});
        }
      }
    }

    // 'points' field as list of arrays/maps
    if (row.containsKey('points') && row['points'] is List) {
      for (final s in (row['points'] as List)) {
        if (s is Map) {
          final plat = tryToDouble(s['lat'] ?? s['latitude']);
          final plng = tryToDouble(s['lng'] ?? s['longitude']);
          if (plat != null && plng != null) pts.add({'lat': plat, 'lng': plng});
        } else if (s is List && s.length >= 2) {
          final a0 = tryToDouble(s[0]);
          final a1 = tryToDouble(s[1]);
          if (a0 != null && a1 != null) pts.add({'lat': a0, 'lng': a1});
        }
      }
    }

    // Deduplicate simple duplicate points while preserving order
    final out = <Map<String, double>>[];
    for (final p in pts) {
      if (out.isEmpty ||
          out.last['lat'] != p['lat'] ||
          out.last['lng'] != p['lng']) {
        out.add(p);
      }
    }

    return out;
  }

  /// Group API rows by route id, and combine segments/points into a single list on each grouped route.
  /// Returns a list of grouped route maps (one map per route), each containing original merged metadata and
  /// a 'combined_segments' List<Map<String,double>> of points.
  static List<Map<String, dynamic>> _groupRowsIntoRoutes(List<Map<String, dynamic>> rows) {
    final Map<int, Map<String, dynamic>> groups = {};
    final Map<int, List<Map<String, double>>> groupsPoints = {};

    for (final row in rows) {
      final rawRouteId = row['route_id'] ?? row['id'] ?? row['routeId'];
      if (rawRouteId == null) continue;

      final int routeId = int.tryParse(rawRouteId.toString()) ?? -1;
      if (routeId < 0) continue;

      // If first time, copy row as base metadata
      if (!groups.containsKey(routeId)) {
        groups[routeId] = Map<String, dynamic>.from(row);
        groupsPoints[routeId] = [];
      } else {
        // Merge metadata conservatively: keep existing fields, but if missing fill from current row
        final existing = groups[routeId]!;
        row.forEach((k, v) {
          if ((existing[k] == null || existing[k].toString().isEmpty) && v != null) {
            existing[k] = v;
          }
        });
      }

      // Extract potential points from current row and append
      final pts = _extractPointsFromRow(row);
      if (pts.isNotEmpty) {
        groupsPoints[routeId]!.addAll(pts);
      }
    }

    // Consolidate into single list with 'combined_segments'
    final List<Map<String, dynamic>> result = [];
    for (final entry in groups.entries) {
      final int id = entry.key;
      final Map<String, dynamic> meta = Map<String, dynamic>.from(entry.value);
      // Remove duplicates while preserving order
      final seen = <String>{};
      final combined = <Map<String, double>>[];
      for (final p in groupsPoints[id] ?? []) {
        final key = '${p['lat']}:${p['lng']}';
        if (!seen.contains(key)) {
          combined.add(p);
          seen.add(key);
        }
      }
      meta['combined_segments'] = combined;
      result.add(meta);
    }

    // Sort result by route id ascending (stable UI)
    result.sort((a, b) {
      final aId = int.tryParse((a['route_id'] ?? a['id'] ?? a['routeId']).toString()) ?? 0;
      final bId = int.tryParse((b['route_id'] ?? b['id'] ?? b['routeId']).toString()) ?? 0;
      return aId.compareTo(bId);
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isForNavigation ? 'Select Route for Navigation' : 'Select Route to Track',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isForNavigation
                  ? [Colors.purple.shade700, Colors.purple.shade500]
                  : [Colors.orange.shade700, Colors.orange.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // Fetch routes from the remote API
        future: _fetchRoutesFromApi(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: isForNavigation ? Colors.purple : Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading routes...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading routes',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          final rawRoutes = snapshot.data ?? [];
          // GROUP rows into single route entries (one card per route)
          final groupedRoutes = _groupRowsIntoRoutes(rawRoutes);

          if (groupedRoutes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.route, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No saved routes found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create a route first using "Create Multi-Point Route"',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          // Build one card per grouped route (clean & minimal)
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedRoutes.length,
            itemBuilder: (context, index) {
              final route = groupedRoutes[index];

              // Parse route id safely
              final dynamic rawRouteId = route['route_id'] ?? route['id'] ?? route['routeId'];
              int? routeId;
              if (rawRouteId is int) {
                routeId = rawRouteId;
              } else if (rawRouteId != null) {
                routeId = int.tryParse(rawRouteId.toString());
              }

              final startName = route['start_name']?.toString() ??
                  route['startName']?.toString() ??
                  route['start']?.toString() ??
                  'Unknown';
              final endName = route['end_name']?.toString() ??
                  route['endName']?.toString() ??
                  route['end']?.toString() ??
                  'Unknown';
              final distance = route['total_distance']?.toString() ?? '0';
              final duration = route['total_duration']?.toString() ?? '0 min';

              final List<Map<String, double>> combinedSegments =
              (route['combined_segments'] is List)
                  ? (route['combined_segments'] as List)
                  .whereType<Map>()
                  .map((m) {
                // Map may contain dynamic values — ensure double
                final lat = double.tryParse(m['lat']?.toString() ?? '') ??
                    (m['latitude'] is num ? (m['latitude'] as num).toDouble() : double.tryParse(m['latitude']?.toString() ?? '') ?? 0.0);
                final lng = double.tryParse(m['lng']?.toString() ?? '') ??
                    (m['longitude'] is num ? (m['longitude'] as num).toDouble() : double.tryParse(m['longitude']?.toString() ?? '') ?? 0.0);
                return {'lat': lat, 'lng': lng};
              }).toList()
                  : <Map<String, double>>[];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (routeId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Route id not available for this route.')),
                        );
                        return;
                      }

                      final int resolvedRouteId = routeId;

                      // Maintain same navigation logic — open navigation or tracking screen.
                      if (isForNavigation) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RealTimeNavigationScreen(
                              routeId: resolvedRouteId,
                              routeName: 'Route $resolvedRouteId Navigation',
                            ),
                          ),
                        );
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RouteTrackingScreen(
                              routeId: resolvedRouteId,
                              routeName: 'Route $resolvedRouteId',
                            ),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Number indicator
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isForNavigation
                                    ? [Colors.purple.shade400, Colors.purple.shade600]
                                    : [Colors.orange.shade400, Colors.orange.shade600],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Route details + combined segments inside single card
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Route ${routeId ?? (index + 1)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$startName → $endName',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                ),
                                const SizedBox(height: 8),

                                // Badges (distance / duration)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.straighten, size: 14, color: Colors.blue.shade700),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$distance km',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.access_time, size: 14, color: Colors.orange.shade700),
                                          const SizedBox(width: 4),
                                          Text(
                                            duration,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.orange.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Combined segments/points list (single combined view)
                                if (combinedSegments.isNotEmpty)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Points (${combinedSegments.length})',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(maxHeight: 160),
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: combinedSegments.length,
                                            itemBuilder: (ctx, i) {
                                              final p = combinedSegments[i];
                                              final lat = p['lat']?.toStringAsFixed(6) ?? '0';
                                              final lng = p['lng']?.toStringAsFixed(6) ?? '0';
                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4),
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 12,
                                                      child: Text('${i + 1}', style: const TextStyle(fontSize: 12)),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        'Lat: $lat, Lng: $lng',
                                                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Text(
                                    'No points available',
                                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                          ),

                          // Arrow icon
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 20,
                            color: isForNavigation ? Colors.purple.shade400 : Colors.orange.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
