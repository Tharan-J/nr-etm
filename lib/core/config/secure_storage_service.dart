import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure Storage Service for managing encrypted device bearer credentials
/// and hardware-scoped secrets (Spec 07 §7.1).
class SecureStorageService {
  static const String _keyDeviceToken = 'etm_device_token';
  static const String _keyDeviceId = 'etm_device_id';
  static const String _keyDeviceSecret = 'etm_device_secret';
  static const String _keyRefreshToken = 'etm_refresh_token';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  Future<void> saveDeviceToken(String token) async {
    await _storage.write(key: _keyDeviceToken, value: token);
  }

  Future<String?> getDeviceToken() async {
    return _storage.read(key: _keyDeviceToken);
  }

  Future<void> saveDeviceId(String deviceId) async {
    await _storage.write(key: _keyDeviceId, value: deviceId);
  }

  Future<String?> getDeviceId() async {
    return _storage.read(key: _keyDeviceId);
  }

  Future<void> saveDeviceSecret(String secret) async {
    await _storage.write(key: _keyDeviceSecret, value: secret);
  }

  Future<String?> getDeviceSecret() async {
    return _storage.read(key: _keyDeviceSecret);
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _keyRefreshToken);
  }

  Future<void> clearAllCredentials() async {
    await _storage.delete(key: _keyDeviceToken);
    await _storage.delete(key: _keyDeviceId);
    await _storage.delete(key: _keyDeviceSecret);
    await _storage.delete(key: _keyRefreshToken);
  }
}
