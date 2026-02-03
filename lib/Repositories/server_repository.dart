import '../Database/db_service.dart';

class ServerRepository {
  Future<bool> doesRouteExistOnServer(int routeId) async {
    return await DBHelper.doesRouteExistOnServer(routeId);
  }

  Future<Map<String, dynamic>> saveRouteSegmentsToServer(int routeId) async {
    return await DBHelper.saveRouteSegmentsToServer(routeId);
  }

  Future<List<Map<String, dynamic>>> fetchRoutesFromServer() async {
    return await DBHelper.fetchRoutesFromServer();
  }

  Future<bool> deleteRouteFromServer(int routeId) async {
    return await DBHelper.deleteRouteFromServer(routeId);
  }

  Future<Map<String, dynamic>> getRouteDetailsWithServerCheck(int routeId) async {
    return await DBHelper.getRouteDetailsWithServerCheck(routeId);
  }
}