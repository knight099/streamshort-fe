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
      // Normalize phone same as sendOtp: digits + country code (+91 default)
      final digitsOnly = phone.replaceAll(RegExp(r'[^0-9+]'), '');
      final normalizedPhone = digitsOnly.startsWith('+') ? digitsOnly : '+91$digitsOnly';
      // Use Dio directly to handle snake_case response keys
      final resp = await _dio.post('auth/otp/verify', data: {
        'phone': normalizedPhone,
        'otp': otp,
      });
      if (resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
        final data = resp.data is Map ? Map<String, dynamic>.from(resp.data as Map) : <String, dynamic>{};
        final accessToken = (data['access_token'] ?? data['accessToken'] ?? '').toString();
        final refreshToken = (data['refresh_token'] ?? data['refreshToken'] ?? '').toString();
        if (accessToken.isNotEmpty) {
          _dio.options.headers['Authorization'] = 'Bearer $accessToken';
        }
        // Build a minimal user; real profile can be fetched later
        final user = User(
          id: data['user'] is Map && (data['user']['id']?.toString().isNotEmpty ?? false) ? data['user']['id'].toString() : '',
          phone: normalizedPhone,
          displayName: null,
          avatarUrl: null,
          role: 'user',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        return TokenResponse(accessToken: accessToken, refreshToken: refreshToken, user: user);
      }
      throw Exception('Failed to verify OTP: ${resp.statusCode}');
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
      // Update Dio Authorization header
      if (response.accessToken.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer ${response.accessToken}';
      }
      
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

  Future<void> updateUserRole(String newRole) async {
    try {
      // This would typically call an API endpoint to update the user role
      // For now, we'll just update the local state
      // In a real app, you'd call something like:
      // await _dio.put('api/users/role', data: {'role': newRole});
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
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
