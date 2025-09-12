import 'package:dio/dio.dart';
import '../../../../features/auth/data/models/auth_models.dart';
import '../../../../core/api/api_client.dart';

class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository(this._apiClient);

  Future<User> getUserProfile() async {
    try {
      final response = await _apiClient.getUserProfile();
      // Manually map UserProfileResponse to User
      return User(
        id: response.userId,
        phone: response.phone,
        role: 'user', // Default role
        createdAt: DateTime.now(), // Placeholder, ideally from token or response
        displayName: null,
        avatarUrl: null,
        lastLoginAt: null,
      );
    } on DioException catch (e) {
      throw Exception('Failed to fetch user profile: ${e.message}');
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
      throw Exception('Failed to update user profile: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }
}
