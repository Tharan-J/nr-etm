import 'dart:convert';
import 'dart:typed_data';

import '../models/ticket.dart';
import '../models/ticket_receipt.dart';

class ReceiptGenerator {
  TicketReceipt generateReceipt({
    required Ticket ticket,
    required String routeName,
    required String busId,
  }) {
    final qrPayload =
        'NR-ETM:${ticket.ticketId}:${ticket.tripId}:${ticket.fareAmount}:${ticket.createdAt.millisecondsSinceEpoch}';

    final textBuffer = StringBuffer()
      ..writeln('================================')
      ..writeln('        NAMMAROUTE ETM          ')
      ..writeln('================================')
      ..writeln('Ticket No : ${ticket.ticketNumber}')
      ..writeln('Bus ID    : $busId')
      ..writeln('Route     : $routeName')
      ..writeln(
        'From      : ${ticket.sourceStopName} (Stage ${ticket.sourceStage})',
      )
      ..writeln(
        'To        : ${ticket.destStopName} (Stage ${ticket.destStage})',
      )
      ..writeln('Category  : ${ticket.passengerCategory.toUpperCase()}')
      ..writeln('Fare      : Rs. ${ticket.fareAmount.toStringAsFixed(2)}')
      ..writeln(
        'Issued At : ${ticket.createdAt.toIso8601String().substring(0, 19)}',
      )
      ..writeln('================================')
      ..writeln('  Thank you for traveling!      ')
      ..writeln('================================');

    final plainText = textBuffer.toString();
    final thermalBytes = _formatEscPosBytes(plainText);

    return TicketReceipt(
      ticketNumber: ticket.ticketNumber,
      routeName: routeName,
      busId: busId,
      sourceStopName: ticket.sourceStopName,
      destStopName: ticket.destStopName,
      fareAmount: ticket.fareAmount,
      passengerCategory: ticket.passengerCategory,
      issuedAt: ticket.createdAt,
      qrPayload: qrPayload,
      formattedPlainText: plainText,
      thermalPrinterBytes: thermalBytes,
    );
  }

  Uint8List _formatEscPosBytes(String text) {
    final List<int> bytes = [];
    // ESC @ Initialize Printer
    bytes.addAll([0x1B, 0x40]);
    // Align Center
    bytes.addAll([0x1B, 0x61, 0x01]);
    bytes.addAll(utf8.encode(text));
    // Feed and cut line
    bytes.addAll([0x0A, 0x0A, 0x0A]);
    return Uint8List.fromList(bytes);
  }
}
