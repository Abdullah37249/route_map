import '../Database/db_service.dart';

class LocalRepository {
  Future<List<Map<String, dynamic>>> getRoutes() async {
    return await DBHelper.getRoutes();
  }

  Future<List<Map<String, dynamic>>> getSegmentsByRouteId(int routeId) async {
    return await DBHelper.getSegmentsByRouteId(routeId);
  }

  Future<bool> updateSegment({
    required int id,
    String? startName,
    String? endName,
    double? segmentDistance,
    String? segmentDuration,
    double? totalDistance,
    String? totalDuration,
    String? province,
    String? city,
    String? date,
  }) async {
    return await DBHelper.updateSegment(
      id: id,
      startName: startName,
      endName: endName,
      segmentDistance: segmentDistance,
      segmentDuration: segmentDuration,
      totalDistance: totalDistance,
      totalDuration: totalDuration,
      province: province,
      city: city,
      date: date,
    );
  }

  Future<int> insertMultiPointRoute({
    required List<Map<String, dynamic>> waypoints,
    required List<double> segmentDistances,
    required List<String> segmentDurations,
    required double totalDistance,
    required String totalDuration,
    required String province,
    required String city,
    required String date,
  }) async {
    return await DBHelper.insertMultiPointRoute(
      waypoints: waypoints,
      segmentDistances: segmentDistances,
      segmentDurations: segmentDurations,
      totalDistance: totalDistance,
      totalDuration: totalDuration,
      province: province,
      city: city,
      date: date,
    );
  }

  Future<bool> deleteLocalRoute(int routeId) async {
    return await DBHelper.deleteLocalRoute(routeId);
  }

  Future<Map<String, dynamic>?> getRouteById(int routeId) async {
    return await DBHelper.getRouteById(routeId);
  }
}