import 'package:flutter/services.dart';
import 'models/location_event.dart';

abstract class LocationService {
  Stream<LocationEvent> get locationStream;
}

class AndroidLocationService implements LocationService {
  static const EventChannel _eventChannel = EventChannel(
    'com.nammaroute.etm/location_stream',
  );

  @override
  Stream<LocationEvent> get locationStream {
    return _eventChannel.receiveBroadcastStream().map((dynamic event) {
      if (event is Map) {
        return LocationEvent.fromMap(event);
      }
      throw Exception('Invalid location event format');
    });
  }
}
