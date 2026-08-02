import 'package:flutter_test/flutter_test.dart';
import 'package:nr_etm/features/printer/domain/models/printer_status.dart';
import 'package:nr_etm/features/printer/domain/services/esc_pos_formatter.dart';
import 'package:nr_etm/features/printer/domain/services/printer_manager.dart';
import 'package:nr_etm/features/ticketing/domain/models/ticket_receipt.dart';

void main() {
  late EscPosFormatter formatter;
  late MockPrinterTransportAdapter mockTransport;
  late PrinterManager printerManager;

  setUp(() {
    formatter = EscPosFormatter();
    mockTransport = MockPrinterTransportAdapter();
    printerManager = PrinterManager(
      transport: mockTransport,
      formatter: formatter,
    );
  });

  final testReceipt = TicketReceipt(
    ticketNumber: 'TKT_10029',
    routeName: '335E',
    busId: 'KA-01-F-1234',
    sourceStopName: 'Majestic',
    destStopName: 'ITPL',
    fareAmount: 40.0,
    passengerCategory: 'adult',
    issuedAt: DateTime.parse('2026-08-02T10:00:00Z'),
    qrPayload: 'NR:TKT:TKT_10029:4000',
    formattedPlainText: 'Sample Plain Text',
  );

  group('Phase 12 — ESC/POS Formatter & Printer Manager Tests', () {
    test(
      'EscPosFormatter generates valid ESC/POS byte commands and layout',
      () {
        final bytes = formatter.formatReceipt(testReceipt);

        expect(bytes, isNotEmpty);
        // Hardware Initialize command [0x1B, 0x40]
        expect(bytes[0], equals(0x1B));
        expect(bytes[1], equals(0x40));

        // Cut Command [0x1D, 0x56, 0x42, 0x03] at end
        final len = bytes.length;
        expect(bytes[len - 4], equals(0x1D));
        expect(bytes[len - 3], equals(0x56));
      },
    );

    test(
      'PrinterManager connects and transmits ESC/POS byte buffers to transport',
      () async {
        expect(printerManager.status.state, equals(PrinterState.disconnected));

        final connected = await printerManager.connect();
        expect(connected, isTrue);
        expect(printerManager.status.state, equals(PrinterState.ready));

        final success = await printerManager.printTicketReceipt(testReceipt);
        expect(success, isTrue);
        expect(mockTransport.sentByteBuffers.length, equals(1));
        expect(printerManager.status.lastPrintResult, isTrue);
      },
    );
  });
}
