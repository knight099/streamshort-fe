import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:streamshort/features/creator/data/models/creator_models.dart';
import 'package:streamshort/features/creator/data/repositories/creator_repository.dart';
import 'package:streamshort/core/providers.dart';

final creatorProfileProvider = StateNotifierProvider<CreatorProfileNotifier, AsyncValue<CreatorProfile?>>((ref) {
  return CreatorProfileNotifier();
});

final creatorDashboardProvider = StateNotifierProvider<CreatorDashboardNotifier, AsyncValue<CreatorDashboardResponse?>>((ref) {
  return CreatorDashboardNotifier();
});

final creatorRepositoryProvider = Provider<CreatorRepository>((ref) {
  return CreatorRepository(ref.read(apiClientProvider), ref.read(dioProvider));
});

class CreatorProfileNotifier extends StateNotifier<AsyncValue<CreatorProfile?>> {
  CreatorProfileNotifier() : super(const AsyncValue.loading());

  Future<void> loadProfile() async {
    try {
      state = const AsyncValue.loading();
      // TODO: Implement API call to load creator profile
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> onboardCreator({
    required String displayName,
    String? bio,
    required String kycDocumentS3Path,
  }) async {
    try {
      state = const AsyncValue.loading();
      // TODO: Implement creator onboarding API call
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
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

class CreatorDashboardNotifier extends StateNotifier<AsyncValue<CreatorDashboardResponse?>> {
  CreatorDashboardNotifier() : super(const AsyncValue.loading());

  Future<void> loadDashboard() async {
    try {
      state = const AsyncValue.loading();
      // TODO: Implement API call to load creator dashboard data
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
