import 'dart:async';
import 'dart:typed_data';

import '../../../ticketing/domain/models/ticket_receipt.dart';
import '../models/printer_status.dart';
import 'esc_pos_formatter.dart';

abstract class PrinterTransportAdapter {
  Future<bool> connect();
  Future<void> disconnect();
  Future<bool> sendBytes(Uint8List bytes);
  bool get isConnected;
}

class MockPrinterTransportAdapter implements PrinterTransportAdapter {
  bool _connected = false;
  final List<Uint8List> sentByteBuffers = [];

  @override
  bool get isConnected => _connected;

  @override
  Future<bool> connect() async {
    _connected = true;
    return true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
  }

  @override
  Future<bool> sendBytes(Uint8List bytes) async {
    if (!_connected) return false;
    sentByteBuffers.add(bytes);
    return true;
  }
}

class PrinterManager {
  final PrinterTransportAdapter transport;
  final EscPosFormatter formatter;
  PrinterStatus _status = PrinterStatus.initial();

  PrinterStatus get status => _status;

  PrinterManager({required this.transport, required this.formatter});

  Future<bool> connect() async {
    _status = PrinterStatus(
      state: PrinterState.connecting,
      isConnected: false,
      paperAvailable: true,
      batteryPct: _status.batteryPct,
    );

    final success = await transport.connect();

    if (success) {
      _status = const PrinterStatus(
        state: PrinterState.ready,
        isConnected: true,
        paperAvailable: true,
        batteryPct: 95,
      );
    } else {
      _status = PrinterStatus(
        state: PrinterState.error,
        isConnected: false,
        paperAvailable: true,
        batteryPct: _status.batteryPct,
        lastError: 'Bluetooth/USB connection failed',
      );
    }

    return success;
  }

  Future<bool> printTicketReceipt(TicketReceipt receipt) async {
    if (!transport.isConnected) {
      final reconnected = await connect();
      if (!reconnected) return false;
    }

    _status = PrinterStatus(
      state: PrinterState.printing,
      isConnected: true,
      paperAvailable: true,
      batteryPct: _status.batteryPct,
    );

    try {
      final escPosBytes = formatter.formatReceipt(receipt);
      final success = await transport.sendBytes(escPosBytes);

      _status = PrinterStatus(
        state: success ? PrinterState.ready : PrinterState.error,
        isConnected: transport.isConnected,
        paperAvailable: true,
        batteryPct: _status.batteryPct - 1,
        lastPrintTime: DateTime.now(),
        lastPrintResult: success,
        lastError: success ? null : 'Failed to transmit ESC/POS bytes',
      );

      return success;
    } catch (e) {
      _status = PrinterStatus(
        state: PrinterState.error,
        isConnected: transport.isConnected,
        paperAvailable: true,
        batteryPct: _status.batteryPct,
        lastPrintTime: DateTime.now(),
        lastPrintResult: false,
        lastError: e.toString(),
      );
      return false;
    }
  }

  Future<void> disconnect() async {
    await transport.disconnect();
    _status = PrinterStatus.initial();
  }
}
