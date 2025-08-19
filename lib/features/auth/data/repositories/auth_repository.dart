import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final Dio _dio;

  AuthRepository(this._apiClient, this._dio);

  Future<PhoneOtpSendResponse> sendOtp(String phone, {String countryCode = '+91'}) async {
    try {
      final digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
      final normalizedCountryCode = countryCode.startsWith('+') ? countryCode : '+$countryCode';
      final formattedPhone = '$normalizedCountryCode$digitsOnly';
      final request = PhoneOtpRequest(phone: formattedPhone);
      final response = await _apiClient.sendOtp(request);
      
      // Store request ID for verification
      // You can use shared preferences or secure storage here
      
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  Future<TokenResponse> verifyOtp(String phone, String otp, String requestId) async {
    try {
      final request = PhoneOtpVerifyRequest(
        phone: phone,
        otp: otp,
        // requestId: requestId,
      );
      final response = await _apiClient.verifyOtp(request);
      
      // Store tokens securely
      // You can use secure storage here
      
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
    }
  }

  Future<TokenResponse> refreshToken(String refreshToken) async {
    try {
      final request = RefreshRequest(refreshToken: refreshToken);
      final response = await _apiClient.refreshToken(request);
      
      // Update stored tokens
      
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to refresh token: $e');
    }
  }

  Future<void> logout() async {
    // Clear stored tokens
    // You can use secure storage here
  }

  Exception _handleError(DioException e) {
    switch (e.response?.statusCode) {
      case 400:
        return Exception('Invalid request: ${e.response?.data?['message'] ?? 'Bad request'}');
      case 401:
        return Exception('Unauthorized: ${e.response?.data?['message'] ?? 'Invalid credentials'}');
      case 403:
        return Exception('Forbidden: ${e.response?.data?['message'] ?? 'Access denied'}');
      case 404:
        return Exception('Not found: ${e.response?.data?['message'] ?? 'Resource not found'}');
      case 429:
        return Exception('Too many requests: ${e.response?.data?['message'] ?? 'Rate limit exceeded'}');
      case 500:
        return Exception('Server error: ${e.response?.data?['message'] ?? 'Internal server error'}');
      default:
        return Exception('Network error: ${e.message}');
    }
  }
}
