// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import '../Database/db_service.dart';
// // import 'edit_route_screen.dart';
// //
// // class RoutesListScreen extends StatefulWidget {
// //   @override
// //   State<RoutesListScreen> createState() => _RoutesListScreenState();
// // }
// //
// // class _RoutesListScreenState extends State<RoutesListScreen> {
// //   List<Map<String, dynamic>> routes = [];
// //
// //   void loadRoutes() async {
// //     final data = await DBHelper.getRoutes();
// //     setState(() {
// //       routes = data;
// //     });
// //   }
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     loadRoutes();
// //   }
// //
// //   Future<void> _checkAndResendRoute(Map<String, dynamic> route) async {
// //     final routeId = route['route_id'] as int;
// //
// //     // Check if route exists on server
// //     final existsOnServer = await DBHelper.doesRouteExistOnServer(routeId);
// //
// //     if (existsOnServer) {
// //       // Show message that route already exists on server
// //       showDialog(
// //         context: context,
// //         builder: (context) => AlertDialog(
// //           title: Text('Route Already on Server'),
// //           content: Text(
// //             'Route $routeId already exists on server. You must delete it from server first before resending.',
// //           ),
// //           actions: [
// //             TextButton(
// //               onPressed: () => Navigator.pop(context),
// //               child: Text('OK'),
// //             ),
// //           ],
// //         ),
// //       );
// //     } else {
// //       // Navigate to edit screen
// //       Navigator.push(
// //         context,
// //         MaterialPageRoute(
// //           builder: (_) => EditRouteScreen(route: route, routeId: routeId),
// //         ),
// //       ).then((success) {
// //         if (success == true) {
// //           // Refresh the list if route was edited and sent successfully
// //           loadRoutes();
// //         }
// //       });
// //     }
// //   }
// //
// //   void _showRouteOptions(Map<String, dynamic> route) {
// //     showModalBottomSheet(
// //       context: context,
// //       builder: (context) => Container(
// //         padding: EdgeInsets.all(20),
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Text(
// //               'Route Options',
// //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //             ),
// //             SizedBox(height: 16),
// //
// //             // View Details Button
// //             ListTile(
// //               leading: Icon(Icons.visibility),
// //               title: Text('View Details'),
// //               onTap: () {
// //                 Navigator.pop(context);
// //                 _showRouteDetails(route);
// //               },
// //             ),
// //
// //             // Edit & Resend Button
// //             ListTile(
// //               leading: Icon(Icons.edit),
// //               title: Text('Edit & Resend to Server'),
// //               onTap: () {
// //                 Navigator.pop(context);
// //                 _checkAndResendRoute(route);
// //               },
// //             ),
// //
// //             // Resend Without Editing Button
// //             ListTile(
// //               leading: Icon(Icons.cloud_upload),
// //               title: Text('Resend as-is to Server'),
// //               onTap: () {
// //                 Navigator.pop(context);
// //                 _resendRouteWithoutEditing(route);
// //               },
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Future<void> _resendRouteWithoutEditing(Map<String, dynamic> route) async {
// //     final routeId = route['route_id'] as int;
// //
// //     showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder: (context) => AlertDialog(
// //         title: Text('Resending Route'),
// //         content: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             CircularProgressIndicator(),
// //             SizedBox(height: 16),
// //             Text('Checking server and resending route...'),
// //           ],
// //         ),
// //       ),
// //     );
// //
// //     try {
// //       // Check if route exists on server
// //       final existsOnServer = await DBHelper.doesRouteExistOnServer(routeId);
// //
// //       if (existsOnServer) {
// //         Navigator.pop(context); // Close loading dialog
// //         showDialog(
// //           context: context,
// //           builder: (context) => AlertDialog(
// //             title: Text('Route Already on Server'),
// //             content: Text(
// //               'Route $routeId already exists on server. You must delete it from server first before resending.',
// //             ),
// //             actions: [
// //               TextButton(
// //                 onPressed: () => Navigator.pop(context),
// //                 child: Text('OK'),
// //               ),
// //             ],
// //           ),
// //         );
// //         return;
// //       }
// //
// //       // Resend all segments to server
// //       final result = await DBHelper.saveRouteSegmentsToServer(routeId);
// //
// //       Navigator.pop(context); // Close loading dialog
// //
// //       if (result['success'] == true) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('Route $routeId sent to server successfully!'),
// //             backgroundColor: Colors.green,
// //           ),
// //         );
// //       } else {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('Failed to send route to server'),
// //             backgroundColor: Colors.red,
// //           ),
// //         );
// //       }
// //     } catch (e) {
// //       Navigator.pop(context); // Close loading dialog
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
// //       );
// //     }
// //   }
// //
// //   void _showRouteDetails(Map<String, dynamic> route) {
// //     final r = route;
// //
// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         title: Text('Route Details - ID: ${r['route_id']}'),
// //         content: SingleChildScrollView(
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               Text('Total Distance: ${r['total_distance']} km'),
// //               Text('Total Duration: ${r['total_duration']}'),
// //               Text('Province: ${r['province']}'),
// //               Text('City: ${r['city']}'),
// //               Text('Date: ${r['date']}'),
// //               SizedBox(height: 16),
// //               Text('Segments:', style: TextStyle(fontWeight: FontWeight.bold)),
// //               SizedBox(height: 8),
// //
// //               // Show each segment
// //               if (r['segments'] != null)
// //                 ...(r['segments'] as List).map((segment) {
// //                   return Container(
// //                     margin: EdgeInsets.only(bottom: 8),
// //                     padding: EdgeInsets.all(8),
// //                     decoration: BoxDecoration(
// //                       border: Border.all(color: Colors.grey.shade300),
// //                       borderRadius: BorderRadius.circular(6),
// //                     ),
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         Text(
// //                           'Segment ${segment['sr_no']}',
// //                           style: TextStyle(fontWeight: FontWeight.w600),
// //                         ),
// //                         Text('From: ${segment['start_name']}'),
// //                         Text('To: ${segment['end_name']}'),
// //                         Row(
// //                           children: [
// //                             Icon(
// //                               Icons.straighten,
// //                               size: 14,
// //                               color: Colors.blue,
// //                             ),
// //                             SizedBox(width: 4),
// //                             Text('${segment['segment_distance']} km'),
// //                             SizedBox(width: 16),
// //                             Icon(
// //                               Icons.access_time,
// //                               size: 14,
// //                               color: Colors.orange,
// //                             ),
// //                             SizedBox(width: 4),
// //                             Text('${segment['segment_duration']}'),
// //                           ],
// //                         ),
// //                       ],
// //                     ),
// //                   );
// //                 }).toList(),
// //             ],
// //           ),
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context),
// //             child: Text('Close'),
// //           ),
// //           ElevatedButton(
// //             onPressed: () {
// //               Navigator.pop(context);
// //               _checkAndResendRoute(route);
// //             },
// //             child: Text('Edit & Resend'),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Saved Routes'),
// //         actions: [
// //           IconButton(
// //             icon: Icon(Icons.refresh),
// //             onPressed: loadRoutes,
// //             tooltip: 'Refresh',
// //           ),
// //         ],
// //       ),
// //       body: routes.isEmpty
// //           ? Center(
// //               child: Column(
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 children: [
// //                   Icon(Icons.route, size: 64, color: Colors.grey),
// //                   SizedBox(height: 16),
// //                   Text(
// //                     'No saved routes',
// //                     style: TextStyle(fontSize: 18, color: Colors.grey),
// //                   ),
// //                   SizedBox(height: 8),
// //                   Text(
// //                     'Create a route first',
// //                     style: TextStyle(color: Colors.grey),
// //                   ),
// //                 ],
// //               ),
// //             )
// //           : ListView.builder(
// //               itemCount: routes.length,
// //               itemBuilder: (context, index) {
// //                 final r = routes[index];
// //
// //                 return Card(
// //                   margin: EdgeInsets.all(8),
// //                   child: InkWell(
// //                     onTap: () => _showRouteOptions(r),
// //                     child: ListTile(
// //                       title: Text(
// //                         'Route ID: ${r['route_id']} | ${r['province']}, ${r['city']}',
// //                         style: TextStyle(fontWeight: FontWeight.bold),
// //                       ),
// //                       subtitle: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           Text(
// //                             '${r['start_name']} → ${r['end_name']}',
// //                             style: TextStyle(fontWeight: FontWeight.w500),
// //                           ),
// //                           Text(
// //                             '${r['segments_count']} segments | ${r['total_distance']} km | ${r['total_duration']}',
// //                             style: TextStyle(fontSize: 12),
// //                           ),
// //                           Text(
// //                             'Date: ${r['date']}',
// //                             style: TextStyle(fontSize: 12, color: Colors.grey),
// //                           ),
// //                         ],
// //                       ),
// //                       trailing: PopupMenuButton<String>(
// //                         onSelected: (value) {
// //                           if (value == 'view') {
// //                             _showRouteDetails(r);
// //                           } else if (value == 'edit') {
// //                             _checkAndResendRoute(r);
// //                           } else if (value == 'resend') {
// //                             _resendRouteWithoutEditing(r);
// //                           }
// //                         },
// //                         itemBuilder: (context) => [
// //                           PopupMenuItem(
// //                             value: 'view',
// //                             child: Row(
// //                               children: [
// //                                 Icon(Icons.visibility, size: 20),
// //                                 SizedBox(width: 8),
// //                                 Text('View Details'),
// //                               ],
// //                             ),
// //                           ),
// //                           PopupMenuItem(
// //                             value: 'edit',
// //                             child: Row(
// //                               children: [
// //                                 Icon(Icons.edit, size: 20),
// //                                 SizedBox(width: 8),
// //                                 Text('Edit & Resend'),
// //                               ],
// //                             ),
// //                           ),
// //                           PopupMenuItem(
// //                             value: 'resend',
// //                             child: Row(
// //                               children: [
// //                                 Icon(Icons.cloud_upload, size: 20),
// //                                 SizedBox(width: 8),
// //                                 Text('Resend to Server'),
// //                               ],
// //                             ),
// //                           ),
// //                         ],
// //                         child: Container(
// //                           padding: EdgeInsets.all(8),
// //                           child: Column(
// //                             mainAxisAlignment: MainAxisAlignment.center,
// //                             children: [
// //                               Icon(Icons.more_vert, size: 20),
// //                               if (r['segments_count'] > 1)
// //                                 Text(
// //                                   '${r['segments_count']}',
// //                                   style: TextStyle(
// //                                     fontSize: 10,
// //                                     fontWeight: FontWeight.bold,
// //                                     color: Colors.blue,
// //                                   ),
// //                                 ),
// //                             ],
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                 );
// //               },
// //             ),
// //     );
// //   }
// // }
//
//
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import '../Database/db_service.dart';
// import 'edit_route_screen.dart';
//
// class RoutesListScreen extends StatefulWidget {
//   @override
//   State<RoutesListScreen> createState() => _RoutesListScreenState();
// }
//
// class _RoutesListScreenState extends State<RoutesListScreen> {
//   List<Map<String, dynamic>> routes = [];
//   bool _isLoading = false;
//
//   void loadRoutes() async {
//     setState(() => _isLoading = true);
//     final data = await DBHelper.getRoutes();
//     setState(() {
//       routes = data;
//       _isLoading = false;
//     });
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     loadRoutes();
//   }
//
//   Future<void> _checkAndResendRoute(Map<String, dynamic> route) async {
//     final routeId = route['route_id'] as int;
//
//     // Check if route exists on server
//     final existsOnServer = await DBHelper.doesRouteExistOnServer(routeId);
//
//     if (existsOnServer) {
//       // Show message that route already exists on server
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           title: Row(
//             children: [
//               Icon(Icons.info, color: Colors.orange),
//               SizedBox(width: 12),
//               Text('Route On Server'),
//             ],
//           ),
//           content: Text(
//             'Route $routeId already exists on server. You must delete it from server first before resending.',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text('OK'),
//             ),
//           ],
//         ),
//       );
//     } else {
//       // Navigate to edit screen
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => EditRouteScreen(route: route, routeId: routeId),
//         ),
//       ).then((success) {
//         if (success == true) {
//           loadRoutes();
//         }
//       });
//     }
//   }
//
//   void _showRouteOptions(Map<String, dynamic> route) {
//     showModalBottomSheet(
//       context: context,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => Container(
//         padding: EdgeInsets.all(20),
//         child: SafeArea(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 40,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[300],
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               SizedBox(height: 20),
//               Text(
//                 'Route Options',
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 20),
//
//               _buildBottomSheetOption(
//                 icon: Icons.visibility,
//                 title: 'View Details',
//                 color: Colors.blue,
//                 onTap: () {
//                   Navigator.pop(context);
//                   _showRouteDetails(route);
//                 },
//               ),
//
//               _buildBottomSheetOption(
//                 icon: Icons.edit,
//                 title: 'Edit & Resend to Server',
//                 color: Colors.green,
//                 onTap: () {
//                   Navigator.pop(context);
//                   _checkAndResendRoute(route);
//                 },
//               ),
//
//               _buildBottomSheetOption(
//                 icon: Icons.cloud_upload,
//                 title: 'Resend as-is to Server',
//                 color: Colors.purple,
//                 onTap: () {
//                   Navigator.pop(context);
//                   _resendRouteWithoutEditing(route);
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBottomSheetOption({
//     required IconData icon,
//     required String title,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return Container(
//       margin: EdgeInsets.only(bottom: 12),
//       child: Material(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(12),
//           child: Padding(
//             padding: EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Container(
//                   padding: EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: color,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(icon, color: Colors.white, size: 20),
//                 ),
//                 SizedBox(width: 16),
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: color,
//                     ),
//                   ),
//                 ),
//                 Icon(Icons.arrow_forward_ios, size: 16, color: color),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _resendRouteWithoutEditing(Map<String, dynamic> route) async {
//     final routeId = route['route_id'] as int;
//
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         title: Text('Resending Route'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(height: 16),
//             Text('Checking server and resending route...'),
//           ],
//         ),
//       ),
//     );
//
//     try {
//       final existsOnServer = await DBHelper.doesRouteExistOnServer(routeId);
//
//       if (existsOnServer) {
//         Navigator.pop(context);
//         showDialog(
//           context: context,
//           builder: (context) => AlertDialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             title: Row(
//               children: [
//                 Icon(Icons.warning, color: Colors.orange),
//                 SizedBox(width: 12),
//                 Text('Route Exists'),
//               ],
//             ),
//             content: Text(
//               'Route $routeId already exists on server. You must delete it from server first before resending.',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: Text('OK'),
//               ),
//             ],
//           ),
//         );
//         return;
//       }
//
//       final result = await DBHelper.saveRouteSegmentsToServer(routeId);
//       Navigator.pop(context);
//
//       if (result['success'] == true) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Row(
//               children: [
//                 Icon(Icons.check_circle, color: Colors.white),
//                 SizedBox(width: 12),
//                 Text('Route $routeId sent successfully!'),
//               ],
//             ),
//             backgroundColor: Colors.green,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Row(
//               children: [
//                 Icon(Icons.error, color: Colors.white),
//                 SizedBox(width: 12),
//                 Text('Failed to send route'),
//               ],
//             ),
//             backgroundColor: Colors.red,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: $e'),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//       );
//     }
//   }
//
//   void _showRouteDetails(Map<String, dynamic> route) {
//     final r = route;
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         title: Row(
//           children: [
//             Icon(Icons.route, color: Colors.blue),
//             SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 'Route ID: ${r['route_id']}',
//                 style: TextStyle(fontSize: 18),
//               ),
//             ),
//           ],
//         ),
//         content: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Summary Card
//               Container(
//                 padding: EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.shade50,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildDetailRow('Distance', '${r['total_distance']} km', Icons.straighten),
//                     SizedBox(height: 8),
//                     _buildDetailRow('Duration', r['total_duration'], Icons.access_time),
//                     SizedBox(height: 8),
//                     _buildDetailRow('Province', r['province'], Icons.location_city),
//                     SizedBox(height: 8),
//                     _buildDetailRow('City', r['city'], Icons.place),
//                     SizedBox(height: 8),
//                     _buildDetailRow('Date', r['date'], Icons.calendar_today),
//                   ],
//                 ),
//               ),
//
//               SizedBox(height: 16),
//               Text(
//                 'Segments (${r['segments_count']}):',
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//               ),
//               SizedBox(height: 8),
//
//               if (r['segments'] != null)
//                 ...List.generate(
//                   (r['segments'] as List).length,
//                       (index) {
//                     final segment = (r['segments'] as List)[index];
//                     return Container(
//                       margin: EdgeInsets.only(bottom: 8),
//                       padding: EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [
//                             Colors.grey.shade50,
//                             Colors.grey.shade100,
//                           ],
//                         ),
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: Colors.grey.shade300),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               Container(
//                                 padding: EdgeInsets.all(6),
//                                 decoration: BoxDecoration(
//                                   color: Colors.blue,
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: Text(
//                                   '${segment['sr_no']}',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                               SizedBox(width: 8),
//                               Expanded(
//                                 child: Text(
//                                   'Segment ${segment['sr_no']}',
//                                   style: TextStyle(fontWeight: FontWeight.w600),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           SizedBox(height: 8),
//                           Row(
//                             children: [
//                               Icon(Icons.circle, color: Colors.green, size: 10),
//                               SizedBox(width: 6),
//                               Expanded(
//                                 child: Text(
//                                   segment['start_name'],
//                                   style: TextStyle(fontSize: 13),
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           SizedBox(height: 4),
//                           Row(
//                             children: [
//                               Icon(Icons.circle, color: Colors.red, size: 10),
//                               SizedBox(width: 6),
//                               Expanded(
//                                 child: Text(
//                                   segment['end_name'],
//                                   style: TextStyle(fontSize: 13),
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           SizedBox(height: 8),
//                           Wrap(
//                             spacing: 12,
//                             children: [
//                               Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Icon(Icons.straighten, size: 14, color: Colors.blue),
//                                   SizedBox(width: 4),
//                                   Text(
//                                     '${segment['segment_distance']} km',
//                                     style: TextStyle(fontSize: 12),
//                                   ),
//                                 ],
//                               ),
//                               Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Icon(Icons.access_time, size: 14, color: Colors.orange),
//                                   SizedBox(width: 4),
//                                   Text(
//                                     segment['segment_duration'],
//                                     style: TextStyle(fontSize: 12),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Close'),
//           ),
//           ElevatedButton.icon(
//             onPressed: () {
//               Navigator.pop(context);
//               _checkAndResendRoute(route);
//             },
//             icon: Icon(Icons.edit),
//             label: Text('Edit & Resend'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.green,
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDetailRow(String label, String value, IconData icon) {
//     return Row(
//       children: [
//         Icon(icon, size: 16, color: Colors.blue.shade700),
//         SizedBox(width: 8),
//         Text(
//           '$label: ',
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//             fontSize: 13,
//           ),
//         ),
//         Expanded(
//           child: Text(
//             value,
//             style: TextStyle(fontSize: 13),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         title: Text('Saved Routes'),
//         centerTitle: true,
//         elevation: 0,
//         flexibleSpace: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Colors.orange.shade700, Colors.orange.shade500],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: loadRoutes,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator())
//           : routes.isEmpty
//           ? Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.route, size: 80, color: Colors.grey.shade300),
//             SizedBox(height: 20),
//             Text(
//               'No saved routes',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey.shade600,
//               ),
//             ),
//             SizedBox(height: 8),
//             Text(
//               'Create a route first',
//               style: TextStyle(
//                 color: Colors.grey.shade500,
//               ),
//             ),
//           ],
//         ),
//       )
//           : RefreshIndicator(
//         onRefresh: () async => loadRoutes(),
//         child: ListView.builder(
//           padding: EdgeInsets.all(12),
//           itemCount: routes.length,
//           itemBuilder: (context, index) {
//             final r = routes[index];
//
//             return Card(
//               margin: EdgeInsets.only(bottom: 12),
//               elevation: 2,
//               shadowColor: Colors.black26,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: InkWell(
//                 onTap: () => _showRouteOptions(r),
//                 borderRadius: BorderRadius.circular(16),
//                 child: Padding(
//                   padding: EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Container(
//                             padding: EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 colors: [Colors.orange.shade400, Colors.orange.shade600],
//                               ),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Icon(
//                               Icons.route,
//                               color: Colors.white,
//                               size: 20,
//                             ),
//                           ),
//                           SizedBox(width: 12),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'Route ID: ${r['route_id']}',
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                                 Text(
//                                   '${r['province']}, ${r['city']}',
//                                   style: TextStyle(
//                                     color: Colors.grey.shade600,
//                                     fontSize: 13,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Container(
//                             padding: EdgeInsets.symmetric(
//                               horizontal: 10,
//                               vertical: 6,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.blue.shade50,
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             child: Text(
//                               '${r['segments_count']} seg',
//                               style: TextStyle(
//                                 color: Colors.blue.shade700,
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 12),
//                       Container(
//                         padding: EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.grey.shade50,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Column(
//                           children: [
//                             Row(
//                               children: [
//                                 Icon(Icons.circle, color: Colors.green, size: 10),
//                                 SizedBox(width: 6),
//                                 Expanded(
//                                   child: Text(
//                                     r['start_name'] ?? 'Start',
//                                     style: TextStyle(fontSize: 13),
//                                     maxLines: 1,
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             SizedBox(height: 6),
//                             Row(
//                               children: [
//                                 Icon(Icons.circle, color: Colors.red, size: 10),
//                                 SizedBox(width: 6),
//                                 Expanded(
//                                   child: Text(
//                                     r['end_name'] ?? 'End',
//                                     style: TextStyle(fontSize: 13),
//                                     maxLines: 1,
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                       SizedBox(height: 12),
//                       Wrap(
//                         spacing: 12,
//                         runSpacing: 8,
//                         children: [
//                           _buildInfoChip(
//                             Icons.straighten,
//                             '${r['total_distance']} km',
//                             Colors.blue,
//                           ),
//                           _buildInfoChip(
//                             Icons.access_time,
//                             r['total_duration'],
//                             Colors.orange,
//                           ),
//                           _buildInfoChip(
//                             Icons.calendar_today,
//                             r['date'],
//                             Colors.purple,
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoChip(IconData icon, String text, Color color) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 14, color: color),
//           SizedBox(width: 4),
//           Text(
//             text,
//             style: TextStyle(
//               fontSize: 12,
//               color: color,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// Updated RoutesListScreen: removed "Edit & Resend" for local-only routes.
// Local routes can still be viewed and "Resend as-is to Server".
// The edit option now only exists via ServerRoutesScreen (Edit & Repost).

import 'dart:convert';
import 'package:flutter/material.dart';
import '../Database/db_service.dart';
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

              _buildBottomSheetOption(
                icon: Icons.visibility,
                title: 'View Details',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _showRouteDetails(route);
                },
              ),

              // NOTE: "Edit & Resend" removed for local routes.
              // If you need to allow editing of local-only routes, re-introduce a guarded flow.

              _buildBottomSheetOption(
                icon: Icons.cloud_upload,
                title: 'Resend as-is to Server',
                color: Colors.purple,
                onTap: () {
                  Navigator.pop(context);
                  _resendRouteWithoutEditing(route);
                },
              ),
            ],
          ),
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.route, color: Colors.blue),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Route ID: ${r['route_id']}',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Summary Card
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Distance', '${r['total_distance']} km', Icons.straighten),
                    SizedBox(height: 8),
                    _buildDetailRow('Duration', r['total_duration'], Icons.access_time),
                    SizedBox(height: 8),
                    _buildDetailRow('Province', r['province'], Icons.location_city),
                    SizedBox(height: 8),
                    _buildDetailRow('City', r['city'], Icons.place),
                    SizedBox(height: 8),
                    _buildDetailRow('Date', r['date'], Icons.calendar_today),
                  ],
                ),
              ),

              SizedBox(height: 16),
              Text(
                'Segments (${r['segments_count']}):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),

              if (r['segments'] != null)
                ...List.generate(
                  (r['segments'] as List).length,
                      (index) {
                    final segment = (r['segments'] as List)[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Segment ${segment['sr_no']}',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text('From: ${segment['start_name']}'),
                          Text('To: ${segment['end_name']}'),
                          Row(
                            children: [
                              Icon(
                                Icons.straighten,
                                size: 14,
                                color: Colors.blue,
                              ),
                              SizedBox(width: 4),
                              Text('${segment['segment_distance']} km'),
                              SizedBox(width: 16),
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 4),
                              Text('${segment['segment_duration']}'),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _checkAndResendRoute(route);
            },
            icon: Icon(Icons.cloud_upload),
            label: Text('Resend to Server'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
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
                                  'Route ID: ${r['route_id']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
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

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
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
    );
  }
}