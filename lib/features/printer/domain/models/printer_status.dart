enum PrinterState { disconnected, connecting, ready, printing, error }

class PrinterStatus {
  final PrinterState state;
  final bool isConnected;
  final bool paperAvailable;
  final int batteryPct;
  final DateTime? lastPrintTime;
  final bool? lastPrintResult;
  final String? lastError;

  const PrinterStatus({
    required this.state,
    required this.isConnected,
    required this.paperAvailable,
    required this.batteryPct,
    this.lastPrintTime,
    this.lastPrintResult,
    this.lastError,
  });

  factory PrinterStatus.initial() {
    return const PrinterStatus(
      state: PrinterState.disconnected,
      isConnected: false,
      paperAvailable: true,
      batteryPct: 100,
    );
  }
}
