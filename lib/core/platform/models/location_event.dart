class LocationEvent {
  final double latitude;
  final double longitude;
  final double speed; // in m/s
  final double bearing; // in degrees
  final double accuracy; // in meters
  final DateTime timestamp;

  const LocationEvent({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.bearing,
    required this.accuracy,
    required this.timestamp,
  });

  factory LocationEvent.fromMap(Map<dynamic, dynamic> map) {
    return LocationEvent(
      latitude: (map['latitude'] as num? ?? 0).toDouble(),
      longitude: (map['longitude'] as num? ?? 0).toDouble(),
      speed: (map['speed'] as num? ?? 0).toDouble(),
      bearing: (map['bearing'] as num? ?? 0).toDouble(),
      accuracy: (map['accuracy'] as num? ?? 0).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'bearing': bearing,
      'accuracy': accuracy,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
