import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/creator_models.dart';

import '../../data/providers.dart';
import '../widgets/dashboard/dialogs/add_episode_dialog.dart';

class SeriesManagementScreen extends ConsumerStatefulWidget {
  final String seriesId;

  const SeriesManagementScreen({super.key, required this.seriesId});

  @override
  ConsumerState<SeriesManagementScreen> createState() => _SeriesManagementScreenState();
}

class _SeriesManagementScreenState extends ConsumerState<SeriesManagementScreen> {
  bool _isLoading = false;
  CreatorSeries? _series;
  List<CreatorEpisode> _episodes = [];

  @override
  void initState() {
    super.initState();
    _loadSeriesData();
  }

  Future<void> _loadSeriesData() async {
    setState(() => _isLoading = true);
    try {
      final content = await ref.read(creatorRepositoryProvider).getCreatorContent();
      final seriesData = content.series.firstWhere((s) => s.id == widget.seriesId);
      final episodes = seriesData.episodes;
      
      setState(() {
        _series = seriesData;
        _episodes = episodes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading series data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_series == null) {
      return const Scaffold(
        body: Center(child: Text('Series not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_series!.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditSeriesDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSeriesHeader(),
            const SizedBox(height: 24),
            _buildSeriesStats(),
            const SizedBox(height: 24),
            _buildEpisodesSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateEpisodeDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Episode'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSeriesHeader() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (_series!.thumbnailUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _series!.thumbnailUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderThumbnail(_series!.title),
                    ),
                  )
                else
                  _buildPlaceholderThumbnail(_series!.title),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _series!.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _series!.synopsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(
                            label: Text(_series!.language),
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(_series!.status),
                            backgroundColor: _series!.isPublished
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(_series!.priceType),
                            backgroundColor: _series!.isFree
                                ? Colors.blue.shade100
                                : Colors.amber.shade100,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_series!.categoryTags.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Categories:'),
              Wrap(
                spacing: 8,
                children: _series!.categoryTags.map((category) {
                  return Chip(
                    label: Text(category),
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeriesStats() {
    return Card(
      elevation: 4,
      child: Padding(
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
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Episodes',
                    _series!.episodeCount.toString(),
                    Icons.play_circle,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Views',
                    '0',
                    Icons.visibility,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Rating',
                    '0.0',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEpisodesSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Episodes (${_episodes.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: () => _showCreateEpisodeDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Episode'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_episodes.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No episodes yet. Add your first episode!'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _episodes.length,
                itemBuilder: (context, index) {
                  final episode = _episodes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: _buildEpisodePlaceholder(),
                      title: Text('Episode ${episode.episodeNumber}: ${episode.title}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${episode.durationSeconds ~/ 60}m ${episode.durationSeconds % 60}s • ${episode.status}'),
                          Text('Episode ${episode.episodeNumber}'),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) => _handleEpisodeAction(value, episode),
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
                            value: 'upload',
                            child: Row(
                              children: [
                                Icon(Icons.upload),
                                SizedBox(width: 8),
                                Text('Upload Video'),
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
                      ),
                      onTap: () => _showEpisodeDetails(episode),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderThumbnail(String title) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          title[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodePlaceholder() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(
        Icons.play_arrow,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  void _handleEpisodeAction(String action, CreatorEpisode episode) {
    switch (action) {
      case 'edit':
        _showEditEpisodeDialog(context, episode);
        break;
      case 'upload':
        _showUploadDialog(context, episode.id);
        break;
      case 'delete':
        _showDeleteEpisodeDialog(context, episode);
        break;
    }
  }

  void _showEpisodeDetails(CreatorEpisode episode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Episode ${episode.episodeNumber}: ${episode.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration: ${episode.durationFormatted}'),
            Text('Status: ${episode.status}'),
            Text('Duration: ${episode.durationSeconds ~/ 60}m ${episode.durationSeconds % 60}s'),
            
            Text('Created: ${episode.createdAt.toString().split(' ')[0]}'),
            if (episode.publishedAt != null) 
              Text('Published: ${episode.publishedAt!.toString().split(' ')[0]}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditSeriesDialog(BuildContext context) {
    // TODO: Implement series editing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Series editing coming soon!')),
    );
  }

  Future<void> _showCreateEpisodeDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddEpisodeDialog(seriesId: widget.seriesId),
    );

    if (result == true && mounted) {
      _loadSeriesData();
    }
  }

  void _showEditEpisodeDialog(BuildContext context, CreatorEpisode episode) {
    // TODO: Implement episode editing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Episode editing coming soon!')),
    );
  }

  void _showUploadDialog(BuildContext context, String episodeId) {
    // TODO: Implement video upload
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video upload coming soon!')),
    );
  }

  void _showDeleteEpisodeDialog(BuildContext context, CreatorEpisode episode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Episode'),
        content: Text(
          'Are you sure you want to delete "Episode ${episode.episodeNumber}: ${episode.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEpisode(episode);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEpisode(CreatorEpisode episode) async {
    try {
      // TODO: Implement episode deletion API call
      setState(() {
        _episodes.removeWhere((e) => e.id == episode.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Episode deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting episode: $e')),
      );
    }
  }
}
