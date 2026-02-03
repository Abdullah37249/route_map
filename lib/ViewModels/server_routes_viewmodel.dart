import '../Database/db_service.dart';

class ServerRoutesViewModel {
  List<Map<String, dynamic>> serverRoutes = [];

  Future<void> loadServerRoutes() async {
    serverRoutes = await DBHelper.fetchRoutesFromServer();
  }

  Future<bool> deleteRouteFromServer(int routeId) async {
    return await DBHelper.deleteRouteFromServer(routeId);
  }

  Future<Map<String, dynamic>> getRouteDetails(int routeId) async {
    try {
      final route = serverRoutes.firstWhere(
            (r) => r['route_id'] == routeId,
      );
      return route;
    } catch (e) {
      return {'error': 'Route not found'};
    }
  }
}