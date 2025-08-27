import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/creator_models.dart';
import '../widgets/dashboard/dialogs/add_episode_dialog.dart';
import '../widgets/dashboard/dialogs/edit_series_dialog.dart';
import '../widgets/dashboard/dialogs/edit_episode_dialog.dart';
import '../../../../core/theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/providers.dart';

class SeriesDetailScreen extends ConsumerStatefulWidget {
  final CreatorSeries series;

  const SeriesDetailScreen({
    super.key,
    required this.series,
  });

  @override
  ConsumerState<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends ConsumerState<SeriesDetailScreen> {
  late CreatorSeries _series;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _series = widget.series;
    _loadSeriesData();
  }

  Future<void> _loadSeriesData() async {
    setState(() => _isLoading = true);
    try {
      final accessToken = ref.read(accessTokenProvider);
      final content = await ref.read(creatorRepositoryProvider).getCreatorContent(
        accessToken: accessToken,
      );
      
      final updatedSeries = content.series.firstWhere(
        (s) => s.id == widget.series.id,
        orElse: () => widget.series,
      );
      
      if (mounted) {
        setState(() {
          _series = updatedSeries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading series: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateSeriesStatus(String status) async {
    try {
      final accessToken = ref.read(accessTokenProvider);
      await ref.read(creatorRepositoryProvider).updateSeriesStatus(
        seriesId: _series.id,
        status: status,
        accessToken: accessToken,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Series ${status == "publish" ? "published" : "unpublished"} successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSeriesData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating series status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateEpisodeStatus(CreatorEpisode episode, String status) async {
    try {
      final accessToken = ref.read(accessTokenProvider);
      await ref.read(creatorRepositoryProvider).updateEpisodeStatus(
        episodeId: episode.id,
        status: status,
        accessToken: accessToken,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Episode ${status == "publish" ? "published" : "unpublished"} successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSeriesData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating episode status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_series.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSeriesData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => EditSeriesDialog(series: _series),
              ).then((shouldRefresh) {
                if (shouldRefresh == true) {
                  _loadSeriesData();
                }
              });
            },
            tooltip: 'Edit Series',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSeriesHeader(),
                  const Divider(),
                  _buildSeriesStats(),
                  const Divider(),
                  _buildEpisodesList(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddEpisodeDialog(seriesId: _series.id),
          ).then((_) => _loadSeriesData());
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Episode'),
      ),
    );
  }

  Widget _buildSeriesHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _series.title[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _series.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _series.synopsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(_series.language),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
              Chip(
                label: Text(_series.priceType),
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              ),
              Chip(
                label: Text(_series.status),
                backgroundColor: _series.isPublished
                    ? Colors.green.shade100
                    : Colors.orange.shade100,
              ),
              ..._series.categoryTags.map(
                (tag) => Chip(
                  label: Text(tag),
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!_series.isPublished)
                ElevatedButton.icon(
                  onPressed: () => _updateSeriesStatus('publish'),
                  icon: const Icon(Icons.publish),
                  label: const Text('Publish Series'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => _updateSeriesStatus('draft'),
                  icon: const Icon(Icons.unpublished),
                  label: const Text('Unpublish Series'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Series Statistics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                icon: Icons.play_circle,
                value: _series.episodeCount.toString(),
                label: 'Episodes',
                color: Colors.blue,
              ),
              _buildStatCard(
                icon: Icons.visibility,
                value: '0',
                label: 'Views',
                color: Colors.green,
              ),
              _buildStatCard(
                icon: Icons.star,
                value: '0.0',
                label: 'Rating',
                color: Colors.amber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodesList() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Episodes (${_series.episodeCount})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AddEpisodeDialog(seriesId: _series.id),
                  ).then((_) => _loadSeriesData());
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Episode'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_series.episodes.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No episodes yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add your first episode to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _series.episodes.length,
              itemBuilder: (context, index) {
                final episode = _series.episodes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          episode.episodeNumber.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: Text(episode.title),
                    subtitle: Text(
                      '${episode.durationSeconds ~/ 60}m ${episode.durationSeconds % 60}s • ${episode.status}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!episode.status.contains('published'))
                          IconButton(
                            icon: const Icon(Icons.publish, color: Colors.green),
                            onPressed: () => _updateEpisodeStatus(episode, 'publish'),
                            tooltip: 'Publish Episode',
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.unpublished, color: Colors.orange),
                            onPressed: () => _updateEpisodeStatus(episode, 'draft'),
                            tooltip: 'Unpublish Episode',
                          ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'edit') {
                              final shouldRefresh = await showDialog<bool>(
                                context: context,
                                builder: (context) => EditEpisodeDialog(episode: episode),
                              );
                              if (shouldRefresh == true) {
                                _loadSeriesData();
                              }
                            } else if (value == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Episode'),
                                  content: Text('Are you sure you want to delete "${episode.title}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  final accessToken = ref.read(accessTokenProvider);
                                  await ref.read(creatorRepositoryProvider).deleteEpisode(
                                        episodeId: episode.id,
                                        accessToken: accessToken,
                                      );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Episode deleted successfully')),
                                    );
                                    _loadSeriesData();
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to delete episode: $e')),
                                    );
                                  }
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
