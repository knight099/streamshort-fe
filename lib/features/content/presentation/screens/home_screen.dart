import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/content_models.dart';
import '../../data/providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'series_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Series> _series = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final accessToken = ref.read(accessTokenProvider);
      final response = await ref.read(contentRepositoryProvider).getPublishedSeries(
            accessToken: accessToken,
          );
      
      if (mounted) {
        setState(() {
          _series = response.items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load content: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadContent,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadContent,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _series.isEmpty
                  ? const Center(
                      child: Text('No content available'),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFeaturedSection(),
                          const SizedBox(height: 24),
                          _buildCategorySection('Latest Series'),
                          const SizedBox(height: 24),
                          _buildCategorySection('Free Content'),
                          const SizedBox(height: 24),
                          _buildCategorySection('Premium Content'),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildFeaturedSection() {
    final featured = _series.isNotEmpty ? _series[0] : null;
    if (featured == null) return const SizedBox.shrink();

    return Container(
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        image: featured.thumbnailUrl != null
            ? DecorationImage(
                image: NetworkImage(featured.thumbnailUrl!),
                fit: BoxFit.cover,
              )
            : null,
        color: Theme.of(context).colorScheme.primary,
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  featured.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  featured.synopsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SeriesDetailScreen(seriesId: featured.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Watch Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Add to watchlist
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('My List'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String title) {
    List<Series> seriesForCategory;
    switch (title) {
      case 'Latest Series':
        seriesForCategory = _series;
        break;
      case 'Free Content':
        seriesForCategory = _series.where((s) => s.isFree).toList();
        break;
      case 'Premium Content':
        seriesForCategory = _series.where((s) => !s.isFree).toList();
        break;
      default:
        seriesForCategory = _series;
    }

    if (seriesForCategory.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: seriesForCategory.length,
            itemBuilder: (context, index) {
              final series = seriesForCategory[index];
              return _buildSeriesCard(series);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSeriesCard(Series series) {
    return Container(
      width: 300,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SeriesDetailScreen(seriesId: series.id),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  image: series.thumbnailUrl != null
                      ? DecorationImage(
                          image: NetworkImage(series.thumbnailUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: series.thumbnailUrl == null
                    ? Center(
                        child: Text(
                          series.title[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      series.synopsis,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
