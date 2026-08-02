import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nr_etm/core/platform/background_service.dart';
import 'package:nr_etm/core/platform/location_service.dart';
import 'package:nr_etm/core/platform/models/location_event.dart';
import 'package:nr_etm/core/platform/native_service_manager.dart';
import 'package:nr_etm/core/platform/power_service.dart';

class MockBackgroundService extends Mock implements BackgroundService {}

class MockLocationService extends Mock implements LocationService {}

class MockPowerService extends Mock implements PowerService {}

void main() {
  late MockBackgroundService mockBackground;
  late MockLocationService mockLocation;
  late MockPowerService mockPower;
  late NativeServiceManager manager;

  setUp(() {
    mockBackground = MockBackgroundService();
    mockLocation = MockLocationService();
    mockPower = MockPowerService();

    manager = NativeServiceManager(
      backgroundService: mockBackground,
      locationService: mockLocation,
      powerService: mockPower,
    );
  });

  test(
    'startDutyForegroundService delegates cleanly to BackgroundService',
    () async {
      when(
        () => mockBackground.startForegroundService(),
      ).thenAnswer((_) async => true);

      final result = await manager.startDutyForegroundService();

      expect(result, isTrue);
      verify(() => mockBackground.startForegroundService()).called(1);
    },
  );

  test('LocationEvent parses map payload accurately', () {
    final now = DateTime.now();
    final event = LocationEvent.fromMap({
      'latitude': 12.9716,
      'longitude': 77.5946,
      'speed': 11.5,
      'bearing': 180.0,
      'accuracy': 5.0,
      'timestamp': now.millisecondsSinceEpoch,
    });

    expect(event.latitude, equals(12.9716));
    expect(event.longitude, equals(77.5946));
    expect(event.speed, equals(11.5));
    expect(event.bearing, equals(180.0));
    expect(event.accuracy, equals(5.0));
  });
}
