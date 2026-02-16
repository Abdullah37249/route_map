// file: lib/screens/route_list_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../Database/db_service.dart';
import '../geofancing/real_time_navigation_screen.dart';
import 'edit_route_screen.dart';

class RoutesListScreen extends StatefulWidget {
  @override
  State<RoutesListScreen> createState() => _RoutesListScreenState();
}

class _RoutesListScreenState extends State<RoutesListScreen> {
  List<Map<String, dynamic>> routes = [];
  bool _isLoading = false;

  void loadRoutes() async {
    setState(() => _isLoading = true);
    final data = await DBHelper.getRoutes();
    setState(() {
      routes = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    loadRoutes();
  }

  Future<void> _checkAndResendRoute(Map<String, dynamic> route) async {
    final routeId = route['route_id'] as int;

    // Check if route exists on server
    final existsOnServer = await DBHelper.doesRouteExistOnServer(routeId);

    if (existsOnServer) {
      // Show message that route already exists on server
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.info, color: Colors.orange),
              SizedBox(width: 12),
              Text('Route On Server'),
            ],
          ),
          content: Text(
            'Route $routeId already exists on server. You must delete it from server first before resending.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // For local routes we no longer allow editing in-place.
      // Instead we open a simple confirmation and then resend as-is.
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Resend Route'),
          content: Text('Do you want to resend route $routeId to server as-is?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('Resend')),
          ],
        ),
      );

      if (result == true) {
        _resendRouteWithoutEditing(route);
      }
    }
  }

  void _showRouteOptions(Map<String, dynamic> route) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Route Options',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              // Navigation Option
              _buildBottomSheetOption(
                icon: Icons.navigation,
                title: 'Start Navigation',
                color: Colors.purple,
                onTap: () {
                  Navigator.pop(context);
                  _startNavigation(route);
                },
              ),

              _buildBottomSheetOption(
                icon: Icons.visibility,
                title: 'View Details',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _showRouteDetails(route);
                },
              ),

              _buildBottomSheetOption(
                icon: Icons.cloud_upload,
                title: 'Resend as-is to Server',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _resendRouteWithoutEditing(route);
                },
              ),

              _buildBottomSheetOption(
                icon: Icons.edit,
                title: 'Edit Route',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  _editRoute(route);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editRoute(Map<String, dynamic> route) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditRouteScreen(
          route: route,
          routeId: route['route_id'] as int,
        ),
      ),
    );

    if (result == true) {
      loadRoutes(); // Refresh the list
    }
  }

  void _startNavigation(Map<String, dynamic> route) {
    final routeId = route['route_id'] as int;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RealTimeNavigationScreen(
          routeId: routeId,
          routeName: route['route_name'] ?? 'Route $routeId Navigation',
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resendRouteWithoutEditing(Map<String, dynamic> route) async {
    final routeId = route['route_id'] as int;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Resending Route'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking server and resending route...'),
          ],
        ),
      ),
    );

    try {
      final existsOnServer = await DBHelper.doesRouteExistOnServer(routeId);

      if (existsOnServer) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 12),
                Text('Route Exists'),
              ],
            ),
            content: Text(
              'Route $routeId already exists on server. You must delete it from server first before resending.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final result = await DBHelper.saveRouteSegmentsToServer(routeId);
      Navigator.pop(context);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Route $routeId sent successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('Failed to send route'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showRouteDetails(Map<String, dynamic> route) {
    final r = route;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade600, Colors.orange.shade400],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.route, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r['route_name'] ?? 'Route ID: ${r['route_id']}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'ID: ${r['route_id']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Card
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              'Route Name',
                              r['route_name'] ?? 'Unnamed',
                              Icons.route,
                              Colors.purple,
                            ),
                            Divider(height: 16),
                            _buildDetailRow(
                              'Distance',
                              '${r['total_distance']} km',
                              Icons.straighten,
                              Colors.blue,
                            ),
                            Divider(height: 16),
                            _buildDetailRow(
                              'Duration',
                              r['total_duration'],
                              Icons.access_time,
                              Colors.orange,
                            ),
                            Divider(height: 16),
                            _buildDetailRow(
                              'Province',
                              r['province'],
                              Icons.location_city,
                              Colors.green,
                            ),
                            Divider(height: 16),
                            _buildDetailRow(
                              'City',
                              r['city'],
                              Icons.place,
                              Colors.red,
                            ),
                            Divider(height: 16),
                            _buildDetailRow(
                              'Date',
                              r['date'],
                              Icons.calendar_today,
                              Colors.purple,
                            ),
                            Divider(height: 16),
                            _buildDetailRow(
                              'Segments',
                              '${r['segments_count']}',
                              Icons.list,
                              Colors.teal,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(Icons.list_alt, color: Colors.orange.shade700),
                          SizedBox(width: 8),
                          Text(
                            'Segments (${r['segments_count']}):',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      if (r['segments'] != null)
                        ...List.generate(
                          (r['segments'] as List<dynamic>).length,
                              (index) {
                            final segment = (r['segments'] as List<dynamic>)[index];
                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              padding: EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.grey.shade50, Colors.grey.shade100],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${segment['sr_no']}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Segment ${segment['sr_no']}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.circle, color: Colors.green, size: 10),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          segment['start_name'],
                                          style: TextStyle(fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.circle, color: Colors.red, size: 10),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          segment['end_name'],
                                          style: TextStyle(fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Wrap(
                                    spacing: 12,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.straighten, size: 14, color: Colors.blue),
                                          SizedBox(width: 4),
                                          Text(
                                            '${segment['segment_distance']} km',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.access_time, size: 14, color: Colors.orange),
                                          SizedBox(width: 4),
                                          Text(
                                            segment['segment_duration'],
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (segment['start_lat'] != null && segment['start_lng'] != null)
                                    Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Coordinates: ${segment['start_lat'].toStringAsFixed(6)}, ${segment['start_lng'].toStringAsFixed(6)}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // Actions
              Container(
                padding: EdgeInsets.all(20),
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
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close),
                        label: Text('Close'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _startNavigation(r);
                        },
                        icon: Icon(Icons.navigation),
                        label: Text('Navigate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _checkAndResendRoute(route);
                        },
                        icon: Icon(Icons.cloud_upload),
                        label: Text('Resend'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
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
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Saved Routes'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade700, Colors.orange.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: loadRoutes,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : routes.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, size: 80, color: Colors.grey.shade300),
            SizedBox(height: 20),
            Text(
              'No saved routes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Create a route first',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back),
              label: Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: () async => loadRoutes(),
        child: ListView.builder(
          padding: EdgeInsets.all(12),
          itemCount: routes.length,
          itemBuilder: (context, index) {
            final r = routes[index];

            return Card(
              margin: EdgeInsets.only(bottom: 12),
              elevation: 2,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () => _showRouteOptions(r),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.orange.shade400, Colors.orange.shade600],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.route,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r['route_name'] ?? 'Route ID: ${r['route_id']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${r['province']}, ${r['city']}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.navigation, color: Colors.purple),
                            onPressed: () => _startNavigation(r),
                            tooltip: 'Start Navigation',
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${r['segments_count']} seg',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.circle, color: Colors.green, size: 10),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    r['start_name'] ?? 'Start',
                                    style: TextStyle(fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.circle, color: Colors.red, size: 10),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    r['end_name'] ?? 'End',
                                    style: TextStyle(fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(
                            Icons.straighten,
                            '${r['total_distance']} km',
                            Colors.blue,
                          ),
                          _buildInfoChip(
                            Icons.access_time,
                            r['total_duration'],
                            Colors.orange,
                          ),
                          _buildInfoChip(
                            Icons.calendar_today,
                            r['date'],
                            Colors.purple,
                          ),
                          _buildInfoChip(
                            Icons.navigation,
                            'Navigate',
                            Colors.purple,
                            onTap: () => _startNavigation(r),
                          ),
                          _buildInfoChip(
                            Icons.edit,
                            'Edit',
                            Colors.green,
                            onTap: () => _editRoute(r),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: onTap != null ? Border.all(color: color, width: 1) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}