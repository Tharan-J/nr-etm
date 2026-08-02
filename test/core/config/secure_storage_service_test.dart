import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nr_etm/core/config/secure_storage_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureStorageService service;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    service = SecureStorageService(storage: mockStorage);
  });

  test('saveDeviceToken writes token securely', () async {
    when(
      () => mockStorage.write(key: 'etm_device_token', value: 'token_xyz'),
    ).thenAnswer((_) async {});

    await service.saveDeviceToken('token_xyz');

    verify(
      () => mockStorage.write(key: 'etm_device_token', value: 'token_xyz'),
    ).called(1);
  });

  test('getDeviceToken reads stored token', () async {
    when(
      () => mockStorage.read(key: 'etm_device_token'),
    ).thenAnswer((_) async => 'token_xyz');

    final token = await service.getDeviceToken();

    expect(token, equals('token_xyz'));
    verify(() => mockStorage.read(key: 'etm_device_token')).called(1);
  });

  test('clearAllCredentials deletes all stored keys', () async {
    when(
      () => mockStorage.delete(key: any(named: 'key')),
    ).thenAnswer((_) async {});

    await service.clearAllCredentials();

    verify(() => mockStorage.delete(key: 'etm_device_token')).called(1);
    verify(() => mockStorage.delete(key: 'etm_device_id')).called(1);
    verify(() => mockStorage.delete(key: 'etm_device_secret')).called(1);
    verify(() => mockStorage.delete(key: 'etm_refresh_token')).called(1);
  });
}
