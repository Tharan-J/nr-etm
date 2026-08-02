enum DutyStatus { inactive, active, ended }

class ConductorDuty {
  final String dutyId;
  final String conductorId;
  final String busId;
  final DateTime startTime;
  final DateTime? endTime;
  final DutyStatus status;

  const ConductorDuty({
    required this.dutyId,
    required this.conductorId,
    required this.busId,
    required this.startTime,
    this.endTime,
    required this.status,
  });

  bool get isActive => status == DutyStatus.active;

  ConductorDuty copyWith({
    String? dutyId,
    String? conductorId,
    String? busId,
    DateTime? startTime,
    DateTime? endTime,
    DutyStatus? status,
  }) {
    return ConductorDuty(
      dutyId: dutyId ?? this.dutyId,
      conductorId: conductorId ?? this.conductorId,
      busId: busId ?? this.busId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
    );
  }

  factory ConductorDuty.fromJson(Map<String, dynamic> json) {
    return ConductorDuty(
      dutyId: json['duty_id'] as String,
      conductorId: json['conductor_id'] as String,
      busId: json['bus_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      status: DutyStatus.values.byName(json['status'] as String? ?? 'inactive'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'duty_id': dutyId,
      'conductor_id': conductorId,
      'bus_id': busId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'status': status.name,
    };
  }
}
