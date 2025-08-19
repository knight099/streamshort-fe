import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/content_repository.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/providers.dart';

// Content State
sealed class ContentState {
  const ContentState();
}

class ContentInitial extends ContentState {
  const ContentInitial();
}

class ContentLoading extends ContentState {
  const ContentLoading();
}

class ContentLoaded extends ContentState {
  final List<Series> series;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  const ContentLoaded({
    required this.series,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });
}

class ContentError extends ContentState {
  final String message;

  const ContentError(this.message);
}

// Content Notifier
class ContentNotifier extends StateNotifier<ContentState> {
  final ContentRepository _contentRepository;

  ContentNotifier(this._contentRepository) : super(const ContentInitial());

  Future<void> loadSeries({
    int page = 1,
    int limit = 20,
    String? category,
    String? language,
    String? search,
    bool refresh = false,
  }) async {
    try {
      if (refresh || page == 1) {
        state = const ContentLoading();
      }

      // Call the real API
      final response = await _contentRepository.getSeries(
        page: page,
        limit: limit,
        category: category,
        language: language,
        search: search,
      );

      state = ContentLoaded(
        series: response.series,
        total: response.total,
        page: page,
        limit: limit,
        hasMore: (page * limit) < response.total,
      );
    } catch (e) {
      // Fallback to mock data if API fails
      if (refresh || page == 1) {
        await _loadMockData();
      } else {
        state = ContentError(e.toString());
      }
    }
  }

  Future<void> _loadMockData() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      final mockSeries = [
        Series(
          id: 'series_1',
          title: 'Action Heroes',
          synopsis: 'Epic action series with amazing stunts and breathtaking sequences',
          category: 'Action',
          language: 'English',
          priceType: 'free',
          price: null,
          thumbnail: 'https://via.placeholder.com/300x200/FF4444/FFFFFF?text=Action+Heroes',
          banner: 'https://via.placeholder.com/800x400/FF4444/FFFFFF?text=Action+Heroes',
          creatorId: 'creator_1',
          episodeCount: 5,
          rating: 4.5,
          viewCount: 25000,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        ),
        Series(
          id: 'series_2',
          title: 'Comedy Central',
          synopsis: 'Hilarious comedy series that will make you laugh out loud',
          category: 'Comedy',
          language: 'English',
          priceType: 'premium',
          price: 9.99,
          thumbnail: 'https://via.placeholder.com/300x200/FFAA00/FFFFFF?text=Comedy+Central',
          banner: 'https://via.placeholder.com/800x400/FFAA00/FFFFFF?text=Comedy+Central',
          creatorId: 'creator_1',
          episodeCount: 3,
          rating: 4.2,
          viewCount: 15000,
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          updatedAt: DateTime.now(),
        ),
        Series(
          id: 'series_3',
          title: 'Drama Queens',
          synopsis: 'Intense drama series with compelling storylines',
          category: 'Drama',
          language: 'Hindi',
          priceType: 'free',
          price: null,
          thumbnail: 'https://via.placeholder.com/300x200/AA44FF/FFFFFF?text=Drama+Queens',
          banner: 'https://via.placeholder.com/800x400/AA44FF/FFFFFF?text=Drama+Queens',
          creatorId: 'creator_2',
          episodeCount: 8,
          rating: 4.7,
          viewCount: 32000,
          createdAt: DateTime.now().subtract(const Duration(days: 25)),
          updatedAt: DateTime.now(),
        ),
        Series(
          id: 'series_4',
          title: 'Horror Nights',
          synopsis: 'Spine-chilling horror series that will keep you on edge',
          category: 'Horror',
          language: 'English',
          priceType: 'premium',
          price: 12.99,
          thumbnail: 'https://via.placeholder.com/300x200/444444/FFFFFF?text=Horror+Nights',
          banner: 'https://via.placeholder.com/800x400/444444/FFFFFF?text=Horror+Nights',
          creatorId: 'creator_3',
          episodeCount: 6,
          rating: 4.1,
          viewCount: 18000,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          updatedAt: DateTime.now(),
        ),
        Series(
          id: 'series_5',
          title: 'Romance Tales',
          synopsis: 'Beautiful love stories that touch your heart',
          category: 'Romance',
          language: 'Spanish',
          priceType: 'free',
          price: null,
          thumbnail: 'https://via.placeholder.com/300x200/FF44AA/FFFFFF?text=Romance+Tales',
          banner: 'https://via.placeholder.com/800x400/FF44AA/FFFFFF?text=Romance+Tales',
          creatorId: 'creator_4',
          episodeCount: 4,
          rating: 4.3,
          viewCount: 22000,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          updatedAt: DateTime.now(),
        ),
      ];

      state = ContentLoaded(
        series: mockSeries,
        total: mockSeries.length,
        page: 1,
        limit: mockSeries.length,
        hasMore: false,
      );
    } catch (e) {
      state = ContentError('Failed to load content: $e');
    }
  }

  Future<void> loadMoreSeries({
    String? category,
    String? language,
    String? search,
  }) async {
    final currentState = state;
    if (currentState is ContentLoaded && currentState.hasMore) {
      await loadSeries(
        page: currentState.page + 1,
        limit: currentState.limit,
        category: category,
        language: language,
        search: search,
      );
    }
  }

  Future<void> searchSeries(String query) async {
    if (query.trim().isEmpty) {
      await loadSeries(refresh: true);
    } else {
      await loadSeries(search: query.trim(), refresh: true);
    }
  }

  Future<void> filterByCategory(String category) async {
    await loadSeries(category: category, refresh: true);
  }

  Future<void> filterByLanguage(String language) async {
    await loadSeries(language: language, refresh: true);
  }

  Future<void> refreshContent() async {
    await loadSeries(refresh: true);
  }

  void clearError() {
    if (state is ContentError) {
      state = const ContentInitial();
    }
  }
}

// Providers
final contentNotifierProvider = StateNotifierProvider<ContentNotifier, ContentState>((ref) {
  final contentRepository = ref.read(contentRepositoryProvider);
  return ContentNotifier(contentRepository);
});

final contentLoadingProvider = Provider<bool>((ref) {
  final contentState = ref.watch(contentNotifierProvider);
  return contentState is ContentLoading;
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
