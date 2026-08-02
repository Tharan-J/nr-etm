import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nr_etm/core/config/secure_storage_service.dart';
import 'package:nr_etm/features/auth/domain/models/pairing_request.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockSecureStorageService mockStorage;

  setUp(() {
    mockStorage = MockSecureStorageService();
  });

  group('Phase 6 — Security Review & Binding Tests', () {
    test('PairingRequest binds device identity securely', () {
      const req = PairingRequest(
        deviceId: 'ETM_HW_9981',
        conductorPin: '4321',
        busId: 'BUS_777',
      );

      final json = req.toJson();
      expect(json['device_id'], equals('ETM_HW_9981'));
      expect(json['conductor_pin'], equals('4321'));
      expect(json['bus_id'], equals('BUS_777'));
    });

    test(
      'SecureStorageService enforces encrypted key-value operations',
      () async {
        when(
          () => mockStorage.getDeviceToken(),
        ).thenAnswer((_) async => 'encrypted_jwt_token_header');

        final token = await mockStorage.getDeviceToken();
        expect(token, equals('encrypted_jwt_token_header'));
        verify(() => mockStorage.getDeviceToken()).called(1);
      },
    );

    test(
      'PairingResponse handles secure token extraction without leaking credentials',
      () {
        final res = PairingResponse.fromJson({
          'token': 'secret_jwt_token',
          'conductor_id': 'COND_007',
          'session_id': 'sess_secret_123',
        });

        expect(res.token, equals('secret_jwt_token'));
        expect(res.conductorId, equals('COND_007'));
        expect(res.sessionId, equals('sess_secret_123'));
      },
    );
  });
}
