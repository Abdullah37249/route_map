class SegmentModel {
  final int? id;
  final int routeId;
  final int srNo;
  final String routeName; // Added
  final String startName;
  final double startLat;
  final double startLng;
  final String endName;
  final double endLat;
  final double endLng;
  final double segmentDistance;
  final String segmentDuration;
  final double totalDistance;
  final String totalDuration;
  final String province;
  final String city;
  final String date;

  SegmentModel({
    this.id,
    required this.routeId,
    required this.srNo,
    required this.routeName, // Added
    required this.startName,
    required this.startLat,
    required this.startLng,
    required this.endName,
    required this.endLat,
    required this.endLng,
    required this.segmentDistance,
    required this.segmentDuration,
    required this.totalDistance,
    required this.totalDuration,
    required this.province,
    required this.city,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'route_id': routeId,
      'sr_no': srNo,
      'route_name': routeName, // Added
      'start_name': startName,
      'start_lat': startLat,
      'start_lng': startLng,
      'end_name': endName,
      'end_lat': endLat,
      'end_lng': endLng,
      'segment_distance': segmentDistance,
      'segment_duration': segmentDuration,
      'total_distance': totalDistance,
      'total_duration': totalDuration,
      'province': province,
      'city': city,
      'date': date,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  static SegmentModel fromMap(Map<String, dynamic> map) {
    return SegmentModel(
      id: map['id'],
      routeId: map['route_id'] ?? 0,
      srNo: map['sr_no'] ?? 0,
      routeName: map['route_name'] ?? 'Unnamed Route', // Added
      startName: map['start_name'] ?? '',
      startLat: map['start_lat'] ?? 0.0,
      startLng: map['start_lng'] ?? 0.0,
      endName: map['end_name'] ?? '',
      endLat: map['end_lat'] ?? 0.0,
      endLng: map['end_lng'] ?? 0.0,
      segmentDistance: map['segment_distance'] ?? 0.0,
      segmentDuration: map['segment_duration'] ?? '',
      totalDistance: map['total_distance'] ?? 0.0,
      totalDuration: map['total_duration'] ?? '',
      province: map['province'] ?? 'Punjab',
      city: map['city'] ?? 'Sialkot',
      date: map['date'] ?? '',
    );
  }
}