import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/network/dio_client.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    int? expiresInMins,
  });

  Future<Map<String, dynamic>> getCurrentUser();

  Future<Map<String, dynamic>> refreshToken(String refreshToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    int? expiresInMins = 60,
  }) async {
    try {
      final response = await dioClient.post(
        ApiConstants.authLogin,
        data: {
          'username': username.trim(),
          'password': password.trim(),
          'expiresInMins': ?expiresInMins,
        },
      );

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw const ApiException('Invalid response received from authentication server');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await dioClient.get(ApiConstants.authMe);
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw const ApiException('Failed to retrieve user profile');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await dioClient.post(
        ApiConstants.authRefresh,
        data: {
          'refreshToken': refreshToken,
          'expiresInMins': 60,
        },
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw const ApiException('Failed to refresh authentication token');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}