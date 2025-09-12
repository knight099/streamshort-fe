import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/models/content_models.dart';
import '../../data/providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

// Search state
class SearchState {
  final List<Series> results;
  final bool isLoading;
  final String? error;
  final String query;
  final String? selectedCategory;
  final String? selectedLanguage;
  final String? selectedPriceType;
  final bool hasMore;
  final int currentPage;

  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
    this.selectedCategory,
    this.selectedLanguage,
    this.selectedPriceType,
    this.hasMore = true,
    this.currentPage = 1,
  });

  SearchState copyWith({
    List<Series>? results,
    bool? isLoading,
    String? error,
    String? query,
    String? selectedCategory,
    String? selectedLanguage,
    String? selectedPriceType,
    bool? hasMore,
    int? currentPage,
  }) {
    return SearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      query: query ?? this.query,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      selectedPriceType: selectedPriceType ?? this.selectedPriceType,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// Search notifier
class SearchNotifier extends StateNotifier<SearchState> {
  final ContentRepository _contentRepository;
  final Ref _ref;

  SearchNotifier(this._contentRepository, this._ref) : super(const SearchState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const SearchState();
      return;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      query: query.trim(),
      results: [],
      currentPage: 1,
      hasMore: true,
    );

    try {
      final authUser = _ref.read(authUserProvider);
      final response = await _contentRepository.searchSeries(
        query: query.trim(),
        page: 1,
        limit: 20,
        category: state.selectedCategory,
        language: state.selectedLanguage,
        priceType: state.selectedPriceType,
        accessToken: authUser?.accessToken,
      );

      state = state.copyWith(
        isLoading: false,
        results: response.items,
        hasMore: response.items.length >= 20,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        results: [],
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoading: true);

    try {
      final authUser = _ref.read(authUserProvider);
      final response = await _contentRepository.searchSeries(
        query: state.query,
        page: state.currentPage + 1,
        limit: 20,
        category: state.selectedCategory,
        language: state.selectedLanguage,
        priceType: state.selectedPriceType,
        accessToken: authUser?.accessToken,
      );

      state = state.copyWith(
        isLoading: false,
        results: [...state.results, ...response.items],
        currentPage: state.currentPage + 1,
        hasMore: response.items.length >= 20,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void setFilter({
    String? category,
    String? language,
    String? priceType,
  }) {
    state = state.copyWith(
      selectedCategory: category,
      selectedLanguage: language,
      selectedPriceType: priceType,
    );
    
    // Re-search with new filters
    if (state.query.isNotEmpty) {
      search(state.query);
    }
  }

  void clearFilters() {
    state = state.copyWith(
      selectedCategory: null,
      selectedLanguage: null,
      selectedPriceType: null,
    );
    
    // Re-search without filters
    if (state.query.isNotEmpty) {
      search(state.query);
    }
  }

  void clearSearch() {
    state = const SearchState();
  }
}

// Providers
final searchNotifierProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final contentRepository = ref.watch(contentRepositoryProvider);
  return SearchNotifier(contentRepository, ref);
});

// Filter options
final searchCategoriesProvider = Provider<List<String>>((ref) {
  return [
    'Entertainment',
    'Education',
    'Technology',
    'Music',
    'Sports',
    'Romance',
    'Comedy',
    'Drama',
    'Action',
    'Documentary',
  ];
});

final searchLanguagesProvider = Provider<List<String>>((ref) {
  return [
    'English',
    'Hindi',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Japanese',
    'Korean',
  ];
});

final searchPriceTypesProvider = Provider<List<String>>((ref) {
  return [
    'free',
    'subscription',
    'one_time',
  ];
});
