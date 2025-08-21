import 'package:flutter/material.dart';
import '../../../data/models/creator_models.dart';
import '../../../utils/date_formatter.dart';

class OverviewTab extends StatelessWidget {
  final bool isLoading;
  final CreatorDashboardResponse? dashboardData;
  final List<CreatorSeries> seriesList;
  final Function(BuildContext) onCreateSeries;
  final Function(BuildContext, String?) onCreateEpisode;
  final Function(BuildContext, CreatorSeries) onSeriesSelected;

  const OverviewTab({
    super.key,
    required this.isLoading,
    required this.dashboardData,
    required this.seriesList,
    required this.onCreateSeries,
    required this.onCreateEpisode,
    required this.onSeriesSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDebugInfo(context),
          _buildStatsGrid(context),
          const SizedBox(height: 24),
          _buildQuickActions(context),
          const SizedBox(height: 24),
          _buildRecentActivity(context),
        ],
      ),
    );
  }

  Widget _buildDebugInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.green.shade700, size: 16),
          const SizedBox(width: 8),
          Text(
            'Overview Tab Active - Dashboard Data: ${dashboardData?.views ?? "Loading..."}',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    if (dashboardData == null) return const SizedBox.shrink();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          'Total Views',
          dashboardData!.views.toString(),
          Icons.visibility,
          Colors.blue,
        ),
        _buildStatCard(
          context,
          'Watch Time',
          dashboardData!.watchTimeFormatted,
          Icons.timer,
          Colors.green,
        ),
        _buildStatCard(
          context,
          'Total Series',
          dashboardData!.totalSeriesSafe.toString(),
          Icons.video_library,
          Colors.orange,
        ),
        _buildStatCard(
          context,
          'Total Episodes',
          dashboardData!.totalEpisodesSafe.toString(),
          Icons.play_circle,
          Colors.purple,
        ),
        _buildStatCard(
          context,
          'Earnings',
          dashboardData!.earningsFormatted,
          Icons.monetization_on,
          Colors.amber,
        ),
        _buildStatCard(
          context,
          'Rating',
          dashboardData!.averageRatingSafe.toStringAsFixed(1),
          Icons.star,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onCreateSeries(context),
                    icon: const Icon(Icons.add),
                    label: const Text('New Series'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: seriesList.isNotEmpty ? () => onCreateEpisode(context, null) : null,
                    icon: const Icon(Icons.video_call),
                    label: const Text('New Episode'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Series',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (seriesList.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No series created yet. Create your first series!'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: seriesList.length > 5 ? 5 : seriesList.length,
                itemBuilder: (context, index) {
                  final series = seriesList[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        series.title[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(series.title),
                    subtitle: Text('${series.episodeCount} episodes • ${series.status}'),
                    trailing: Text(
                      '${series.episodeCount} episodes',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onTap: () => onSeriesSelected(context, series),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
