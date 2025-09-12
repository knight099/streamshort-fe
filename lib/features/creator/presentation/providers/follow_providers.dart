import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/creator_repository.dart';
import '../../data/models/follow_models.dart';
import '../../data/providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

// Follow state
sealed class FollowState {
  const FollowState();
}

class FollowInitial extends FollowState {
  const FollowInitial();
}

class FollowLoading extends FollowState {
  const FollowLoading();
}

class FollowSuccess extends FollowState {
  final String status;
  const FollowSuccess(this.status);
}

class FollowError extends FollowState {
  final String message;
  const FollowError(this.message);
}

// Following list state
sealed class FollowingListState {
  const FollowingListState();
}

class FollowingListInitial extends FollowingListState {
  const FollowingListInitial();
}

class FollowingListLoading extends FollowingListState {
  const FollowingListLoading();
}

class FollowingListLoaded extends FollowingListState {
  final List<FollowedCreator> creators;
  final int total;
  final bool hasMore;
  const FollowingListLoaded({
    required this.creators,
    required this.total,
    required this.hasMore,
  });
}

class FollowingListError extends FollowingListState {
  final String message;
  const FollowingListError(this.message);
}

// Follow notifier
class FollowNotifier extends StateNotifier<FollowState> {
  final CreatorRepository _creatorRepository;
  final Ref _ref;

  FollowNotifier(this._creatorRepository, this._ref) : super(const FollowInitial());

  Future<void> followCreator(String creatorId) async {
    try {
      state = const FollowLoading();
      final accessToken = _ref.read(accessTokenProvider);
      
      if (accessToken == null) {
        state = const FollowError('Please login to follow creators');
        return;
      }

      final response = await _creatorRepository.followCreator(
        creatorId: creatorId,
        accessToken: accessToken,
      );
      
      state = FollowSuccess(response.status);
    } catch (e) {
      state = FollowError(e.toString());
    }
  }

  Future<void> unfollowCreator(String creatorId) async {
    try {
      state = const FollowLoading();
      final accessToken = _ref.read(accessTokenProvider);
      
      if (accessToken == null) {
        state = const FollowError('Please login to unfollow creators');
        return;
      }

      final response = await _creatorRepository.unfollowCreator(
        creatorId: creatorId,
        accessToken: accessToken,
      );
      
      state = FollowSuccess(response.status);
    } catch (e) {
      state = FollowError(e.toString());
    }
  }

  Future<bool> checkFollowing(String creatorId) async {
    try {
      final accessToken = _ref.read(accessTokenProvider);
      
      if (accessToken == null) {
        return false;
      }

      final response = await _creatorRepository.checkFollowing(
        creatorId: creatorId,
        accessToken: accessToken,
      );
      
      return response.following;
    } catch (e) {
      return false;
    }
  }

  void clearError() {
    if (state is FollowError) {
      state = const FollowInitial();
    }
  }
}

// Following list notifier
class FollowingListNotifier extends StateNotifier<FollowingListState> {
  final CreatorRepository _creatorRepository;
  final Ref _ref;

  FollowingListNotifier(this._creatorRepository, this._ref) : super(const FollowingListInitial());

  Future<void> loadFollowingList({bool refresh = false}) async {
    try {
      if (refresh) {
        state = const FollowingListLoading();
      } else if (state is FollowingListLoaded) {
        final currentState = state as FollowingListLoaded;
        if (!currentState.hasMore) return;
      } else {
        state = const FollowingListLoading();
      }

      final accessToken = _ref.read(accessTokenProvider);
      
      if (accessToken == null) {
        state = const FollowingListError('Please login to view following list');
        return;
      }

      final currentState = state is FollowingListLoaded ? state as FollowingListLoaded : null;
      final page = currentState != null ? (currentState.creators.length ~/ 20) + 1 : 1;

      final response = await _creatorRepository.getFollowingList(
        page: page,
        limit: 20,
        accessToken: accessToken,
      );

      final creators = currentState != null && !refresh 
          ? [...currentState.creators, ...response.items]
          : response.items;

      state = FollowingListLoaded(
        creators: creators,
        total: response.total,
        hasMore: creators.length < response.total,
      );
    } catch (e) {
      state = FollowingListError(e.toString());
    }
  }

  Future<void> unfollowCreator(String creatorId) async {
    try {
      final accessToken = _ref.read(accessTokenProvider);
      
      if (accessToken == null) {
        return;
      }

      await _creatorRepository.unfollowCreator(
        creatorId: creatorId,
        accessToken: accessToken,
      );

      // Update local state
      if (state is FollowingListLoaded) {
        final currentState = state as FollowingListLoaded;
        final updatedCreators = currentState.creators
            .where((creator) => creator.id != creatorId)
            .toList();
        
        state = FollowingListLoaded(
          creators: updatedCreators,
          total: currentState.total - 1,
          hasMore: currentState.hasMore,
        );
      }
    } catch (e) {
      // Handle error silently or show toast
    }
  }

  void clearError() {
    if (state is FollowingListError) {
      state = const FollowingListInitial();
    }
  }
}

// Providers
final followNotifierProvider = StateNotifierProvider<FollowNotifier, FollowState>((ref) {
  final creatorRepository = ref.watch(creatorRepositoryProvider);
  return FollowNotifier(creatorRepository, ref);
});

final followingListNotifierProvider = StateNotifierProvider<FollowingListNotifier, FollowingListState>((ref) {
  final creatorRepository = ref.watch(creatorRepositoryProvider);
  return FollowingListNotifier(creatorRepository, ref);
});

// Helper providers
final followingListProvider = Provider<List<FollowedCreator>>((ref) {
  final state = ref.watch(followingListNotifierProvider);
  if (state is FollowingListLoaded) {
    return state.creators;
  }
  return [];
});

final hasMoreFollowingProvider = Provider<bool>((ref) {
  final state = ref.watch(followingListNotifierProvider);
  if (state is FollowingListLoaded) {
    return state.hasMore;
  }
  return false;
});

final followingListLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(followingListNotifierProvider);
  return state is FollowingListLoading;
});

final followingListErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(followingListNotifierProvider);
  if (state is FollowingListError) {
    return state.message;
  }
  return null;
});
