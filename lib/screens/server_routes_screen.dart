// // import 'package:flutter/material.dart';
// //
// // import '../Database/db_service.dart';
// //
// //
// // class ServerRoutesScreen extends StatefulWidget {
// //   @override
// //   State<ServerRoutesScreen> createState() => _ServerRoutesScreenState();
// // }
// //
// // class _ServerRoutesScreenState extends State<ServerRoutesScreen> {
// //   List<Map<String, dynamic>> serverRoutes = [];
// //   bool _isLoading = false;
// //   bool _isRefreshing = false;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadServerRoutes();
// //   }
// //
// //   Future<void> _loadServerRoutes() async {
// //     setState(() => _isLoading = true);
// //     try {
// //       final routes = await DBHelper.fetchRoutesFromServer();
// //       setState(() {
// //         serverRoutes = routes;
// //       });
// //     } catch (e) {
// //       print('Error loading server routes: $e');
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text('Failed to load routes from server'),
// //           backgroundColor: Colors.red,
// //         ),
// //       );
// //     } finally {
// //       setState(() => _isLoading = false);
// //     }
// //   }
// //
// //   Future<void> _refreshRoutes() async {
// //     setState(() => _isRefreshing = true);
// //     await _loadServerRoutes();
// //     setState(() => _isRefreshing = false);
// //   }
// //
// //   void _showRouteDetails(Map<String, dynamic> route) {
// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         title: Text('Route Details - ID: ${route['route_id']}'),
// //         content: SingleChildScrollView(
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               _buildDetailItem('Route ID', '${route['route_id']}'),
// //               _buildDetailItem('Segments', '${route['segments_count']}'),
// //               _buildDetailItem('From', route['start_name']),
// //               _buildDetailItem('To', route['end_name']),
// //               _buildDetailItem(
// //                 'Total Distance',
// //                 '${route['total_distance']} km',
// //               ),
// //               _buildDetailItem('Total Duration', route['total_duration']),
// //               _buildDetailItem('Province', route['province']),
// //               _buildDetailItem('City', route['city']),
// //               _buildDetailItem('Date', route['date']),
// //
// //               SizedBox(height: 16),
// //               Divider(),
// //               SizedBox(height: 8),
// //
// //               Text(
// //                 'Segments:',
// //                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
// //               ),
// //               SizedBox(height: 8),
// //
// //               // Show segments
// //               ...(route['segments'] as List<dynamic>).map<Widget>((segment) {
// //                 return Container(
// //                   margin: EdgeInsets.only(bottom: 8),
// //                   padding: EdgeInsets.all(12),
// //                   decoration: BoxDecoration(
// //                     border: Border.all(color: Colors.grey.shade300),
// //                     borderRadius: BorderRadius.circular(8),
// //                   ),
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Text(
// //                         'Segment ${segment['sr_no']}',
// //                         style: TextStyle(fontWeight: FontWeight.bold),
// //                       ),
// //                       SizedBox(height: 4),
// //                       Text('From: ${segment['start_name']}'),
// //                       Text('To: ${segment['end_name']}'),
// //                       SizedBox(height: 4),
// //                       Row(
// //                         children: [
// //                           Icon(Icons.straighten, size: 14, color: Colors.blue),
// //                           SizedBox(width: 4),
// //                           Text('${segment['segment_distance']} km'),
// //                           SizedBox(width: 16),
// //                           Icon(
// //                             Icons.access_time,
// //                             size: 14,
// //                             color: Colors.orange,
// //                           ),
// //                           SizedBox(width: 4),
// //                           Text(segment['segment_duration']),
// //                         ],
// //                       ),
// //                       if (segment['start_lat'] != null &&
// //                           segment['start_lng'] != null)
// //                         Text(
// //                           'Coordinates: ${segment['start_lat'].toStringAsFixed(6)}, ${segment['start_lng'].toStringAsFixed(6)}',
// //                           style: TextStyle(fontSize: 11, color: Colors.grey),
// //                         ),
// //                     ],
// //                   ),
// //                 );
// //               }).toList(),
// //             ],
// //           ),
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context),
// //             child: Text('Close'),
// //           ),
// //           TextButton(
// //             onPressed: () {
// //               Navigator.pop(context);
// //               _showDeleteConfirmation(route);
// //             },
// //             child: Text(
// //               'Delete from Server',
// //               style: TextStyle(color: Colors.red),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   void _showDeleteConfirmation(Map<String, dynamic> route) {
// //     final routeId = route['route_id'];
// //
// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         title: Text('Delete Route from Server?'),
// //         content: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Icon(Icons.delete, size: 48, color: Colors.red),
// //             SizedBox(height: 12),
// //             Text(
// //               'This will delete route $routeId from the server only.',
// //               textAlign: TextAlign.center,
// //             ),
// //             SizedBox(height: 8),
// //             Text(
// //               'Local data will NOT be affected.',
// //               textAlign: TextAlign.center,
// //               style: TextStyle(color: Colors.green),
// //             ),
// //           ],
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context),
// //             child: Text('Cancel'),
// //           ),
// //           ElevatedButton(
// //             onPressed: () {
// //               Navigator.pop(context);
// //               _deleteRouteFromServer(routeId);
// //             },
// //             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
// //             child: Text('Delete from Server'),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Future<void> _deleteRouteFromServer(int routeId) async {
// //     showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder: (context) => AlertDialog(
// //         title: Text('Deleting Route'),
// //         content: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             CircularProgressIndicator(),
// //             SizedBox(height: 16),
// //             Text('Deleting route $routeId from server...'),
// //           ],
// //         ),
// //       ),
// //     );
// //
// //     try {
// //       final success = await DBHelper.deleteRouteFromServer(routeId);
// //
// //       Navigator.pop(context); // Close loading dialog
// //
// //       if (success) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('Route $routeId deleted from server successfully'),
// //             backgroundColor: Colors.green,
// //           ),
// //         );
// //
// //         // Refresh the list
// //         await _loadServerRoutes();
// //       } else {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('Failed to delete route from server'),
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
// //   Widget _buildDetailItem(String label, String value) {
// //     return Padding(
// //       padding: EdgeInsets.only(bottom: 8),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Container(
// //             width: 100,
// //             child: Text(
// //               '$label:',
// //               style: TextStyle(fontWeight: FontWeight.bold),
// //             ),
// //           ),
// //           SizedBox(width: 8),
// //           Expanded(child: Text(value)),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Routes from Server'),
// //         actions: [
// //           IconButton(
// //             icon: Icon(Icons.refresh),
// //             onPressed: _refreshRoutes,
// //             tooltip: 'Refresh',
// //           ),
// //         ],
// //       ),
// //       body: _isLoading
// //           ? Center(child: CircularProgressIndicator())
// //           : serverRoutes.isEmpty
// //           ? Center(
// //               child: Column(
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 children: [
// //                   Icon(Icons.cloud_off, size: 64, color: Colors.grey),
// //                   SizedBox(height: 16),
// //                   Text(
// //                     'No routes found on server',
// //                     style: TextStyle(fontSize: 18, color: Colors.grey),
// //                   ),
// //                   SizedBox(height: 8),
// //                   Text(
// //                     'Pull down to refresh',
// //                     style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
// //                   ),
// //                   SizedBox(height: 16),
// //                   ElevatedButton.icon(
// //                     onPressed: _refreshRoutes,
// //                     icon: Icon(Icons.refresh),
// //                     label: Text('Refresh'),
// //                   ),
// //                 ],
// //               ),
// //             )
// //           : RefreshIndicator(
// //               onRefresh: _refreshRoutes,
// //               child: ListView.builder(
// //                 itemCount: serverRoutes.length,
// //                 itemBuilder: (context, index) {
// //                   final route = serverRoutes[index];
// //                   final routeId = route['route_id'];
// //                   final segments = route['segments'] as List<dynamic>;
// //
// //                   return Card(
// //                     margin: EdgeInsets.all(8),
// //                     elevation: 2,
// //                     child: InkWell(
// //                       onTap: () => _showRouteDetails(route),
// //                       borderRadius: BorderRadius.circular(8),
// //                       child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           ListTile(
// //                             leading: Container(
// //                               width: 40,
// //                               height: 40,
// //                               decoration: BoxDecoration(
// //                                 color: Colors.blue.shade100,
// //                                 shape: BoxShape.circle,
// //                               ),
// //                               child: Center(
// //                                 child: Text(
// //                                   '${segments.length}',
// //                                   style: TextStyle(
// //                                     fontWeight: FontWeight.bold,
// //                                     color: Colors.blue,
// //                                   ),
// //                                 ),
// //                               ),
// //                             ),
// //                             title: Text(
// //                               'Route ID: $routeId',
// //                               style: TextStyle(fontWeight: FontWeight.bold),
// //                             ),
// //                             subtitle: Column(
// //                               crossAxisAlignment: CrossAxisAlignment.start,
// //                               mainAxisSize: MainAxisSize.min,
// //                               children: [
// //                                 Text(
// //                                   '${route['start_name']} → ${route['end_name']}',
// //                                   maxLines: 1,
// //                                   overflow: TextOverflow.ellipsis,
// //                                 ),
// //                                 SizedBox(height: 4),
// //                                 Text(
// //                                   '${route['province']}, ${route['city']} • ${route['date']}',
// //                                   style: TextStyle(
// //                                     fontSize: 12,
// //                                     color: Colors.grey,
// //                                   ),
// //                                 ),
// //                                 SizedBox(height: 4),
// //                                 Row(
// //                                   children: [
// //                                     Container(
// //                                       padding: EdgeInsets.symmetric(
// //                                         horizontal: 8,
// //                                         vertical: 4,
// //                                       ),
// //                                       decoration: BoxDecoration(
// //                                         color: Colors.blue.shade50,
// //                                         borderRadius: BorderRadius.circular(12),
// //                                       ),
// //                                       child: Text(
// //                                         '${route['total_distance']} km',
// //                                         style: TextStyle(
// //                                           fontSize: 11,
// //                                           color: Colors.blue,
// //                                         ),
// //                                       ),
// //                                     ),
// //                                     SizedBox(width: 8),
// //                                     Text(
// //                                       route['total_duration'],
// //                                       style: TextStyle(
// //                                         fontSize: 11,
// //                                         color: Colors.orange,
// //                                       ),
// //                                     ),
// //                                   ],
// //                                 ),
// //                               ],
// //                             ),
// //                             trailing: IconButton(
// //                               icon: Icon(Icons.delete, color: Colors.red),
// //                               onPressed: () => _showDeleteConfirmation(route),
// //                               tooltip: 'Delete from server',
// //                             ),
// //                           ),
// //                           Container(
// //                             padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
// //                             child: Wrap(
// //                               spacing: 8,
// //                               runSpacing: 8,
// //                               children: List.generate(segments.length, (
// //                                 segmentIndex,
// //                               ) {
// //                                 final segment = segments[segmentIndex];
// //                                 return Container(
// //                                   padding: EdgeInsets.symmetric(
// //                                     horizontal: 8,
// //                                     vertical: 4,
// //                                   ),
// //                                   decoration: BoxDecoration(
// //                                     color: Colors.grey.shade100,
// //                                     borderRadius: BorderRadius.circular(16),
// //                                   ),
// //                                   child: Row(
// //                                     mainAxisSize: MainAxisSize.min,
// //                                     children: [
// //                                       Text(
// //                                         'S${segment['sr_no']}',
// //                                         style: TextStyle(
// //                                           fontSize: 11,
// //                                           fontWeight: FontWeight.bold,
// //                                           color: Colors.blue,
// //                                         ),
// //                                       ),
// //                                       SizedBox(width: 4),
// //                                       Text(
// //                                         '${segment['segment_distance']} km',
// //                                         style: TextStyle(fontSize: 11),
// //                                       ),
// //                                     ],
// //                                   ),
// //                                 );
// //                               }),
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                   );
// //                 },
// //               ),
// //             ),
// //     );
// //   }
// // }
//
//
// import 'package:flutter/material.dart';
// import '../Database/db_service.dart';
//
// class ServerRoutesScreen extends StatefulWidget {
//   @override
//   State<ServerRoutesScreen> createState() => _ServerRoutesScreenState();
// }
//
// class _ServerRoutesScreenState extends State<ServerRoutesScreen> {
//   List<Map<String, dynamic>> serverRoutes = [];
//   bool _isLoading = false;
//   bool _isRefreshing = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadServerRoutes();
//   }
//
//   Future<void> _loadServerRoutes() async {
//     setState(() => _isLoading = true);
//     try {
//       final routes = await DBHelper.fetchRoutesFromServer();
//       setState(() {
//         serverRoutes = routes;
//       });
//     } catch (e) {
//       print('Error loading server routes: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Row(
//             children: [
//               Icon(Icons.error, color: Colors.white),
//               SizedBox(width: 12),
//               Expanded(
//                 child: Text('Failed to load routes from server'),
//               ),
//             ],
//           ),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   Future<void> _refreshRoutes() async {
//     setState(() => _isRefreshing = true);
//     await _loadServerRoutes();
//     setState(() => _isRefreshing = false);
//   }
//
//   void _showRouteDetails(Map<String, dynamic> route) {
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Container(
//           constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Header
//               Container(
//                 padding: EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [Colors.purple.shade600, Colors.purple.shade400],
//                   ),
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(20),
//                     topRight: Radius.circular(20),
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(Icons.route, color: Colors.white, size: 28),
//                     SizedBox(width: 12),
//                     Expanded(
//                       child: Text(
//                         'Route ID: ${route['route_id']}',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                     IconButton(
//                       icon: Icon(Icons.close, color: Colors.white),
//                       onPressed: () => Navigator.pop(context),
//                     ),
//                   ],
//                 ),
//               ),
//
//               // Content
//               Flexible(
//                 child: SingleChildScrollView(
//                   padding: EdgeInsets.all(20),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Summary Card
//                       Container(
//                         padding: EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Colors.purple.shade50,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Column(
//                           children: [
//                             _buildDetailRow(
//                               'Distance',
//                               '${route['total_distance']} km',
//                               Icons.straighten,
//                               Colors.blue,
//                             ),
//                             Divider(height: 16),
//                             _buildDetailRow(
//                               'Duration',
//                               route['total_duration'],
//                               Icons.access_time,
//                               Colors.orange,
//                             ),
//                             Divider(height: 16),
//                             _buildDetailRow(
//                               'Province',
//                               route['province'],
//                               Icons.location_city,
//                               Colors.green,
//                             ),
//                             Divider(height: 16),
//                             _buildDetailRow(
//                               'City',
//                               route['city'],
//                               Icons.place,
//                               Colors.red,
//                             ),
//                             Divider(height: 16),
//                             _buildDetailRow(
//                               'Date',
//                               route['date'],
//                               Icons.calendar_today,
//                               Colors.purple,
//                             ),
//                           ],
//                         ),
//                       ),
//
//                       SizedBox(height: 20),
//                       Row(
//                         children: [
//                           Icon(Icons.list_alt, color: Colors.purple.shade700),
//                           SizedBox(width: 8),
//                           Text(
//                             'Segments (${route['segments_count']}):',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 18,
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 12),
//
//                       ...List.generate(
//                         (route['segments'] as List<dynamic>).length,
//                             (index) {
//                           final segment = (route['segments'] as List<dynamic>)[index];
//                           return Container(
//                             margin: EdgeInsets.only(bottom: 12),
//                             padding: EdgeInsets.all(14),
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 colors: [Colors.grey.shade50, Colors.grey.shade100],
//                               ),
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(color: Colors.grey.shade300),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   children: [
//                                     Container(
//                                       padding: EdgeInsets.all(8),
//                                       decoration: BoxDecoration(
//                                         color: Colors.purple,
//                                         shape: BoxShape.circle,
//                                       ),
//                                       child: Text(
//                                         '${segment['sr_no']}',
//                                         style: TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 12,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ),
//                                     SizedBox(width: 10),
//                                     Expanded(
//                                       child: Text(
//                                         'Segment ${segment['sr_no']}',
//                                         style: TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 15,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 SizedBox(height: 10),
//                                 Row(
//                                   children: [
//                                     Icon(Icons.circle, color: Colors.green, size: 10),
//                                     SizedBox(width: 8),
//                                     Expanded(
//                                       child: Text(
//                                         segment['start_name'],
//                                         style: TextStyle(fontSize: 13),
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 SizedBox(height: 6),
//                                 Row(
//                                   children: [
//                                     Icon(Icons.circle, color: Colors.red, size: 10),
//                                     SizedBox(width: 8),
//                                     Expanded(
//                                       child: Text(
//                                         segment['end_name'],
//                                         style: TextStyle(fontSize: 13),
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 SizedBox(height: 10),
//                                 Wrap(
//                                   spacing: 12,
//                                   children: [
//                                     Row(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: [
//                                         Icon(Icons.straighten, size: 14, color: Colors.blue),
//                                         SizedBox(width: 4),
//                                         Text(
//                                           '${segment['segment_distance']} km',
//                                           style: TextStyle(fontSize: 12),
//                                         ),
//                                       ],
//                                     ),
//                                     Row(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: [
//                                         Icon(Icons.access_time, size: 14, color: Colors.orange),
//                                         SizedBox(width: 4),
//                                         Text(
//                                           segment['segment_duration'],
//                                           style: TextStyle(fontSize: 12),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                                 if (segment['start_lat'] != null && segment['start_lng'] != null)
//                                   Padding(
//                                     padding: EdgeInsets.only(top: 8),
//                                     child: Text(
//                                       'Coordinates: ${segment['start_lat'].toStringAsFixed(6)}, ${segment['start_lng'].toStringAsFixed(6)}',
//                                       style: TextStyle(fontSize: 11, color: Colors.grey),
//                                     ),
//                                   ),
//                               ],
//                             ),
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               // Actions
//               Container(
//                 padding: EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade50,
//                   borderRadius: BorderRadius.only(
//                     bottomLeft: Radius.circular(20),
//                     bottomRight: Radius.circular(20),
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton.icon(
//                         onPressed: () => Navigator.pop(context),
//                         icon: Icon(Icons.close),
//                         label: Text('Close'),
//                         style: OutlinedButton.styleFrom(
//                           padding: EdgeInsets.symmetric(vertical: 12),
//                           side: BorderSide(color: Colors.grey.shade400),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: 12),
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: () {
//                           Navigator.pop(context);
//                           _showDeleteConfirmation(route);
//                         },
//                         icon: Icon(Icons.delete),
//                         label: Text('Delete'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.red,
//                           foregroundColor: Colors.white,
//                           padding: EdgeInsets.symmetric(vertical: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showDeleteConfirmation(Map<String, dynamic> route) {
//     final routeId = route['route_id'];
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         title: Row(
//           children: [
//             Icon(Icons.warning, color: Colors.red, size: 28),
//             SizedBox(width: 12),
//             Text('Delete Route?'),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.red.shade50,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Column(
//                 children: [
//                   Text(
//                     'This will delete route $routeId from the server only.',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(fontSize: 15),
//                   ),
//                   SizedBox(height: 12),
//                   Container(
//                     padding: EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.green.shade50,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(Icons.info, color: Colors.green.shade700, size: 20),
//                         SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             'Local data will NOT be affected.',
//                             style: TextStyle(
//                               color: Colors.green.shade700,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//           ElevatedButton.icon(
//             onPressed: () {
//               Navigator.pop(context);
//               _deleteRouteFromServer(routeId);
//             },
//             icon: Icon(Icons.delete),
//             label: Text('Delete'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
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
//   Future<void> _deleteRouteFromServer(int routeId) async {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         title: Text('Deleting Route'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(height: 16),
//             Text('Deleting route $routeId from server...'),
//           ],
//         ),
//       ),
//     );
//
//     try {
//       final success = await DBHelper.deleteRouteFromServer(routeId);
//       Navigator.pop(context);
//
//       if (success) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Row(
//               children: [
//                 Icon(Icons.check_circle, color: Colors.white),
//                 SizedBox(width: 12),
//                 Expanded(
//                   child: Text('Route $routeId deleted successfully!'),
//                 ),
//               ],
//             ),
//             backgroundColor: Colors.green,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         );
//         _loadServerRoutes();
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Row(
//               children: [
//                 Icon(Icons.error, color: Colors.white),
//                 SizedBox(width: 12),
//                 Expanded(
//                   child: Text('Failed to delete route from server'),
//                 ),
//               ],
//             ),
//             backgroundColor: Colors.red,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
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
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//       );
//     }
//   }
//
//   Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
//     return Row(
//       children: [
//         Icon(icon, size: 18, color: color),
//         SizedBox(width: 12),
//         Text(
//           '$label: ',
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//             fontSize: 14,
//           ),
//         ),
//         Expanded(
//           child: Text(
//             value,
//             style: TextStyle(fontSize: 14),
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
//         title: Text('Server Routes'),
//         centerTitle: true,
//         elevation: 0,
//         flexibleSpace: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Colors.purple.shade700, Colors.purple.shade500],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: _refreshRoutes,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(height: 16),
//             Text(
//               'Loading routes from server...',
//               style: TextStyle(color: Colors.grey.shade600),
//             ),
//           ],
//         ),
//       )
//           : serverRoutes.isEmpty
//           ? Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.cloud_off, size: 80, color: Colors.grey.shade300),
//             SizedBox(height: 20),
//             Text(
//               'No routes found on server',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey.shade600,
//               ),
//             ),
//             SizedBox(height: 8),
//             Text(
//               'Pull down to refresh',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey.shade500,
//               ),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton.icon(
//               onPressed: _refreshRoutes,
//               icon: Icon(Icons.refresh),
//               label: Text('Refresh'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.purple,
//                 foregroundColor: Colors.white,
//                 padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       )
//           : RefreshIndicator(
//         onRefresh: _refreshRoutes,
//         child: ListView.builder(
//           padding: EdgeInsets.all(12),
//           itemCount: serverRoutes.length,
//           itemBuilder: (context, index) {
//             final route = serverRoutes[index];
//             final routeId = route['route_id'];
//             final segments = route['segments'] as List<dynamic>;
//
//             return Card(
//               margin: EdgeInsets.only(bottom: 12),
//               elevation: 2,
//               shadowColor: Colors.black26,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: InkWell(
//                 onTap: () => _showRouteDetails(route),
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
//                                 colors: [Colors.purple.shade400, Colors.purple.shade600],
//                               ),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Icon(
//                               Icons.cloud,
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
//                                   'Route ID: $routeId',
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                                 Text(
//                                   '${route['province']}, ${route['city']}',
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
//                               color: Colors.purple.shade50,
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             child: Text(
//                               '${segments.length} seg',
//                               style: TextStyle(
//                                 color: Colors.purple.shade700,
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
//                                     route['start_name'] ?? 'Start',
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
//                                     route['end_name'] ?? 'End',
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
//                         spacing: 8,
//                         runSpacing: 8,
//                         children: [
//                           _buildInfoChip(
//                             Icons.straighten,
//                             '${route['total_distance']} km',
//                             Colors.blue,
//                           ),
//                           _buildInfoChip(
//                             Icons.access_time,
//                             route['total_duration'],
//                             Colors.orange,
//                           ),
//                           _buildInfoChip(
//                             Icons.calendar_today,
//                             route['date'],
//                             Colors.purple,
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 12),
//                       Container(
//                         decoration: BoxDecoration(
//                           color: Colors.grey.shade100,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         padding: EdgeInsets.all(8),
//                         child: Wrap(
//                           spacing: 6,
//                           runSpacing: 6,
//                           children: List.generate(segments.length, (segmentIndex) {
//                             final segment = segments[segmentIndex];
//                             return Container(
//                               padding: EdgeInsets.symmetric(
//                                 horizontal: 8,
//                                 vertical: 4,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(16),
//                                 border: Border.all(color: Colors.grey.shade300),
//                               ),
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Text(
//                                     'S${segment['sr_no']}',
//                                     style: TextStyle(
//                                       fontSize: 11,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.purple,
//                                     ),
//                                   ),
//                                   SizedBox(width: 4),
//                                   Text(
//                                     '${segment['segment_distance']} km',
//                                     style: TextStyle(fontSize: 10),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           }),
//                         ),
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


// Updated ServerRoutesScreen with "Edit & Repost" flow.
// - Prepares a local copy of the server route (preserves route_id).
// - Opens MultiPointMapScreen.editMode for editing.
// - After editing the map screen saves, server route list is refreshed.

import 'package:flutter/material.dart';
import '../Database/db_service.dart';
import 'multi_point_map_screen.dart';

class ServerRoutesScreen extends StatefulWidget {
  @override
  State<ServerRoutesScreen> createState() => _ServerRoutesScreenState();
}

class _ServerRoutesScreenState extends State<ServerRoutesScreen> {
  List<Map<String, dynamic>> serverRoutes = [];
  bool _isLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadServerRoutes();
  }

  Future<void> _loadServerRoutes() async {
    setState(() => _isLoading = true);
    try {
      final routes = await DBHelper.fetchRoutesFromServer();
      setState(() {
        serverRoutes = routes;
      });
    } catch (e) {
      print('Error loading server routes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Failed to load routes from server'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshRoutes() async {
    setState(() => _isRefreshing = true);
    await _loadServerRoutes();
    setState(() => _isRefreshing = false);
  }

  // Prepare a local copy of a server route so the local editor can open it.
  // This uses DBHelper.editMultiPointRoute to create local segments with the same route_id.
  Future<void> _prepareLocalCopyForServerRoute(Map<String, dynamic> serverRoute) async {
    try {
      final int routeId = serverRoute['route_id'] as int;
      final segments = (serverRoute['segments'] as List<dynamic>).cast<Map<String, dynamic>>();

      if (segments.isEmpty) return;

      // Build waypoints: start of each segment, then append final end
      final List<Map<String, dynamic>> waypoints = [];
      for (final seg in segments) {
        final startLat = (seg['start_lat'] is String)
            ? double.tryParse(seg['start_lat'].toString()) ?? 0.0
            : (seg['start_lat'] as double? ?? 0.0);
        final startLng = (seg['start_lng'] is String)
            ? double.tryParse(seg['start_lng'].toString()) ?? 0.0
            : (seg['start_lng'] as double? ?? 0.0);
        waypoints.add({
          'name': seg['start_name']?.toString() ?? 'Point',
          'lat': startLat,
          'lng': startLng,
          'address': seg['start_name']?.toString() ?? '',
        });
      }

      final last = segments.last;
      final endLat = (last['end_lat'] is String)
          ? double.tryParse(last['end_lat'].toString()) ?? 0.0
          : (last['end_lat'] as double? ?? 0.0);
      final endLng = (last['end_lng'] is String)
          ? double.tryParse(last['end_lng'].toString()) ?? 0.0
          : (last['end_lng'] as double? ?? 0.0);
      waypoints.add({
        'name': last['end_name']?.toString() ?? 'End',
        'lat': endLat,
        'lng': endLng,
        'address': last['end_name']?.toString() ?? '',
      });

      // Build segment distances/durations
      final List<double> segmentDistances = [];
      final List<String> segmentDurations = [];
      for (final seg in segments) {
        final dist = (seg['segment_distance'] is String)
            ? double.tryParse(seg['segment_distance'].toString()) ?? 0.0
            : (seg['segment_distance'] as double? ?? 0.0);
        final dur = seg['segment_duration']?.toString() ?? '0 min';
        segmentDistances.add(dist);
        segmentDurations.add(dur);
      }

      final totalDistance = (segments.first['total_distance'] is String)
          ? double.tryParse(segments.first['total_distance'].toString()) ?? 0.0
          : (segments.first['total_distance'] as double? ?? 0.0);
      final totalDuration = segments.first['total_duration']?.toString() ?? '';

      // Use editMultiPointRoute to create local rows with same route_id
      await DBHelper.editMultiPointRoute(
        routeId: routeId,
        waypoints: waypoints,
        segmentDistances: segmentDistances,
        segmentDurations: segmentDurations,
        totalDistance: totalDistance,
        totalDuration: totalDuration,
        province: serverRoute['province']?.toString() ?? 'Punjab',
        city: serverRoute['city']?.toString() ?? 'Sialkot',
        date: serverRoute['date']?.toString() ?? DateTime.now().toIso8601String().split('T')[0],
      );
    } catch (e) {
      print('Error preparing local copy: $e');
      rethrow;
    }
  }

  // Full flow: prepare local copy then open map editor
  Future<void> _editAndOpenEditor(Map<String, dynamic> serverRoute) async {
    final routeId = serverRoute['route_id'] as int;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Preparing editor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Preparing local copy for editing...'),
          ],
        ),
      ),
    );

    try {
      await _prepareLocalCopyForServerRoute(serverRoute);
      Navigator.pop(context); // close preparing dialog

      // Build waypoints to pass to the editor (read from local DB to ensure consistency)
      final localSegments = await DBHelper.getSegmentsByRouteId(routeId);
      final List<Map<String, dynamic>> waypoints = [];
      if (localSegments.isNotEmpty) {
        for (final seg in localSegments) {
          waypoints.add({
            'name': seg['start_name']?.toString() ?? 'Point',
            'lat': seg['start_lat'] as double? ?? 0.0,
            'lng': seg['start_lng'] as double? ?? 0.0,
            'address': seg['start_name']?.toString() ?? '',
          });
        }
        // append last end
        final last = localSegments.last;
        waypoints.add({
          'name': last['end_name']?.toString() ?? 'End',
          'lat': last['end_lat'] as double? ?? 0.0,
          'lng': last['end_lng'] as double? ?? 0.0,
          'address': last['end_name']?.toString() ?? '',
        });
      }

      // Open editor in editMode with existingWaypoints and routeId
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MultiPointMapScreen.editMode(
            existingWaypoints: waypoints,
            routeId: routeId,
          ),
        ),
      );

      // If the editor saved and reposted, refresh server list
      if (result == true) {
        await _loadServerRoutes();
      }
    } catch (e) {
      Navigator.pop(context); // ensure dialog closed if error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to prepare editor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRouteDetails(Map<String, dynamic> route) {
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
                    colors: [Colors.purple.shade600, Colors.purple.shade400],
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
                      child: Text(
                        'Route ID: ${route['route_id']}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              'Distance',
                              '${route['total_distance']} km',
                              Icons.straighten,
                              Colors.blue,
                            ),
                            Divider(height: 16),
                            _buildDetailRow(
                              'Duration',
                              route['total_duration'],
                              Icons.access_time,
                              Colors.orange,
                            ),
                            Divider(height: 16),
                            _buildDetailRow(
                              'Province',
                              route['province'],
                              Icons.location_city,
                              Colors.green,
                            ),
                            Divider(height: 16),
                            _buildDetailRow(
                              'City',
                              route['city'],
                              Icons.place,
                              Colors.red,
                            ),
                            Divider(height: 16),
                            _buildDetailRow(
                              'Date',
                              route['date'],
                              Icons.calendar_today,
                              Colors.purple,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(Icons.list_alt, color: Colors.purple.shade700),
                          SizedBox(width: 8),
                          Text(
                            'Segments (${route['segments_count']}):',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      ...List.generate(
                        (route['segments'] as List<dynamic>).length,
                            (index) {
                          final segment = (route['segments'] as List<dynamic>)[index];
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
                                        color: Colors.purple,
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
                          _showDeleteConfirmation(route);
                        },
                        icon: Icon(Icons.delete),
                        label: Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
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
                          _editAndOpenEditor(route);
                        },
                        icon: Icon(Icons.edit),
                        label: Text('Edit & Repost'),
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

  void _showDeleteConfirmation(Map<String, dynamic> route) {
    final routeId = route['route_id'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Delete Route?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'This will delete route $routeId from the server only.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.green.shade700, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Local data will NOT be affected.',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _deleteRouteFromServer(routeId);
            },
            icon: Icon(Icons.delete),
            label: Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRouteFromServer(int routeId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Deleting Route'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Deleting route $routeId from server...'),
          ],
        ),
      ),
    );

    try {
      final success = await DBHelper.deleteRouteFromServer(routeId);
      Navigator.pop(context);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Route $routeId deleted successfully!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        _loadServerRoutes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to delete route from server'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
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
        title: Text('Server Routes'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade700, Colors.purple.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshRoutes,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading routes from server...',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      )
          : serverRoutes.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 80, color: Colors.grey.shade300),
            SizedBox(height: 20),
            Text(
              'No routes found on server',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Pull down to refresh',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refreshRoutes,
              icon: Icon(Icons.refresh),
              label: Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
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
        onRefresh: _refreshRoutes,
        child: ListView.builder(
          padding: EdgeInsets.all(12),
          itemCount: serverRoutes.length,
          itemBuilder: (context, index) {
            final route = serverRoutes[index];
            final routeId = route['route_id'];
            final segments = route['segments'] as List<dynamic>;

            return Card(
              margin: EdgeInsets.only(bottom: 12),
              elevation: 2,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () => _showRouteDetails(route),
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
                                colors: [Colors.purple.shade400, Colors.purple.shade600],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.cloud,
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
                                  'Route ID: $routeId',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${route['province']}, ${route['city']}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.green),
                            onPressed: () => _editAndOpenEditor(route),
                            tooltip: 'Edit & Repost',
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${segments.length} seg',
                              style: TextStyle(
                                color: Colors.purple.shade700,
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
                                    route['start_name'] ?? 'Start',
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
                                    route['end_name'] ?? 'End',
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
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(
                            Icons.straighten,
                            '${route['total_distance']} km',
                            Colors.blue,
                          ),
                          _buildInfoChip(
                            Icons.access_time,
                            route['total_duration'],
                            Colors.orange,
                          ),
                          _buildInfoChip(
                            Icons.calendar_today,
                            route['date'],
                            Colors.purple,
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.all(8),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: List.generate(segments.length, (segmentIndex) {
                            final segment = segments[segmentIndex];
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'S${segment['sr_no']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '${segment['segment_distance']} km',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
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