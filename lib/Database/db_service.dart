// Copy the entire content from the original DBHelper.dart file here
// It remains exactly the same
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

class DBHelper {
  static Database? _db;
  static const int _currentVersion = 3; // Incremented version for route_name column

  // Initialize local database
  static Future<Database> getDatabase() async {
    if (_db != null) return _db!;

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'routes.db');

    _db = await openDatabase(
      path,
      version: _currentVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: _onDowngrade,
    );
    return _db!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE map_routes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        route_id INTEGER,
        sr_no INTEGER,
        route_name TEXT DEFAULT 'Unnamed Route',
        start_name TEXT,
        start_lat REAL,
        start_lng REAL,
        end_name TEXT,
        end_lat REAL,
        end_lng REAL,
        segment_distance REAL,
        segment_duration TEXT,
        total_distance REAL,
        total_duration TEXT,
        waypoints TEXT,
        province TEXT DEFAULT 'Punjab',
        city TEXT DEFAULT 'Sialkot',
        date TEXT,
        created_at TEXT
      )
    ''');

    // Create index for better performance
    await db.execute('CREATE INDEX idx_route_id ON map_routes(route_id)');
  }

  static Future<void> _onUpgrade(
      Database db,
      int oldVersion,
      int newVersion,
      ) async {
    print('Upgrading database from version $oldVersion to $newVersion');

    if (oldVersion == 1) {
      // Backup old table
      await db.execute('ALTER TABLE map_routes RENAME TO map_routes_old');

      // Create new table with updated schema
      await _onCreate(db, newVersion);

      // Migrate data from old table
      final oldData = await db.query('map_routes_old');

      for (final row in oldData) {
        // For old simple routes, set route_id = id and sr_no = 1
        await db.insert('map_routes', {
          'route_id': row['id'],
          'sr_no': 1,
          'route_name': 'Route ${row['id']}',
          'start_name': 'Start Point',
          'start_lat': row['start_lat'],
          'start_lng': row['start_lng'],
          'end_name': 'End Point',
          'end_lat': row['end_lat'],
          'end_lng': row['end_lng'],
          'segment_distance': row['distance'],
          'segment_duration': row['duration'],
          'total_distance': row['distance'],
          'total_duration': row['duration'],
          'province': row['province'],
          'city': row['city'],
          'date': row['date'],
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Drop old table
      await db.execute('DROP TABLE map_routes_old');
    } else if (oldVersion == 2) {
      // Add route_name column to existing table
      try {
        await db.execute('ALTER TABLE map_routes ADD COLUMN route_name TEXT DEFAULT "Unnamed Route"');
        print('Added route_name column to map_routes table');

        // Update existing rows with default route names
        await db.rawUpdate('UPDATE map_routes SET route_name = ? WHERE route_name IS NULL',
            ['Route ' + '|| route_id']);
      } catch (e) {
        print('Error adding route_name column: $e');
      }
    }
  }

  static Future<void> _onDowngrade(
      Database db,
      int oldVersion,
      int newVersion,
      ) async {
    await db.execute('DROP TABLE IF EXISTS map_routes');
    await _onCreate(db, newVersion);
  }

  // Reset database (for testing/debugging)
  static Future<void> resetDatabase() async {
    final db = await getDatabase();
    await db.execute('DROP TABLE IF EXISTS map_routes');
    await _onCreate(db, _currentVersion);
  }

  // Extract shorter location name from full address
  static String _getShortLocation(String fullAddress) {
    // Try to extract meaningful shorter name
    final parts = fullAddress.split(',');

    if (parts.length >= 2) {
      // Return first two parts (usually street/area, city)
      return '${parts[0].trim()}, ${parts[1].trim()}';
    } else if (parts.length == 1) {
      // If it's just one part, truncate to 50 chars
      return fullAddress.length > 50
          ? '${fullAddress.substring(0, 47)}...'
          : fullAddress;
    }

    // Default fallback
    return fullAddress.length > 50
        ? '${fullAddress.substring(0, 47)}...'
        : fullAddress;
  }

  // Truncate text to fit server column limits (max 100 chars)
  static String _truncateForServer(String text, {int maxLength = 100}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  // Insert a simple route (A to B)
  static Future<int> insertSimpleRoute({
    required String startName,
    required double startLat,
    required double startLng,
    required String endName,
    required double endLat,
    required double endLng,
    required double distance,
    required String duration,
    String province = 'Punjab',
    String city = 'Sialkot',
    required String date,
    String routeName = 'Unnamed Route',
  }) async {
    final db = await getDatabase();

    try {
      return await db
          .insert('map_routes', {
        'route_id': 0, // Will be updated after insert
        'sr_no': 1,
        'route_name': routeName,
        'start_name': startName,
        'start_lat': startLat,
        'start_lng': startLng,
        'end_name': endName,
        'end_lat': endLat,
        'end_lng': endLng,
        'segment_distance': distance,
        'segment_duration': duration,
        'total_distance': distance,
        'total_duration': duration,
        'province': province,
        'city': city,
        'date': date,
        'created_at': DateTime.now().toIso8601String(),
      })
          .then((id) async {
        // Update route_id to match the id
        await db.update(
          'map_routes',
          {'route_id': id},
          where: 'id = ?',
          whereArgs: [id],
        );
        return id;
      });
    } catch (e) {
      print('Error inserting simple route: $e');
      if (e.toString().contains('no column named')) {
        await resetDatabase();
        return await insertSimpleRoute(
          startName: startName,
          startLat: startLat,
          startLng: startLng,
          endName: endName,
          endLat: endLat,
          endLng: endLng,
          distance: distance,
          duration: duration,
          province: province,
          city: city,
          date: date,
          routeName: routeName,
        );
      }
      rethrow;
    }
  }

  // Insert a multi-point route with segments
  static Future<int> insertMultiPointRoute({
    required List<Map<String, dynamic>> waypoints,
    required List<double> segmentDistances,
    required List<String> segmentDurations,
    required double totalDistance,
    required String totalDuration,
    String province = 'Punjab',
    String city = 'Sialkot',
    required String date,
    String routeName = 'Unnamed Route',
  }) async {
    final db = await getDatabase();

    try {
      // First insert to get the route_id
      final firstSegmentId = await db.insert('map_routes', {
        'route_id': 0, // Temporary
        'sr_no': 1,
        'route_name': routeName,
        'start_name': waypoints[0]['name'] ?? 'Start Point',
        'start_lat': waypoints[0]['lat'] ?? 0.0,
        'start_lng': waypoints[0]['lng'] ?? 0.0,
        'end_name': waypoints[1]['name'] ?? 'Point 2',
        'end_lat': waypoints[1]['lat'] ?? 0.0,
        'end_lng': waypoints[1]['lng'] ?? 0.0,
        'segment_distance': segmentDistances[0],
        'segment_duration': segmentDurations[0],
        'total_distance': totalDistance,
        'total_duration': totalDuration,
        'waypoints': jsonEncode(waypoints),
        'province': province,
        'city': city,
        'date': date,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update route_id to match the first segment's id
      final routeId = firstSegmentId;
      await db.update(
        'map_routes',
        {'route_id': routeId},
        where: 'id = ?',
        whereArgs: [firstSegmentId],
      );

      // Insert remaining segments
      for (int i = 1; i < waypoints.length - 1; i++) {
        await db.insert('map_routes', {
          'route_id': routeId,
          'sr_no': i + 1,
          'route_name': routeName,
          'start_name': waypoints[i]['name'] ?? 'Point ${i + 1}',
          'start_lat': waypoints[i]['lat'] ?? 0.0,
          'start_lng': waypoints[i]['lng'] ?? 0.0,
          'end_name': waypoints[i + 1]['name'] ?? 'Point ${i + 2}',
          'end_lat': waypoints[i + 1]['lat'] ?? 0.0,
          'end_lng': waypoints[i + 1]['lng'] ?? 0.0,
          'segment_distance': segmentDistances[i],
          'segment_duration': segmentDurations[i],
          'total_distance': totalDistance,
          'total_duration': totalDuration,
          'waypoints': jsonEncode(waypoints),
          'province': province,
          'city': city,
          'date': date,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return routeId;
    } catch (e) {
      print('Error inserting multi-point route: $e');
      if (e.toString().contains('no column named')) {
        await resetDatabase();
        return await insertMultiPointRoute(
          waypoints: waypoints,
          segmentDistances: segmentDistances,
          segmentDurations: segmentDurations,
          totalDistance: totalDistance,
          totalDuration: totalDuration,
          province: province,
          city: city,
          date: date,
          routeName: routeName,
        );
      }
      rethrow;
    }
  }

  // Alias for backward compatibility
  static Future<int> insertRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required double distance,
    required String duration,
    String province = 'Punjab',
    String city = 'Sialkot',
    required String date,
    String routeName = 'Unnamed Route',
  }) async {
    return await insertSimpleRoute(
      startName: 'Start Point',
      startLat: startLat,
      startLng: startLng,
      endName: 'End Point',
      endLat: endLat,
      endLng: endLng,
      distance: distance,
      duration: duration,
      province: province,
      city: city,
      date: date,
      routeName: routeName,
    );
  }

  // Fetch all routes (grouped by route_id)
  static Future<List<Map<String, dynamic>>> getRoutes() async {
    final db = await getDatabase();
    try {
      final routes = await db.query(
        'map_routes',
        orderBy: 'route_id DESC, sr_no ASC',
      );

      final Map<int, List<Map<String, dynamic>>> grouped = {};
      for (final route in routes) {
        final routeId = route['route_id'] as int;
        grouped.putIfAbsent(routeId, () => []);
        grouped[routeId]!.add(route);
      }

      final result = <Map<String, dynamic>>[];
      grouped.forEach((routeId, segments) {
        if (segments.isNotEmpty) {
          final firstSegment = segments.first;
          result.add({
            'route_id': routeId,
            'segments_count': segments.length,
            'route_name': firstSegment['route_name'] ?? 'Unnamed Route',
            'start_name': firstSegment['start_name'],
            'end_name': segments.last['end_name'],
            'total_distance': firstSegment['total_distance'],
            'total_duration': firstSegment['total_duration'],
            'province': firstSegment['province'],
            'city': firstSegment['city'],
            'date': firstSegment['date'],
            'segments': segments,
          });
        }
      });

      return result;
    } catch (e) {
      print('Error getting routes: $e');
      if (e.toString().contains('no column named')) {
        await resetDatabase();
        return [];
      }
      rethrow;
    }
  }

  // Get all segments for a specific route
  static Future<List<Map<String, dynamic>>> getRouteSegments(
      int routeId,
      ) async {
    final db = await getDatabase();
    try {
      return await db.query(
        'map_routes',
        where: 'route_id = ?',
        whereArgs: [routeId],
        orderBy: 'sr_no ASC',
      );
    } catch (e) {
      print('Error getting route segments: $e');
      return [];
    }
  }

  // Get all segments by route ID (alias for getRouteSegments)
  static Future<List<Map<String, dynamic>>> getSegmentsByRouteId(int routeId) async {
    return await getRouteSegments(routeId);
  }

  // Prepare data for server with shorter names
  static Map<String, dynamic> _prepareServerData(Map<String, dynamic> segment) {
    final startName = segment['start_name']?.toString() ?? 'Unknown Start';
    final endName = segment['end_name']?.toString() ?? 'Unknown End';
    final routeName = segment['route_name']?.toString() ?? 'Unnamed Route';

    // Get shorter names for server
    final shortStartName = _getShortLocation(startName);
    final shortEndName = _getShortLocation(endName);
    final shortRouteName = _truncateForServer(routeName);

    // Truncate to server column limits
    final truncatedStartName = _truncateForServer(shortStartName);
    final truncatedEndName = _truncateForServer(shortEndName);

    return {
      'route_id': segment['route_id'] ?? 0,
      'sr_no': segment['sr_no'] ?? 1,
      'route_name': shortRouteName,
      'start_name': truncatedStartName,
      'start_lat': segment['start_lat'] ?? 0.0,
      'start_lng': segment['start_lng'] ?? 0.0,
      'end_name': truncatedEndName,
      'end_lat': segment['end_lat'] ?? 0.0,
      'end_lng': segment['end_lng'] ?? 0.0,
      'segment_distance': segment['segment_distance'] ?? 0.0,
      'segment_duration': segment['segment_duration']?.toString() ?? '0 min',
      'total_distance': segment['total_distance'] ?? 0.0,
      'total_duration': segment['total_duration']?.toString() ?? '0 min',
      'province': segment['province']?.toString() ?? 'Punjab',
      'city': segment['city']?.toString() ?? 'Sialkot',
      'date':
      segment['date']?.toString() ??
          DateTime.now().toIso8601String().split('T')[0],
      'created_at':
      segment['created_at']?.toString() ?? DateTime.now().toIso8601String(),
    };
  }

  // Save route to server
  static Future<bool> saveRouteToServer(Map<String, dynamic> data) async {
    try {
      // Prepare data with shorter names
      final serverData = _prepareServerData(data);

      print('Sending to server (short names):');
      print('Route Name: ${serverData['route_name']}');
      print('Start: ${serverData['start_name']}');
      print('End: ${serverData['end_name']}');

      final res = await http
          .post(
        Uri.parse(
          'https://cloud.metaxperts.net:8443/erp/valor_trading/maproutespost/post/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(serverData),
      )
          .timeout(Duration(seconds: 10));

      print('Server response status: ${res.statusCode}');

      // Check if response is empty or has content
      if (res.body.trim().isEmpty) {
        print('Server returned empty response - assuming success');
        return true;
      }

      // Try to parse the response if it exists
      try {
        final responseJson = jsonDecode(res.body);
        print('Server response: $responseJson');

        if (res.statusCode == 200 || res.statusCode == 201) {
          print(
            'Route saved to server successfully: ${data['route_id']}-${data['sr_no']}',
          );
          return true;
        } else {
          print('Server error: $responseJson');
          return false;
        }
      } catch (e) {
        print('Could not parse server response: $e');
        // If we can't parse but status is 200, assume success
        return res.statusCode == 200;
      }
    } catch (e) {
      print('Error saving to server: $e');
      return false;
    }
  }

  // Save all segments of a route to server
  static Future<Map<String, dynamic>> saveRouteSegmentsToServer(
      int routeId,
      ) async {
    try {
      final segments = await getRouteSegments(routeId);

      if (segments.isEmpty) {
        return {
          'success': false,
          'message': 'No segments found for route $routeId',
          'total_segments': 0,
          'sent_segments': 0,
          'failed_segments': 0,
        };
      }

      int sentCount = 0;
      int failedCount = 0;
      List<String> failedSegmentNumbers = [];

      for (final segment in segments) {
        final success = await saveRouteToServer(segment);

        if (success) {
          sentCount++;
        } else {
          failedCount++;
          failedSegmentNumbers.add('Segment ${segment['sr_no']}');
        }

        // Small delay between requests to avoid overwhelming server
        await Future.delayed(Duration(milliseconds: 500));
      }

      return {
        'success': sentCount > 0,
        'message': failedCount == 0
            ? 'All $sentCount segments saved successfully!'
            : 'Saved $sentCount segments, ${failedCount} failed: ${failedSegmentNumbers.join(", ")}',
        'total_segments': segments.length,
        'sent_segments': sentCount,
        'failed_segments': failedCount,
        'failed_segment_numbers': failedSegmentNumbers,
      };
    } catch (e) {
      print('Error saving route segments to server: $e');
      return {
        'success': false,
        'message': 'Error: $e',
        'total_segments': 0,
        'sent_segments': 0,
        'failed_segments': 0,
      };
    }
  }

  // Check database schema
  static Future<void> checkSchema() async {
    final db = await getDatabase();
    final tableInfo = await db.rawQuery('PRAGMA table_info(map_routes)');
    print('Database schema:');
    for (final column in tableInfo) {
      print('Column: ${column['name']}, Type: ${column['type']}');
    }
  }

  // NEW FUNCTIONALITY: Check if a route exists on server
  static Future<bool> doesRouteExistOnServer(int routeId) async {
    try {
      final allServerRoutes = await fetchRoutesFromServer();

      // Check if any route on server has this route_id
      final exists = allServerRoutes.any((route) =>
      route['route_id'] == routeId);

      print('Route $routeId exists on server: $exists');
      return exists;
    } catch (e) {
      print('Error checking route existence on server: $e');
      return false; // Assume not exists if error
    }
  }

  // NEW FUNCTIONALITY: Get locally saved routes that don't exist on server
  static Future<List<Map<String, dynamic>>> getOrphanedRoutes() async {
    try {
      final localRoutes = await getRoutes();
      final serverRoutes = await fetchRoutesFromServer();

      final serverRouteIds = serverRoutes.map((r) => r['route_id'] as int).toSet();

      final orphaned = localRoutes.where((localRoute) {
        final routeId = localRoute['route_id'] as int;
        return !serverRouteIds.contains(routeId);
      }).toList();

      print('Found ${orphaned.length} orphaned routes (not on server)');
      return orphaned;
    } catch (e) {
      print('Error getting orphaned routes: $e');
      return [];
    }
  }

  // NEW FUNCTIONALITY: Update a specific segment
  static Future<bool> updateSegment({
    required int id,
    String? startName,
    double? startLat,
    double? startLng,
    String? endName,
    double? endLat,
    double? endLng,
    double? segmentDistance,
    String? segmentDuration,
    double? totalDistance,
    String? totalDuration,
    String? province,
    String? city,
    String? date,
    String? routeName,
  }) async {
    final db = await getDatabase();

    try {
      final updates = <String, dynamic>{};
      if (startName != null) updates['start_name'] = startName;
      if (startLat != null) updates['start_lat'] = startLat;
      if (startLng != null) updates['start_lng'] = startLng;
      if (endName != null) updates['end_name'] = endName;
      if (endLat != null) updates['end_lat'] = endLat;
      if (endLng != null) updates['end_lng'] = endLng;
      if (segmentDistance != null) updates['segment_distance'] = segmentDistance;
      if (segmentDuration != null) updates['segment_duration'] = segmentDuration;
      if (totalDistance != null) updates['total_distance'] = totalDistance;
      if (totalDuration != null) updates['total_duration'] = totalDuration;
      if (province != null) updates['province'] = province;
      if (city != null) updates['city'] = city;
      if (date != null) updates['date'] = date;
      if (routeName != null) updates['route_name'] = routeName;

      updates['created_at'] = DateTime.now().toIso8601String();

      final result = await db.update(
        'map_routes',
        updates,
        where: 'id = ?',
        whereArgs: [id],
      );

      return result > 0;
    } catch (e) {
      print('Error updating segment: $e');
      return false;
    }
  }

  // NEW FUNCTIONALITY: Delete a route locally
  static Future<bool> deleteLocalRoute(int routeId) async {
    final db = await getDatabase();

    try {
      final result = await db.delete(
        'map_routes',
        where: 'route_id = ?',
        whereArgs: [routeId],
      );

      print('Deleted $result segments for route $routeId');
      return result > 0;
    } catch (e) {
      print('Error deleting local route: $e');
      return false;
    }
  }

  // NEW FUNCTIONALITY: Get route by ID
  static Future<Map<String, dynamic>?> getRouteById(int routeId) async {
    try {
      final routes = await getRoutes();
      return routes.firstWhere(
            (route) => route['route_id'] == routeId,
        orElse: () => {},
      );
    } catch (e) {
      print('Error getting route by ID: $e');
      return null;
    }
  }

  // GET: Fetch routes from server
  static Future<List<Map<String, dynamic>>> fetchRoutesFromServer() async {
    try {
      print('Fetching routes from server...');

      final res = await http
          .get(
        Uri.parse(
          'https://cloud.metaxperts.net:8443/erp/valor_trading/maproutesget/get/',
        ),
        headers: {
          'Accept': 'application/json',
        },
      )
          .timeout(Duration(seconds: 15));

      print('GET Server response status: ${res.statusCode}');

      if (res.statusCode == 200) {
        final responseBody = res.body.trim();

        if (responseBody.isEmpty) {
          print('Server returned empty response');
          return [];
        }

        try {
          // Parse the response as a Map first
          final Map<String, dynamic> responseJson = jsonDecode(responseBody);
          print('Response keys: ${responseJson.keys.toList()}');

          // Check if we have an 'items' key
          if (responseJson.containsKey('items') && responseJson['items'] is List) {
            final List<dynamic> items = responseJson['items'];
            print('Fetched ${items.length} items from server');

            // Filter out items with null coordinates (invalid routes)
            final validItems = items.where((item) {
              if (item is Map<String, dynamic>) {
                final startLat = item['start_lat'];
                final startLng = item['start_lng'];
                return startLat != null && startLng != null;
              }
              return false;
            }).toList();

            print('Valid items: ${validItems.length}');

            // Convert to proper format
            final List<Map<String, dynamic>> routes = [];

            // Group by route_id
            final Map<int, List<Map<String, dynamic>>> grouped = {};

            for (final item in validItems) {
              if (item is Map<String, dynamic>) {
                // Extract route_id from the response
                final routeId = (item['route_id'] is String)
                    ? int.tryParse(item['route_id'].toString()) ?? 0
                    : (item['route_id'] as int? ?? 0);

                // Extract sr_no
                final srNo = (item['sr_no'] is String)
                    ? int.tryParse(item['sr_no'].toString()) ?? 1
                    : (item['sr_no'] as int? ?? 1);

                // Create cleaned segment data
                final segment = {
                  'id': 0, // Placeholder
                  'route_id': routeId,
                  'sr_no': srNo,
                  'route_name': item['route_name']?.toString() ?? 'Unnamed Route',
                  'start_name': item['start_name']?.toString() ?? 'Unknown Start',
                  'start_lat': (item['start_lat'] is String)
                      ? double.tryParse(item['start_lat'].toString()) ?? 0.0
                      : (item['start_lat'] as double? ?? 0.0),
                  'start_lng': (item['start_lng'] is String)
                      ? double.tryParse(item['start_lng'].toString()) ?? 0.0
                      : (item['start_lng'] as double? ?? 0.0),
                  'end_name': item['end_name']?.toString() ?? 'Unknown End',
                  'end_lat': (item['end_lat'] is String)
                      ? double.tryParse(item['end_lat'].toString()) ?? 0.0
                      : (item['end_lat'] as double? ?? 0.0),
                  'end_lng': (item['end_lng'] is String)
                      ? double.tryParse(item['end_lng'].toString()) ?? 0.0
                      : (item['end_lng'] as double? ?? 0.0),
                  'segment_distance': (item['segment_distance'] is String)
                      ? double.tryParse(item['segment_distance'].toString()) ?? 0.0
                      : (item['segment_distance'] as double? ?? 0.0),
                  'segment_duration': item['segment_duration']?.toString() ?? '0 min',
                  'total_distance': (item['total_distance'] is String)
                      ? double.tryParse(item['total_distance'].toString()) ?? 0.0
                      : (item['total_distance'] as double? ?? 0.0),
                  'total_duration': item['total_duration']?.toString() ?? '0 min',
                  'province': item['province']?.toString() ?? 'Unknown',
                  'city': item['city']?.toString() ?? 'Unknown',
                  'date': item['created_at']?.toString()?.split('T')[0] ?? DateTime.now().toIso8601String().split('T')[0],
                  'created_at': item['created_at']?.toString() ?? DateTime.now().toIso8601String(),
                };

                grouped.putIfAbsent(routeId, () => []);
                grouped[routeId]!.add(segment);
              }
            }

            // Create route structure
            grouped.forEach((routeId, segments) {
              if (segments.isNotEmpty) {
                // Sort segments by sr_no
                segments.sort((a, b) => (a['sr_no'] as int).compareTo(b['sr_no'] as int));

                // Calculate totals from first segment
                final firstSegment = segments.first;
                final lastSegment = segments.last;

                routes.add({
                  'route_id': routeId,
                  'segments_count': segments.length,
                  'route_name': firstSegment['route_name'],
                  'start_name': firstSegment['start_name'],
                  'end_name': lastSegment['end_name'],
                  'total_distance': firstSegment['total_distance'],
                  'total_duration': firstSegment['total_duration'],
                  'province': firstSegment['province'],
                  'city': firstSegment['city'],
                  'date': firstSegment['date'],
                  'segments': segments,
                  'is_from_server': true,
                });
              }
            });

            // Sort routes by route_id (descending)
            routes.sort((a, b) => (b['route_id'] as int).compareTo(a['route_id'] as int));

            print('Successfully processed ${routes.length} routes from server');
            return routes;
          } else {
            print('No "items" key found in response or items is not a list');
            print('Response structure: $responseJson');
            return [];
          }
        } catch (e) {
          print('Error parsing server response: $e');
          print('Response body: ${res.body}');
          return [];
        }
      } else {
        print('Failed to fetch routes: ${res.statusCode}');
        print('Response: ${res.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching from server: $e');
      return [];
    }
  }

  // NEW FUNCTIONALITY: Get route details with server check
  static Future<Map<String, dynamic>> getRouteDetailsWithServerCheck(int routeId) async {
    try {
      final localRoute = await getRouteById(routeId);
      final existsOnServer = await doesRouteExistOnServer(routeId);

      if (localRoute != null && localRoute.isNotEmpty) {
        return {
          ...localRoute,
          'exists_on_server': existsOnServer,
          'is_orphaned': !existsOnServer,
        };
      } else {
        return {
          'exists_on_server': existsOnServer,
          'is_orphaned': false,
          'message': 'Route not found locally',
        };
      }
    } catch (e) {
      print('Error getting route details: $e');
      return {
        'exists_on_server': false,
        'is_orphaned': false,
        'message': 'Error: $e',
      };
    }
  }

  // NEW FUNCTIONALITY: Update route ID (for when resending with conflict)
  static Future<int> updateRouteId(int oldRouteId, int newRouteId) async {
    final db = await getDatabase();

    try {
      // Get all segments with old route ID
      final segments = await getSegmentsByRouteId(oldRouteId);

      if (segments.isEmpty) {
        return 0;
      }

      // Update each segment with new route ID
      int updatedCount = 0;
      for (final segment in segments) {
        final result = await db.update(
          'map_routes',
          {'route_id': newRouteId},
          where: 'id = ?',
          whereArgs: [segment['id']],
        );

        if (result > 0) {
          updatedCount++;
        }
      }

      print('Updated $updatedCount segments from route ID $oldRouteId to $newRouteId');
      return updatedCount;
    } catch (e) {
      print('Error updating route ID: $e');
      return 0;
    }
  }

  // Add these methods to DBHelper.dart:

// NEW: Delete route from server
  static Future<bool> deleteRouteFromServer(int routeId) async {
    try {
      print('Deleting route $routeId from server...');

      final res = await http
          .delete(
        Uri.parse(
          'https://cloud.metaxperts.net:8443/erp/valor_trading/maproutesdelete/delete/$routeId',
        ),
        headers: {
          'Accept': 'application/json',
        },
      )
          .timeout(Duration(seconds: 10));

      print('Delete Server response status: ${res.statusCode}');

      if (res.statusCode == 200 || res.statusCode == 204) {
        print('Route $routeId deleted from server successfully');
        return true;
      } else {
        print('Failed to delete route from server: ${res.statusCode}');
        print('Response: ${res.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting route from server: $e');
      return false;
    }
  }

// NEW: Delete all segments of a route from server (one by one)
  static Future<Map<String, dynamic>> deleteAllSegmentsFromServer(int routeId) async {
    try {
      // First fetch the segments from server to get their individual IDs
      final serverRoutes = await fetchRoutesFromServer();
      final routeOnServer = serverRoutes.firstWhere(
            (route) => route['route_id'] == routeId,
        // orElse: () => ,
      );

      if (routeOnServer == null) {
        return {
          'success': false,
          'message': 'Route $routeId not found on server',
          'deleted_segments': 0,
        };
      }

      final segments = routeOnServer['segments'] as List<dynamic>;
      int deletedCount = 0;
      int failedCount = 0;

      // Delete each segment (if the server supports segment-level deletion)
      for (final segment in segments) {
        // Note: This assumes server has endpoint for segment deletion
        // You might need to adjust based on your server API
        final success = await deleteRouteFromServer(routeId);

        if (success) {
          deletedCount++;
        } else {
          failedCount++;
        }

        await Future.delayed(Duration(milliseconds: 300));
      }

      return {
        'success': deletedCount > 0,
        'message': 'Deleted $deletedCount segments, $failedCount failed',
        'deleted_segments': deletedCount,
      };
    } catch (e) {
      print('Error deleting all segments: $e');
      return {
        'success': false,
        'message': 'Error: $e',
        'deleted_segments': 0,
      };
    }
  }

  // Add this method to DBHelper class (anywhere after other methods)

// Edit existing multi-point route (preserving route_id)
  static Future<bool> editMultiPointRoute({
    required int routeId,
    required List<Map<String, dynamic>> waypoints,
    required List<double> segmentDistances,
    required List<String> segmentDurations,
    required double totalDistance,
    required String totalDuration,
    String province = 'Punjab',
    String city = 'Sialkot',
    required String date,
    String routeName = 'Unnamed Route',
  }) async {
    final db = await getDatabase();

    try {
      // Delete existing segments for this route
      await db.delete(
        'map_routes',
        where: 'route_id = ?',
        whereArgs: [routeId],
      );

      // Insert updated segments with the SAME route_id
      for (int i = 0; i < waypoints.length - 1; i++) {
        await db.insert('map_routes', {
          'route_id': routeId, // Keep the original route ID
          'sr_no': i + 1,
          'route_name': routeName,
          'start_name': waypoints[i]['name'] ?? 'Point ${i + 1}',
          'start_lat': waypoints[i]['lat'] ?? 0.0,
          'start_lng': waypoints[i]['lng'] ?? 0.0,
          'end_name': waypoints[i + 1]['name'] ?? 'Point ${i + 2}',
          'end_lat': waypoints[i + 1]['lat'] ?? 0.0,
          'end_lng': waypoints[i + 1]['lng'] ?? 0.0,
          'segment_distance': segmentDistances[i],
          'segment_duration': segmentDurations[i],
          'total_distance': totalDistance,
          'total_duration': totalDuration,
          'waypoints': jsonEncode(waypoints),
          'province': province,
          'city': city,
          'date': date,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return true;
    } catch (e) {
      print('Error editing multi-point route: $e');
      return false;
    }
  }

}