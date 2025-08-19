import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:streamshort/features/engagement/data/models/engagement_models.dart';

final episodeLikesProvider = StateNotifierProvider.family<EpisodeLikesNotifier, AsyncValue<LikeResponse?>, String>((ref, episodeId) {
  return EpisodeLikesNotifier(episodeId);
});

final episodeRatingProvider = StateNotifierProvider.family<EpisodeRatingNotifier, AsyncValue<RatingResponse?>, String>((ref, episodeId) {
  return EpisodeRatingNotifier(episodeId);
});

final episodeCommentsProvider = StateNotifierProvider.family<EpisodeCommentsNotifier, AsyncValue<CommentListResponse?>, String>((ref, episodeId) {
  return EpisodeCommentsNotifier(episodeId);
});

class EpisodeLikesNotifier extends StateNotifier<AsyncValue<LikeResponse?>> {
  final String episodeId;

  EpisodeLikesNotifier(this.episodeId) : super(const AsyncValue.loading());

  Future<void> loadLikes() async {
    try {
      state = const AsyncValue.loading();
      // TODO: Implement API call to load episode likes
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> toggleLike() async {
    try {
      state = const AsyncValue.loading();
      // TODO: Implement API call to toggle like
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class EpisodeRatingNotifier extends StateNotifier<AsyncValue<RatingResponse?>> {
  final String episodeId;

  EpisodeRatingNotifier(this.episodeId) : super(const AsyncValue.loading());

  Future<void> loadRating() async {
    try {
      state = const AsyncValue.loading();
      // TODO: Implement API call to load episode rating
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> submitRating(int score) async {
    try {
      state = const AsyncValue.loading();
      // TODO: Implement API call to submit rating
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class EpisodeCommentsNotifier extends StateNotifier<AsyncValue<CommentListResponse?>> {
  final String episodeId;

  EpisodeCommentsNotifier(this.episodeId) : super(const AsyncValue.loading());

  Future<void> loadComments({int page = 1}) async {
    try {
      state = const AsyncValue.loading();
      // TODO: Implement API call to load episode comments
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> postComment(String text) async {
    try {
      state = const AsyncValue.loading();
      // TODO: Implement API call to post comment
      await loadComments();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
