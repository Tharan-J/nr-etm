import '../../features/telemetry/domain/services/telemetry_engine.dart';
import 'sync_engine.dart';

enum BackpressureState { normal, throttled, critical }

class BackpressureManager {
  final SyncEngine syncEngine;
  final TelemetryEngine telemetryEngine;

  BackpressureState _state = BackpressureState.normal;

  BackpressureState get state => _state;

  BackpressureManager({
    required this.syncEngine,
    required this.telemetryEngine,
  });

  Future<void> evaluateQueueBackpressure() async {
    final count = await syncEngine.getPendingQueueCount();

    if (count > 2000) {
      _state = BackpressureState.critical;
      telemetryEngine.setSamplingInterval(
        60,
      ); // 60s sampling under critical load
    } else if (count > 500) {
      _state = BackpressureState.throttled;
      telemetryEngine.setSamplingInterval(30); // 30s sampling under high queue
    } else {
      _state = BackpressureState.normal;
      telemetryEngine.setSamplingInterval(5); // 5s normal sampling
    }
  }
}
