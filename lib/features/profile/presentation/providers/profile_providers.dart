import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:streamshort/features/auth/data/models/auth_models.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<User?>>((ref) {
  return ProfileNotifier();
});

class ProfileNotifier extends StateNotifier<AsyncValue<User?>> {
  ProfileNotifier() : super(const AsyncValue.loading());

  Future<void> loadProfile() async {
    try {
      state = const AsyncValue.loading();
      // TODO: Implement profile loading from API
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      state = const AsyncValue.loading();
      // TODO: Implement profile update API call
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
