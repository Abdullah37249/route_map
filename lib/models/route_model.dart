class RouteModel {
  final int? id;
  final int routeId;
  final String startName;
  final String endName;
  final double totalDistance;
  final String totalDuration;
  final String province;
  final String city;
  final String date;
  final int segmentsCount;
  final List<Map<String, dynamic>> segments;

  RouteModel({
    this.id,
    required this.routeId,
    required this.startName,
    required this.endName,
    required this.totalDistance,
    required this.totalDuration,
    required this.province,
    required this.city,
    required this.date,
    required this.segmentsCount,
    required this.segments,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'route_id': routeId,
      'start_name': startName,
      'end_name': endName,
      'total_distance': totalDistance,
      'total_duration': totalDuration,
      'province': province,
      'city': city,
      'date': date,
      'segments_count': segmentsCount,
    };
  }

  static RouteModel fromMap(Map<String, dynamic> map) {
    return RouteModel(
      id: map['id'],
      routeId: map['route_id'],
      startName: map['start_name'] ?? '',
      endName: map['end_name'] ?? '',
      totalDistance: map['total_distance'] ?? 0.0,
      totalDuration: map['total_duration'] ?? '',
      province: map['province'] ?? 'Punjab',
      city: map['city'] ?? 'Sialkot',
      date: map['date'] ?? '',
      segmentsCount: map['segments_count'] ?? 0,
      segments: map['segments'] ?? [],
    );
  }
}