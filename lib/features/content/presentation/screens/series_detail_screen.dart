import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/content_models.dart';
import '../../data/providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../../subscription/presentation/widgets/subscription_dialog.dart';
import 'episode_player_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class SeriesDetailScreen extends ConsumerStatefulWidget {
  final String seriesId;

  const SeriesDetailScreen({super.key, required this.seriesId});

  @override
  ConsumerState<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends ConsumerState<SeriesDetailScreen> {
  Series? _series;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSeries();
  }

  Future<void> _loadSeries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final accessToken = ref.read(accessTokenProvider);
      final response = await ref.read(contentRepositoryProvider).getPublishedSeries(
            accessToken: accessToken,
          );
      
      final series = response.items.firstWhere((s) => s.id == widget.seriesId);
      
      if (mounted) {
        setState(() {
          _series = series;
          _isLoading = false;
        });

        // Check subscription status if series is not free
        if (!series.isFree) {
          ref.read(subscriptionCheckProvider.notifier).checkAccess(
            targetType: 'series',
            targetId: series.id,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load series: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _handleWatchEpisode(BuildContext context, Episode episode) {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text('Please login to watch this episode.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
      return;
    }

    // Check subscription for premium content
    if (_series != null && !_series!.isFree) {
      final subscriptionState = ref.read(subscriptionCheckProvider);
      if (subscriptionState is SubscriptionCheckLoaded && !subscriptionState.hasAccess) {
        showDialog(
          context: context,
          builder: (context) => SubscriptionDialog(
            targetType: 'series',
            targetId: _series!.id,
            title: 'Premium Content',
            description: 'Subscribe to watch all episodes of ${_series!.title}',
          ),
        );
        return;
      }
    }

    // Navigate to reels-like episode player
    if (_series != null && _series!.episodes != null && _series!.episodes!.isNotEmpty) {
      final episodeIndex = _series!.episodes!.indexWhere((e) => e.id == episode.id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EpisodePlayerScreen(
            episodeId: episode.id,
            seriesId: _series!.id,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No episodes to play.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_series?.title ?? 'Series Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSeries,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _series == null
                  ? const Center(child: Text('Series not found'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSeriesHeader(context),
                          const SizedBox(height: 24),
                          _buildEpisodesList(context),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSeriesHeader(BuildContext context) {
    if (_series == null) return const SizedBox.shrink();

    return Stack(
      children: [
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            image: _series!.thumbnailUrl != null
                ? DecorationImage(
                    image: NetworkImage(_series!.thumbnailUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
            color: Theme.of(context).colorScheme.primary,
          ),
          child: Container(
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
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _series!.title ?? 'Untitled',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _series!.synopsis ?? 'No description available',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Chip(
                    label: Text((_series!.language ?? 'Unknown').toUpperCase()),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text((_series!.priceType ?? 'Unknown').toUpperCase()),
                    backgroundColor: _series!.isFree
                        ? Colors.green
                        : Theme.of(context).colorScheme.secondary,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                  if (!_series!.isFree) ...[
                    const SizedBox(width: 8),
                    Consumer(
                      builder: (context, ref, child) {
                        final subscriptionState = ref.watch(subscriptionCheckProvider);
                        if (subscriptionState is SubscriptionCheckLoaded) {
                          return Chip(
                            label: Text(subscriptionState.hasAccess ? 'SUBSCRIBED' : 'SUBSCRIBE'),
                            backgroundColor: subscriptionState.hasAccess
                                ? Colors.green
                                : Theme.of(context).colorScheme.error,
                            labelStyle: const TextStyle(color: Colors.white),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEpisodesList(BuildContext context) {
    if (_series == null || _series!.episodes == null || _series!.episodes!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No episodes available'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Episodes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _series!.episodes!.length,
          itemBuilder: (context, index) {
            final episode = _series!.episodes![index];
            return _buildEpisodeCard(context, episode);
          },
        ),
      ],
    );
  }

  Widget _buildEpisodeCard(BuildContext context, Episode episode) {
    final duration = Duration(seconds: episode.durationSeconds ?? 0);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final durationText = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _handleWatchEpisode(context, episode),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 120,
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: episode.thumbUrl != null
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(episode.thumbUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: episode.thumbUrl == null
                    ? Center(
                        child: Text(
                          episode.episodeNumber.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      episode.title ?? 'Untitled Episode',
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Episode ${episode.episodeNumber} • $durationText',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (!_series!.isFree)
                Consumer(
                  builder: (context, ref, child) {
                    final subscriptionState = ref.watch(subscriptionCheckProvider);
                    if (subscriptionState is SubscriptionCheckLoaded && !subscriptionState.hasAccess) {
                      return const Icon(Icons.lock, size: 32);
                    }
                    return const Icon(Icons.play_circle_outline, size: 32);
                  },
                )
              else
                const Icon(Icons.play_circle_outline, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}