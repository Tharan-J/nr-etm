import 'package:flutter/services.dart';

abstract class BackgroundService {
  Future<bool> startForegroundService();
  Future<bool> stopForegroundService();
  Future<bool> isServiceRunning();
}

class AndroidBackgroundService implements BackgroundService {
  static const MethodChannel _methodChannel = MethodChannel(
    'com.nammaroute.etm/background_service',
  );

  @override
  Future<bool> startForegroundService() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'startForegroundService',
      );
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  @override
  Future<bool> stopForegroundService() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'stopForegroundService',
      );
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isServiceRunning() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'isServiceRunning',
      );
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }
}
