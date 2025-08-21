import 'package:flutter/material.dart';
import '../../../data/models/creator_models.dart';
import 'dialogs/add_episode_dialog.dart';
import '../../screens/series_detail_screen.dart';
import '../../screens/dashboard/creator_dashboard_screen.dart';

class SeriesTab extends StatelessWidget {
  final bool isLoading;
  final List<CreatorSeries> seriesList;
  final Function(BuildContext) onCreateSeries;
  final Function(BuildContext, CreatorSeries) onSeriesSelected;
  final VoidCallback onRefresh;
  final Function(BuildContext, CreatorSeries, String) onUpdateStatus;

  const SeriesTab({
    super.key,
    required this.isLoading,
    required this.seriesList,
    required this.onCreateSeries,
    required this.onSeriesSelected,
    required this.onUpdateStatus,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (seriesList.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: seriesList.length,
      itemBuilder: (context, index) {
        final series = seriesList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: series.thumbnailUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      series.thumbnailUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderThumbnail(context, series.title),
                    ),
                  )
                : _buildPlaceholderThumbnail(context, series.title),
            title: Text(series.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(series.synopsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Chip(
                      label: Text(series.language),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(series.status),
                      backgroundColor: series.isPublished
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
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${series.episodeCount} episodes',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      series.status,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: series.isPublished ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Add Episode',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AddEpisodeDialog(series: series),
                        );
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'publish' || value == 'draft') {
                          onUpdateStatus(context, series, value);
                        }
                      },
                      itemBuilder: (context) => [
                        if (!series.isPublished)
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
                        if (series.isPublished)
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
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SeriesDetailScreen(series: series),
                ),
              ).then((_) {
                // Refresh the series list when returning from detail screen
                onRefresh();
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Series Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first series to get started\n\nNote: Series management API is currently being set up on the backend.',
              style: TextStyle(fontSize: 16),
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

  Widget _buildPlaceholderThumbnail(BuildContext context, String title) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          title[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
