import '../Database/db_service.dart';


class RouteListViewModel {
  List<Map<String, dynamic>> routes = [];

  Future<void> loadRoutes() async {
    routes = await DBHelper.getRoutes();
  }

  Future<bool> checkRouteExistsOnServer(int routeId) async {
    return await DBHelper.doesRouteExistOnServer(routeId);
  }

  Future<Map<String, dynamic>> resendRouteWithoutEditing(Map<String, dynamic> route) async {
    final routeId = route['route_id'] as int;

    final existsOnServer = await DBHelper.doesRouteExistOnServer(routeId);

    if (existsOnServer) {
      return {
        'success': false,
        'message': 'Route $routeId already exists on server. You must delete it from server first before resending.',
      };
    }

    final result = await DBHelper.saveRouteSegmentsToServer(routeId);

    if (result['success'] == true) {
      return {
        'success': true,
        'message': 'Route $routeId sent to server successfully!',
      };
    } else {
      return {
        'success': false,
        'message': 'Failed to send route to server',
      };
    }
  }

  Future<Map<String, dynamic>> getRouteDetails(int routeId) async {
    try {
      final routes = await DBHelper.getRoutes();
      final route = routes.firstWhere(
            (r) => r['route_id'] == routeId,
        orElse: () => {},
      );

      if (route.isEmpty) {
        return {'error': 'Route not found'};
      }

      return route;
    } catch (e) {
      return {'error': 'Error: $e'};
    }
  }
}