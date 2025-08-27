import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:streamshort/core/api/api_client.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/providers.dart';

// Content state
abstract class ContentState {}

class ContentInitial extends ContentState {}

class ContentLoading extends ContentState {}

class ContentLoaded extends ContentState {
  final List<Series> series;
  final bool hasMore;
  final int page;

  ContentLoaded({
    required this.series,
    required this.hasMore,
    required this.page,
  });
}

class ContentError extends ContentState {
  final String message;

  ContentError(this.message);
}

// Content notifier
class ContentNotifier extends StateNotifier<ContentState> {
  final ContentRepository _repository;

  ContentNotifier(this._repository) : super(ContentInitial());

  Future<void> loadSeries({
    String? category,
    String? language,
    bool? includeAdultContent,
    bool refresh = false,
  }) async {
    try {
      if (refresh || state is ContentInitial) {
        state = ContentLoading();
      }

      final response = await _repository.getPublishedSeries(
        page: 1,
        limit: 20,
        includeAdultContent: includeAdultContent,
      );

      state = ContentLoaded(
        series: response.items,
        hasMore: response.total == null || response.items.length < (response.total ?? 0),
        page: 1,
      );
    } catch (e) {
      state = ContentError(e.toString());
    }
  }

  Future<void> loadMoreSeries({
    String? category,
    String? language,
    bool? includeAdultContent,
  }) async {
    if (state is! ContentLoaded) return;

    final currentState = state as ContentLoaded;
    if (!currentState.hasMore) return;

    try {
      final nextPage = currentState.page + 1;
      final response = await _repository.getPublishedSeries(
        page: nextPage,
        limit: 20,
        includeAdultContent: includeAdultContent,
      );

      state = ContentLoaded(
        series: [...currentState.series, ...response.items],
        hasMore: response.total == null || response.items.length < (response.total ?? 0),
        page: nextPage,
      );
    } catch (e) {
      state = ContentError(e.toString());
    }
  }

  Future<void> refreshContent() async {
    await loadSeries(refresh: true);
  }

  Future<void> searchSeries(String query) async {
    try {
      state = ContentLoading();
      // TODO: Implement search
      state = ContentLoaded(
        series: [],
        hasMore: false,
        page: 1,
      );
    } catch (e) {
      state = ContentError(e.toString());
    }
  }

  void clearError() {
    state = ContentInitial();
  }
}

// Providers
final contentNotifierProvider = StateNotifierProvider<ContentNotifier, ContentState>((ref) {
  final repository = ref.watch(contentRepositoryProvider);
  return ContentNotifier(repository);
});

final seriesListProvider = Provider<List<Series>>((ref) {
  final contentState = ref.watch(contentNotifierProvider);
  if (contentState is ContentLoaded) {
    return contentState.series;
  }
  return [];
});

final hasMoreContentProvider = Provider<bool>((ref) {
  final contentState = ref.watch(contentNotifierProvider);
  if (contentState is ContentLoaded) {
    return contentState.hasMore;
  }
  return false;
});

final contentLoadingProvider = Provider<bool>((ref) {
  final contentState = ref.watch(contentNotifierProvider);
  return contentState is ContentLoading;
});

// Adult content filter provider
final adultContentFilterProvider = StateProvider<bool>((ref) => false);