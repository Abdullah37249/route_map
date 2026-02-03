// import 'package:flutter/material.dart';
// import 'package:routing_0sm/screens/route_list_screen.dart';
//
// import 'map_screen.dart';
// import 'multi_point_map_screen.dart';
// import 'server_routes_screen.dart';
//
// class MainScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('OSM Route Planner')),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ElevatedButton(
//               child: Text('Create Multi-Point Route'),
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => MultiPointMapScreen()),
//                 );
//               },
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               child: Text('View Saved Routes'),
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => RoutesListScreen()),
//                 );
//               },
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               child: Text('View Server Routes (GET)'),
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => ServerRoutesScreen()),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:routing_0sm/screens/route_list_screen.dart';
import 'map_screen.dart';
import 'multi_point_map_screen.dart';
import 'server_routes_screen.dart';

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('OSM Route Planner', style: TextStyle(color: Colors.white),),
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
              // Main Actions
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 12),

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

              // View Saved Routes Card
              _buildActionCard(
                context: context,
                icon: Icons.bookmark,
                title: 'View Saved Routes',
                subtitle: 'Access your locally saved routes',
                gradientColors: [Colors.orange.shade400, Colors.orange.shade600],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RoutesListScreen()),
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
                gradientColors: [Colors.purple.shade400, Colors.purple.shade600],
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
}