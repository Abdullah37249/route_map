// file: lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:routing_0sm/screens/route_list_screen.dart';
import '../Database/db_service.dart';


import 'real_time_navigation_screen.dart';
import 'route_selection_screen.dart';
import 'route_tracking_screen.dart';
import '../screens/map_screen.dart';
import '../screens/multi_point_map_screen.dart';
import '../screens/server_routes_screen.dart';


class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('OSM Route Planner', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                margin: EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Route Planner',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Plan, save, and track your routes',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Create Multi-Point Route Card
              _buildActionCard(
                context: context,
                icon: Icons.add_location_alt,
                title: 'Create Multi-Point Route',
                subtitle: 'Plan a route with multiple waypoints',
                gradientColors: [Colors.green.shade400, Colors.green.shade600],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MultiPointMapScreen()),
                  );
                },
              ),

              SizedBox(height: 12),

              // Real-Time Navigation Card
              _buildActionCard(
                context: context,
                icon: Icons.navigation,
                title: 'Real-Time Navigation',
                subtitle: 'Turn-by-turn navigation with geofencing',
                gradientColors: [Colors.purple.shade400, Colors.purple.shade600],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RouteSelectionScreen(
                        isForNavigation: true,
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: 12),

              // View Server Routes Card
              _buildActionCard(
                context: context,
                icon: Icons.cloud,
                title: 'View Server Routes',
                subtitle: 'Sync and manage server routes',
                gradientColors: [Colors.teal.shade400, Colors.teal.shade600],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ServerRoutesScreen()),
                  );
                },
              ),

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRouteSelectionDialogForNavigation(BuildContext context) async {
    try {
      final routes = await DBHelper.getRoutes();

      if (routes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No saved routes found'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(maxHeight: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade600, Colors.purple.shade400],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.navigation, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Select Route for Navigation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Routes List
                // ✅ FIX: Removed shrinkWrap when using Expanded
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    itemCount: routes.length,
                    itemBuilder: (context, index) {
                      final route = routes[index];
                      final routeId = route['route_id'] as int?;
                      final startName = route['start_name']?.toString() ?? 'Unknown';
                      final endName = route['end_name']?.toString() ?? 'Unknown';
                      final distance = route['total_distance']?.toString() ?? '0';
                      final duration = route['total_duration']?.toString() ?? '0 min';

                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.purple.shade400, Colors.purple.shade600],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            'Route $routeId',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$startName to $endName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.straighten, size: 12, color: Colors.blue),
                                  SizedBox(width: 4),
                                  Text('$distance km', style: TextStyle(fontSize: 11)),
                                  SizedBox(width: 12),
                                  Icon(Icons.access_time, size: 12, color: Colors.orange),
                                  SizedBox(width: 4),
                                  Text(duration, style: TextStyle(fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.purple),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RealTimeNavigationScreen(
                                  routeId: routeId!,
                                  routeName: 'Route $routeId Navigation',
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),

                // Footer
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading routes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showRouteSelectionDialog(BuildContext context) async {
    try {
      final routes = await DBHelper.getRoutes();

      if (routes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No saved routes found'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Select Route to Track'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: routes.length,
              itemBuilder: (context, index) {
                final route = routes[index];
                final routeId = route['route_id'] as int?;
                final startName = route['start_name']?.toString() ?? 'Unknown';
                final endName = route['end_name']?.toString() ?? 'Unknown';

                return ListTile(
                  leading: Icon(Icons.route, color: Colors.orange),
                  title: Text('Route $routeId'),
                  subtitle: Text('$startName to $endName'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RouteTrackingScreen(
                          routeId: routeId!,
                          routeName: 'Route $routeId',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading routes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24, color: Colors.blue.shade700),
              SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}