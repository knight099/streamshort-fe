import 'package:flutter/material.dart';
import '../../../data/models/creator_models.dart';
import '../../../utils/date_formatter.dart';

class EpisodesTab extends StatelessWidget {
  final bool isLoading;
  final List<CreatorSeries> seriesList;
  final Function(BuildContext) onCreateSeries;
  final Function(BuildContext, CreatorEpisode) onEpisodeSelected;
  final Function(BuildContext, CreatorEpisode, String) onUpdateStatus;

  const EpisodesTab({
    super.key,
    required this.isLoading,
    required this.seriesList,
    required this.onCreateSeries,
    required this.onEpisodeSelected,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (seriesList.isEmpty) {
      return _buildEmptyState(
        context,
        'No Episodes Yet',
        'Create a series first, then add episodes to it',
      );
    }

    // Collect all episodes from all series
    final allEpisodes = <MapEntry<String, CreatorEpisode>>[];
    for (final series in seriesList) {
      for (final episode in series.episodes) {
        allEpisodes.add(MapEntry(series.title, episode));
      }
    }

    if (allEpisodes.isEmpty) {
      return _buildEmptyState(
        context,
        'No Episodes Yet',
        'Add episodes to your series to get started',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allEpisodes.length,
      itemBuilder: (context, index) {
        final episodeEntry = allEpisodes[index];
        final seriesTitle = episodeEntry.key;
        final episode = episodeEntry.value;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                '${episode.episodeNumber}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(episode.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Series: $seriesTitle'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Chip(
                      label: Text('${episode.durationSeconds ~/ 60}m'),
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(episode.status),
                      backgroundColor: episode.status == 'published' 
                          ? Colors.green.shade100 
                          : Colors.orange.shade100,
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  episode.publishedAt != null 
                      ? 'Published ${formatDate(episode.publishedAt!)}'
                      : 'Draft',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'publish' || value == 'draft') {
                      onUpdateStatus(context, episode, value);
                    }
                  },
                  itemBuilder: (context) => [
                    if (episode.status != 'published')
                      const PopupMenuItem(
                        value: 'publish',
                        child: Row(
                          children: [
                            Icon(Icons.publish, size: 20),
                            SizedBox(width: 8),
                            Text('Publish'),
                          ],
                        ),
                      ),
                    if (episode.status == 'published')
                      const PopupMenuItem(
                        value: 'draft',
                        child: Row(
                          children: [
                            Icon(Icons.unpublished, size: 20),
                            SizedBox(width: 8),
                            Text('Unpublish'),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            onTap: () => onEpisodeSelected(context, episode),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => onCreateSeries(context),
              icon: const Icon(Icons.add),
              label: const Text('Get Started'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
