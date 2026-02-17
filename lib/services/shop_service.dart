import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:routing_0sm/models/routes_add_shop_model.dart';

class ShopService {
  // APNA BASE URL
  static const String baseUrl = 'https://cloud.metaxperts.net:8443/erp/valor_trading';

  /// GET SHOPS BY ROUTE ID - FIXED URL
  static Future<List<AddShopModel>> fetchShopsByRouteId(int routeId) async {
    try {
      print('📡 Fetching shops for route ID: $routeId');

      // ✅ FIXED: Use the correct shop endpoint with the route ID
      final url = 'https://cloud.metaxperts.net:8443/erp/valor_trading/shoprouteget/get/$routeId';
      print('🌐 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      print('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        List<AddShopModel> shops = [];

        // Parse based on the actual response structure of this endpoint
        // You'll need to check what this API returns (list, object with items, etc.)
        if (data is List) {
          // If API returns a list directly
          shops = data.map((item) => AddShopModel.fromMap(item)).toList();
        } else if (data is Map) {
          // If API returns an object with a data/items array
          if (data.containsKey('items') && data['items'] is List) {
            shops = (data['items'] as List)
                .map((item) => AddShopModel.fromMap(item))
                .toList();
          } else if (data.containsKey('data') && data['data'] is List) {
            shops = (data['data'] as List)
                .map((item) => AddShopModel.fromMap(item))
                .toList();
          }
        }

        print('✅ Shops fetched for route $routeId: ${shops.length}');
        return shops;
      }

      print('❌ API returned status: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Error fetching shops: $e');
      return [];
    }
  }

  /// FILTER SHOPS NEAR ROUTE
  static List<AddShopModel> filterShopsNearRoute({
    required List<AddShopModel> allShops,
    required List<LatLng> routePoints,
    required double bufferMeters,
  }) {
    if (routePoints.isEmpty || allShops.isEmpty) return [];

    final distance = Distance();
    final List<AddShopModel> nearbyShops = [];

    for (final shop in allShops) {
      final lat = shop.lat;
      final lng = shop.lng;

      if (lat == null || lng == null) continue;

      final shopPoint = LatLng(lat, lng);

      for (int i = 0; i < routePoints.length - 1; i++) {
        final d = _distanceToSegment(
            shopPoint,
            routePoints[i],
            routePoints[i + 1]
        );

        if (d <= bufferMeters) {
          nearbyShops.add(shop);
          break;
        }
      }
    }

    print('📍 Found ${nearbyShops.length} shops within ${bufferMeters}m of route');
    return nearbyShops;
  }

  static double _distanceToSegment(LatLng p, LatLng a, LatLng b) {
    final distance = Distance();
    final l2 = distance(a, b);
    if (l2 == 0) return distance(p, a);

    final t = ((p.latitude - a.latitude) * (b.latitude - a.latitude) +
        (p.longitude - a.longitude) * (b.longitude - a.longitude)) / (l2 * l2);

    if (t < 0) return distance(p, a);
    if (t > 1) return distance(p, b);

    final projection = LatLng(
      a.latitude + t * (b.latitude - a.latitude),
      a.longitude + t * (b.longitude - a.longitude),
    );
    return distance(p, projection);
  }
}