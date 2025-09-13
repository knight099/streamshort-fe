import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/creator_models.dart';
import '../../data/repositories/creator_repository.dart';
import '../../data/providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'creator_profile_screen.dart';

class OldCreatorDashboardScreen extends ConsumerStatefulWidget {
  const OldCreatorDashboardScreen({super.key});

  @override
  ConsumerState<OldCreatorDashboardScreen> createState() => _OldCreatorDashboardScreenState();
}

class _OldCreatorDashboardScreenState extends ConsumerState<OldCreatorDashboardScreen> {
  CreatorDashboardResponse? _dashboardData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCreatorDashboard();
  }

  Future<void> _loadCreatorDashboard() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final repo = ref.read(creatorRepositoryProvider);
      final accessToken = ref.read(accessTokenProvider);
      final user = ref.read(authUserProvider);

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final data = await repo.getCreatorDashboard(creatorId: user.id, accessToken: accessToken);

      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Creator Dashboard'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Creator Dashboard'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: $_error',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCreatorDashboard,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Creator Stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Creator Analytics',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCreatorStat(
                            context,
                            'Total Views',
                            '${(_dashboardData!.views / 1000).toStringAsFixed(1)}K',
                            Icons.visibility,
                          ),
                        ),
                        Expanded(
                          child: _buildCreatorStat(
                            context,
                            'Total Series',
                            '${_dashboardData!.followerCountFormatted}',
                            Icons.people,
                          ),
                        ),
                        Expanded(
                          child: _buildCreatorStat(
                            context,
                            'Revenue',
                            '${_dashboardData!.earningsFormatted}',
                            Icons.attach_money,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Content Management
            Text(
              'Content Management',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildContentCard(
              context,
              'My Series',
              'Manage your video series',
              Icons.video_library,
              'View Series',
            ),
            _buildContentCard(
              context,
              'Upload New Content',
              'Add episodes to your series',
              Icons.cloud_upload,
              'Upload',
            ),
            _buildContentCard(
              context,
              'Analytics',
              'Detailed performance metrics',
              Icons.analytics,
              'View',
            ),
            const SizedBox(height: 20),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              context,
              'Creator Profile',
              Icons.person,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatorProfileScreen(),
                  ),
                );
              },
            ),
            _buildActionButton(
              context,
              'Payout Settings',
              Icons.account_balance_wallet,
              () {
                // TODO: Navigate to payout settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payout settings coming soon!')),
                );
              },
            ),
            _buildActionButton(
              context,
              'Creator Guidelines',
              Icons.help_outline,
              () {
                // TODO: Show creator guidelines
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Creator guidelines coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatorStat(BuildContext context, String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 28,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildContentCard(BuildContext context, String title, String subtitle, IconData icon, String action) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Chip(
          label: Text(action),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        onTap: () {
          // TODO: Implement content management actions
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title functionality coming soon!')),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
