import 'dart:async';

import 'package:fixnum/fixnum.dart';

import '../../../../core/capture/data/app_database.dart';
import '../../../../core/capture/data/dao/durable_capture_dao.dart';
import '../../../../core/generated/proto/etm_telemetry.pb.dart';
import '../../../../core/platform/models/location_event.dart';

class TelemetryEngine {
  final DurableCaptureDao captureDao;
  StreamSubscription<LocationEvent>? _subscription;
  int _samplingIntervalSeconds = 5;

  int get samplingIntervalSeconds => _samplingIntervalSeconds;

  TelemetryEngine({required this.captureDao});

  void setSamplingInterval(int intervalSeconds) {
    _samplingIntervalSeconds = intervalSeconds;
  }

  void startTelemetryStream({
    required Stream<LocationEvent> locationStream,
    required String tripId,
    required String conductorId,
    required String deviceId,
  }) {
    _subscription?.cancel();
    _subscription = locationStream.listen((event) async {
      await processLocationPing(
        event: event,
        tripId: tripId,
        conductorId: conductorId,
        deviceId: deviceId,
      );
    });
  }

  Future<void> processLocationPing({
    required LocationEvent event,
    required String tripId,
    required String conductorId,
    required String deviceId,
    int batteryLevelPct = 100,
    bool isCharging = false,
  }) async {
    final nowMs = event.timestamp.millisecondsSinceEpoch;
    final pingId = 'ping_$nowMs';

    final companion = TelemetryTableCompanion.insert(
      pingId: pingId,
      deviceId: deviceId,
      latitude: event.latitude,
      longitude: event.longitude,
      speedMps: event.speed,
      headingDegrees: event.bearing,
      capturedAt: event.timestamp,
      batteryLevelPct: batteryLevelPct,
      isCharging: isCharging,
    );

    final protoRecord = TelemetryPingRecord()
      ..pingId = pingId
      ..deviceId = deviceId
      ..tripId = tripId
      ..latitude = event.latitude
      ..longitude = event.longitude
      ..speedMps = event.speed
      ..headingDegrees = event.bearing
      ..capturedAtEpochMs = Int64(nowMs);

    await captureDao.captureTelemetryTransaction(
      telemetryCompanion: companion,
      telemetryRecord: protoRecord,
    );
  }

  void stopTelemetryStream() {
    _subscription?.cancel();
    _subscription = null;
  }
}
