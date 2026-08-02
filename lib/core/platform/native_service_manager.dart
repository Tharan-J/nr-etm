import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'background_service.dart';
import 'location_service.dart';
import 'models/location_event.dart';
import 'power_service.dart';

final backgroundServiceProvider = Provider<BackgroundService>((ref) {
  return AndroidBackgroundService();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return AndroidLocationService();
});

final powerServiceProvider = Provider<PowerService>((ref) {
  return AndroidPowerService();
});

class NativeServiceManager {
  final BackgroundService backgroundService;
  final LocationService locationService;
  final PowerService powerService;

  NativeServiceManager({
    required this.backgroundService,
    required this.locationService,
    required this.powerService,
  });

  Future<bool> startDutyForegroundService() async {
    return backgroundService.startForegroundService();
  }

  Future<bool> stopDutyForegroundService() async {
    return backgroundService.stopForegroundService();
  }

  Stream<LocationEvent> get locationStream => locationService.locationStream;

  Future<bool> checkBatteryOptimizations() async {
    return powerService.isBatteryOptimizationIgnored();
  }
}

final nativeServiceManagerProvider = Provider<NativeServiceManager>((ref) {
  return NativeServiceManager(
    backgroundService: ref.watch(backgroundServiceProvider),
    locationService: ref.watch(locationServiceProvider),
    powerService: ref.watch(powerServiceProvider),
  );
});
