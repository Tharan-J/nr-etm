import 'package:dio/dio.dart';
import '../../domain/models/pairing_request.dart';

abstract class AuthRemoteDataSource {
  Future<PairingResponse> pairDevice(PairingRequest request);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.nammaroute.com',
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  @override
  Future<PairingResponse> pairDevice(PairingRequest request) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/pair',
        data: request.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        return PairingResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Pairing failed with status: ${response.statusCode}',
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Unexpected pairing error: $e');
    }
  }
}
