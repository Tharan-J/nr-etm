import 'dart:typed_data';

class TicketReceipt {
  final String ticketNumber;
  final String routeName;
  final String busId;
  final String sourceStopName;
  final String destStopName;
  final double fareAmount;
  final String passengerCategory;
  final DateTime issuedAt;
  final String qrPayload;
  final String formattedPlainText;
  final Uint8List? thermalPrinterBytes;

  const TicketReceipt({
    required this.ticketNumber,
    required this.routeName,
    required this.busId,
    required this.sourceStopName,
    required this.destStopName,
    required this.fareAmount,
    required this.passengerCategory,
    required this.issuedAt,
    required this.qrPayload,
    required this.formattedPlainText,
    this.thermalPrinterBytes,
  });
}
