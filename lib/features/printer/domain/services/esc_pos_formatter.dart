import 'dart:convert';
import 'dart:typed_data';

import '../../../ticketing/domain/models/ticket_receipt.dart';

class EscPosFormatter {
  static const List<int> escInit = [0x1B, 0x40];
  static const List<int> alignCenter = [0x1B, 0x61, 0x01];
  static const List<int> alignLeft = [0x1B, 0x61, 0x00];
  static const List<int> alignRight = [0x1B, 0x61, 0x02];
  static const List<int> boldOn = [0x1B, 0x45, 0x01];
  static const List<int> boldOff = [0x1B, 0x45, 0x00];
  static const List<int> feedAndCut = [0x1D, 0x56, 0x42, 0x03];
  static const List<int> lineFeed = [0x0A];

  Uint8List formatReceipt(TicketReceipt receipt) {
    final builder = BytesBuilder();

    // 1. Initialize
    builder.add(escInit);

    // 2. Header (Centered, Bold)
    builder.add(alignCenter);
    builder.add(boldOn);
    builder.add(utf8.encode('NAMMAROUTE E-TICKET\n'));
    builder.add(utf8.encode('KSRTC RURAL DIVISION\n'));
    builder.add(boldOff);
    builder.add(utf8.encode('--------------------------------\n'));

    // 3. Ticket Info (Left Aligned)
    builder.add(alignLeft);
    builder.add(utf8.encode('TICKET NO: ${receipt.ticketNumber}\n'));
    builder.add(
      utf8.encode('DATE/TIME: ${receipt.issuedAt.toIso8601String()}\n'),
    );
    builder.add(utf8.encode('ROUTE    : ${receipt.routeName}\n'));
    builder.add(utf8.encode('BUS ID   : ${receipt.busId}\n'));
    builder.add(utf8.encode('--------------------------------\n'));

    // 4. Journey Details
    builder.add(utf8.encode('FROM    : ${receipt.sourceStopName}\n'));
    builder.add(utf8.encode('TO      : ${receipt.destStopName}\n'));
    builder.add(
      utf8.encode('CATEGORY: ${receipt.passengerCategory.toUpperCase()}\n'),
    );
    builder.add(utf8.encode('--------------------------------\n'));

    // 5. Fare Amount (Right Aligned, Bold)
    builder.add(alignRight);
    builder.add(boldOn);
    builder.add(
      utf8.encode('TOTAL FARE: Rs. ${receipt.fareAmount.toStringAsFixed(2)}\n'),
    );
    builder.add(boldOff);

    // 6. Security QR Payload String
    builder.add(alignCenter);
    builder.add(lineFeed);
    builder.add(utf8.encode('QR: ${receipt.qrPayload}\n'));
    builder.add(lineFeed);

    // 7. Footer
    builder.add(utf8.encode('Thank You! Safe Journey\n'));
    builder.add(utf8.encode('--------------------------------\n'));

    // 8. Cut Command
    builder.add(feedAndCut);

    return builder.toBytes();
  }
}
