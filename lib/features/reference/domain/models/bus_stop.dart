class BusStop {
  final String stopId;
  final String name;
  final String code;
  final double latitude;
  final double longitude;
  final int stageNumber;

  const BusStop({
    required this.stopId,
    required this.name,
    required this.code,
    required this.latitude,
    required this.longitude,
    required this.stageNumber,
  });

  factory BusStop.fromJson(Map<String, dynamic> json) {
    return BusStop(
      stopId: json['stop_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      stageNumber: json['stage_number'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stop_id': stopId,
      'name': name,
      'code': code,
      'latitude': latitude,
      'longitude': longitude,
      'stage_number': stageNumber,
    };
  }
}
