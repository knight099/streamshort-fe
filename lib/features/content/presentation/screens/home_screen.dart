import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:streamshort/core/theme.dart';
import 'package:streamshort/features/auth/presentation/providers/auth_providers.dart';
import 'package:streamshort/features/content/data/models/content_models.dart';
import 'package:streamshort/features/content/presentation/providers/content_providers.dart';
import 'package:streamshort/features/content/presentation/widgets/series_card.dart';
import 'package:streamshort/features/content/presentation/widgets/series_shimmer.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final selectedLanguage = useState<String?>(null);
    final selectedCategory = useState<String?>(null);
    
    final seriesState = ref.watch(seriesListProvider);
    final authState = ref.watch(authStateProvider);

    useEffect(() {
      // Load initial series
      ref.read(seriesListProvider.notifier).loadSeries();
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Streamshort'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Show search dialog
              _showSearchDialog(context, ref, searchController);
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          _buildFilters(context, selectedLanguage, selectedCategory, ref),
          
          // Series List
          Expanded(
            child: seriesState.when(
              data: (series) => _buildSeriesList(context, series, ref),
              loading: () => const _LoadingView(),
              error: (error, stack) => _ErrorView(
                error: error.toString(),
                onRetry: () => ref.read(seriesListProvider.notifier).loadSeries(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: authState.isAuthenticated && authState.user?.isCreator == true
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/creator/series'),
              icon: const Icon(Icons.add),
              label: const Text('Create'),
            )
          : null,
    );
  }

  Widget _buildFilters(
    BuildContext context,
    ValueNotifier<String?> selectedLanguage,
    ValueNotifier<String?> selectedCategory,
    WidgetRef ref,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discover',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Language Filter
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: selectedLanguage.value == null,
                onSelected: (selected) {
                  selectedLanguage.value = null;
                  _applyFilters(ref, selectedLanguage.value, selectedCategory.value);
                },
              ),
              FilterChip(
                label: const Text('Hindi'),
                selected: selectedLanguage.value == 'hi',
                onSelected: (selected) {
                  selectedLanguage.value = selected ? 'hi' : null;
                  _applyFilters(ref, selectedLanguage.value, selectedCategory.value);
                },
              ),
              FilterChip(
                label: const Text('English'),
                selected: selectedLanguage.value == 'en',
                onSelected: (selected) {
                  selectedLanguage.value = selected ? 'en' : null;
                  _applyFilters(ref, selectedLanguage.value, selectedCategory.value);
                },
              ),
              FilterChip(
                label: const Text('Marathi'),
                selected: selectedLanguage.value == 'mr',
                onSelected: (selected) {
                  selectedLanguage.value = selected ? 'mr' : null;
                  _applyFilters(ref, selectedLanguage.value, selectedCategory.value);
                },
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Category Filter
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: selectedCategory.value == null,
                onSelected: (selected) {
                  selectedCategory.value = null;
                  _applyFilters(ref, selectedLanguage.value, selectedCategory.value);
                },
              ),
              FilterChip(
                label: const Text('Drama'),
                selected: selectedCategory.value == 'drama',
                onSelected: (selected) {
                  selectedCategory.value = selected ? 'drama' : null;
                  _applyFilters(ref, selectedLanguage.value, selectedCategory.value);
                },
              ),
              FilterChip(
                label: const Text('Comedy'),
                selected: selectedCategory.value == 'comedy',
                onSelected: (selected) {
                  selectedCategory.value = selected ? 'comedy' : null;
                  _applyFilters(ref, selectedLanguage.value, selectedCategory.value);
                },
              ),
              FilterChip(
                label: const Text('Action'),
                selected: selectedCategory.value == 'action',
                onSelected: (selected) {
                  selectedCategory.value = selected ? 'action' : null;
                  _applyFilters(ref, selectedLanguage.value, selectedCategory.value);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesList(BuildContext context, SeriesListResponse series, WidgetRef ref) {
    if (series.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No series found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Try adjusting your filters',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(seriesListProvider.notifier).loadSeries(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: series.items.length,
        itemBuilder: (context, index) {
          final seriesItem = series.items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SeriesCard(series: seriesItem),
          );
        },
      ),
    );
  }

  void _applyFilters(WidgetRef ref, String? language, String? category) {
    ref.read(seriesListProvider.notifier).loadSeries(
      language: language,
      category: category,
    );
  }

  void _showSearchDialog(BuildContext context, WidgetRef ref, TextEditingController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Series'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Search by title, creator, or category...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (query) {
            if (query.isNotEmpty) {
              ref.read(seriesListProvider.notifier).searchSeries(query);
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(seriesListProvider.notifier).searchSeries(controller.text);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: SeriesShimmer(),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
