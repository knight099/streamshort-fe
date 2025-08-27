import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../data/providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'series_detail_screen.dart';

class LikedVideosScreen extends ConsumerStatefulWidget {
  const LikedVideosScreen({super.key});

  @override
  ConsumerState<LikedVideosScreen> createState() => _LikedVideosScreenState();
}

class _LikedVideosScreenState extends ConsumerState<LikedVideosScreen> {
  List<Series> _likedSeries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLikedVideos();
  }

  Future<void> _loadLikedVideos() async {
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
          _likedSeries = response.items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load liked videos: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liked Videos'),
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
                        onPressed: _loadLikedVideos,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _likedSeries.isEmpty
                  ? const Center(
                      child: Text('No liked videos yet'),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLikedVideos,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _likedSeries.length,
                        itemBuilder: (context, index) {
                          final series = _likedSeries[index];
                          return _buildSeriesCard(context, series);
                        },
                      ),
                    ),
    );
  }

  Widget _buildSeriesCard(BuildContext context, Series series) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
              height: 200,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    series.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    series.synopsis,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Chip(
                        label: Text(series.language.toUpperCase()),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(series.priceType.toUpperCase()),
                        backgroundColor: series.isFree
                            ? Colors.green
                            : Theme.of(context).colorScheme.secondary,
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
