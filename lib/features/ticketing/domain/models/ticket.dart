class Ticket {
  final String ticketId;
  final String ticketNumber;
  final String tripId;
  final String dutyId;
  final String sourceStopId;
  final String destStopId;
  final String sourceStopName;
  final String destStopName;
  final int sourceStage;
  final int destStage;
  final double fareAmount;
  final String passengerCategory; // 'adult', 'child', 'senior', 'pass'
  final DateTime createdAt;
  final String qrPayload;

  const Ticket({
    required this.ticketId,
    required this.ticketNumber,
    required this.tripId,
    required this.dutyId,
    required this.sourceStopId,
    required this.destStopId,
    required this.sourceStopName,
    required this.destStopName,
    required this.sourceStage,
    required this.destStage,
    required this.fareAmount,
    required this.passengerCategory,
    required this.createdAt,
    required this.qrPayload,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      ticketId: json['ticket_id'] as String,
      ticketNumber: json['ticket_number'] as String,
      tripId: json['trip_id'] as String,
      dutyId: json['duty_id'] as String,
      sourceStopId: json['source_stop_id'] as String,
      destStopId: json['dest_stop_id'] as String,
      sourceStopName: json['source_stop_name'] as String? ?? '',
      destStopName: json['dest_stop_name'] as String? ?? '',
      sourceStage: json['source_stage'] as int,
      destStage: json['dest_stage'] as int,
      fareAmount: (json['fare_amount'] as num).toDouble(),
      passengerCategory: json['passenger_category'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      qrPayload: json['qr_payload'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticket_id': ticketId,
      'ticket_number': ticketNumber,
      'trip_id': tripId,
      'duty_id': dutyId,
      'source_stop_id': sourceStopId,
      'dest_stop_id': destStopId,
      'source_stop_name': sourceStopName,
      'dest_stop_name': destStopName,
      'source_stage': sourceStage,
      'dest_stage': destStage,
      'fare_amount': fareAmount,
      'passenger_category': passengerCategory,
      'created_at': createdAt.toIso8601String(),
      'qr_payload': qrPayload,
    };
  }
}
