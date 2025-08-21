import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';

class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository(this._apiClient);

  Future<User> getUserProfile() async {
    try {
      final response = await _apiClient.getUserProfile();
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  Future<User> updateUserProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      // First get current profile
      final currentProfile = await getUserProfile();
      
      // Create updated user object
      final updatedUser = User(
        id: currentProfile.id,
        phone: currentProfile.phone,
        displayName: displayName ?? currentProfile.displayName,
        avatarUrl: avatarUrl ?? currentProfile.avatarUrl,
        role: currentProfile.role,
        createdAt: currentProfile.createdAt,
        lastLoginAt: DateTime.now(),
      );
      
      final response = await _apiClient.updateUserProfile(updatedUser);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  Exception _handleError(DioException e) {
    switch (e.response?.statusCode) {
      case 400:
        return Exception('Invalid request: ${e.response?.data?['message'] ?? 'Bad request'}');
      case 401:
        return Exception('Unauthorized: ${e.response?.data?['message'] ?? 'Please login again'}');
      case 403:
        return Exception('Forbidden: ${e.response?.data?['message'] ?? 'Access denied'}');
      case 404:
        return Exception('Not found: ${e.response?.data?['message'] ?? 'Profile not found'}');
      case 500:
        return Exception('Server error: ${e.response?.data?['message'] ?? 'Internal server error'}');
      default:
        return Exception('Network error: ${e.message}');
    }
  }
}
