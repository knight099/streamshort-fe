import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/creator_models.dart';
import '../../../data/providers.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../widgets/dashboard/profile_tab.dart';
import '../../widgets/dashboard/overview_tab.dart';
import '../../widgets/dashboard/series_tab.dart';
import '../../widgets/dashboard/episodes_tab.dart';
import '../series_management_screen.dart';
import '../../widgets/dashboard/dialogs/index.dart';
import '../../widgets/dashboard/edit_profile_dialog.dart';

class CreatorDashboardScreen extends ConsumerStatefulWidget {
  const CreatorDashboardScreen({super.key});

  @override
  ConsumerState<CreatorDashboardScreen> createState() => _CreatorDashboardScreenState();
}

class _CreatorDashboardScreenState extends ConsumerState<CreatorDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  CreatorDashboardResponse? _dashboardData;
  List<CreatorSeries> _seriesList = [];
  CreatorProfile? _creatorProfile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCreatorData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCreatorData() async {
    setState(() => _isLoading = true);
    try {
      final accessToken = ref.read(accessTokenProvider);
      if (accessToken == null) {
        throw Exception('No access token available');
      }
      
      // Load creator profile first
      final profile = await ref.read(creatorRepositoryProvider).getCreatorProfile(accessToken: accessToken);
      setState(() {
        _creatorProfile = profile;
      });
      
      // Load dashboard data
      try {
        final dashboard = await ref.read(creatorRepositoryProvider).getCreatorDashboard(accessToken: accessToken);
        setState(() {
          _dashboardData = dashboard;
        });
      } catch (e) {
        print('Dashboard loading failed: $e');
        // Continue without dashboard data
      }
      
      // Load series data
      try {
        final content = await ref.read(creatorRepositoryProvider).getCreatorContent(accessToken: accessToken);
        setState(() {
          _seriesList = content.series;
        });
      } catch (e) {
        print('Series loading failed: $e');
        // Continue without series data
        setState(() {
          _seriesList = [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading creator data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showCreateSeriesDialog(BuildContext context) async {
    final shouldRefresh = await showDialog<bool>(
      context: context,
      builder: (context) => const CreateSeriesDialog(),
    );
    if (shouldRefresh == true && mounted) {
      _loadCreatorData();
    }
  }

  void _showCreateEpisodeDialog(BuildContext context, String? seriesId) {
    showDialog(
      context: context,
      builder: (context) => CreateEpisodeDialog(seriesId: seriesId),
    );
  }

  void _showOnboardingDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Creator onboarding is already complete!')),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditCreatorProfileDialog(
        creatorProfile: _creatorProfile!,
        onProfileUpdated: (updatedProfile) {
          setState(() {
            _creatorProfile = updatedProfile;
          });
        },
      ),
    );
  }

  void _navigateToSeriesDetail(BuildContext context, CreatorSeries series) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeriesManagementScreen(seriesId: series.id),
      ),
    );
  }

  Future<void> _updateSeriesStatus(BuildContext context, CreatorSeries series, String status) async {
    try {
      final accessToken = ref.read(accessTokenProvider);
      await ref.read(creatorRepositoryProvider).updateSeriesStatus(
        seriesId: series.id,
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
        _loadCreatorData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update series status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateEpisodeStatus(BuildContext context, CreatorEpisode episode, String status) async {
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
        _loadCreatorData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update episode status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEpisodeDetails(BuildContext context, CreatorEpisode episode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Episode ${episode.episodeNumber}: ${episode.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration: ${episode.durationSeconds ~/ 60}m ${episode.durationSeconds % 60}s'),
            Text('Status: ${episode.status}'),
            Text('Episode: ${episode.episodeNumber}'),
            Text('Created: ${episode.createdAt.toString().split(' ')[0]}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Clear existing data and reload
              setState(() {
                _dashboardData = null;
                _seriesList = [];
                _creatorProfile = null;
              });
              _loadCreatorData();
            },
            tooltip: 'Refresh Dashboard',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Profile', icon: Icon(Icons.person)),
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Series', icon: Icon(Icons.video_library)),
            Tab(text: 'Episodes', icon: Icon(Icons.play_circle)),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ProfileTab(
            isLoading: _isLoading,
            creatorProfile: _creatorProfile,
            onRefresh: () {
              setState(() {
                _creatorProfile = null;
              });
              _loadCreatorData();
            },
            onOnboarding: () => _showOnboardingDialog(context),
          ),
          OverviewTab(
            isLoading: _isLoading,
            dashboardData: _dashboardData,
            seriesList: _seriesList,
            onCreateSeries: _showCreateSeriesDialog,
            onCreateEpisode: _showCreateEpisodeDialog,
            onSeriesSelected: _navigateToSeriesDetail,
          ),
          SeriesTab(
            isLoading: _isLoading,
            seriesList: _seriesList,
            onCreateSeries: _showCreateSeriesDialog,
            onSeriesSelected: _navigateToSeriesDetail,
            onUpdateStatus: _updateSeriesStatus,
            onRefresh: _loadCreatorData,
          ),
          EpisodesTab(
            isLoading: _isLoading,
            seriesList: _seriesList,
            onCreateSeries: _showCreateSeriesDialog,
            onEpisodeSelected: _showEpisodeDetails,
            onUpdateStatus: _updateEpisodeStatus,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSeriesDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Create Series'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
