enum TripStatus { idle, active, paused, completed }

enum TripDirection { up, down }

class BusTrip {
  final String tripId;
  final String dutyId;
  final String routeId;
  final String routeName;
  final TripDirection direction;
  final int currentStage;
  final int totalTicketsIssued;
  final double totalRevenueCollected;
  final DateTime startTime;
  final DateTime? endTime;
  final TripStatus status;

  const BusTrip({
    required this.tripId,
    required this.dutyId,
    required this.routeId,
    required this.routeName,
    required this.direction,
    required this.currentStage,
    this.totalTicketsIssued = 0,
    this.totalRevenueCollected = 0.0,
    required this.startTime,
    this.endTime,
    required this.status,
  });

  bool get isActive => status == TripStatus.active;

  BusTrip copyWith({
    String? tripId,
    String? dutyId,
    String? routeId,
    String? routeName,
    TripDirection? direction,
    int? currentStage,
    int? totalTicketsIssued,
    double? totalRevenueCollected,
    DateTime? startTime,
    DateTime? endTime,
    TripStatus? status,
  }) {
    return BusTrip(
      tripId: tripId ?? this.tripId,
      dutyId: dutyId ?? this.dutyId,
      routeId: routeId ?? this.routeId,
      routeName: routeName ?? this.routeName,
      direction: direction ?? this.direction,
      currentStage: currentStage ?? this.currentStage,
      totalTicketsIssued: totalTicketsIssued ?? this.totalTicketsIssued,
      totalRevenueCollected:
          totalRevenueCollected ?? this.totalRevenueCollected,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
    );
  }

  factory BusTrip.fromJson(Map<String, dynamic> json) {
    return BusTrip(
      tripId: json['trip_id'] as String,
      dutyId: json['duty_id'] as String,
      routeId: json['route_id'] as String,
      routeName: json['route_name'] as String,
      direction: TripDirection.values.byName(
        json['direction'] as String? ?? 'up',
      ),
      currentStage: json['current_stage'] as int? ?? 1,
      totalTicketsIssued: json['total_tickets_issued'] as int? ?? 0,
      totalRevenueCollected: (json['total_revenue_collected'] as num? ?? 0)
          .toDouble(),
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      status: TripStatus.values.byName(json['status'] as String? ?? 'idle'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'duty_id': dutyId,
      'route_id': routeId,
      'route_name': routeName,
      'direction': direction.name,
      'current_stage': currentStage,
      'total_tickets_issued': totalTicketsIssued,
      'total_revenue_collected': totalRevenueCollected,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'status': status.name,
    };
  }
}
