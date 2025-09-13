import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../creator/data/repositories/creator_repository.dart';
import '../../../subscription/data/repositories/subscription_repository.dart';
import '../../../subscription/data/models/subscription_models.dart';
import '../../../subscription/presentation/widgets/subscription_sheet.dart';
import '../providers/profile_providers.dart';
import '../../../creator/data/providers.dart';
import '../../../subscription/data/providers.dart';
import '../../../content/presentation/screens/liked_videos_screen.dart';
import '../../../subscription/presentation/screens/subscription_management_screen.dart';
import '../../../creator/presentation/screens/following_screen.dart';
import '../../../creator/presentation/screens/creator_onboarding_screen.dart';
import '../../../creator/presentation/screens/dashboard/creator_dashboard_screen.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _isLoading = true;
  String? _error;
  bool _isSavingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Try to get user from auth state first
      final authUser = ref.read(authUserProvider);
      if (authUser != null) {
        // Check if this user has a creator profile
        try {
          final creatorRepo = ref.read(creatorRepositoryProvider);
          final accessToken = ref.read(accessTokenProvider);
          
          if (accessToken != null) {
            print('Checking for creator profile...');
            final creatorProfile = await creatorRepo.getCreatorProfile(accessToken: accessToken);
            if (creatorProfile != null) {
              print('Creator profile found! Updating user role to creator');
              // User has a creator profile, update their role
              await ref.read(authNotifierProvider.notifier).updateUserRole('creator');
              print('User role updated to creator');
            } else {
              print('No creator profile found');
            }
          } else {
            print('No access token available');
          }
        } catch (e) {
          // If creator profile check fails, continue with regular user
          print('Creator profile check failed: $e');
        }
        
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // If not authenticated, show demo data
      setState(() {
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
    // Watch the auth user to automatically update when role changes
    final authUser = ref.watch(authUserProvider);
    
    // Use auth user directly instead of local state
    final user = authUser;
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('User Profile'),
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
          title: const Text('User Profile'),
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
                onPressed: _loadUserProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserProfile,
            tooltip: 'Refresh Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: user?.avatarUrl != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: user!.avatarUrl!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Shimmer.fromColors(
                                  baseColor: Colors.grey.shade800,
                                  highlightColor: Colors.grey.shade700,
                                  child: Container(width: 80, height: 80, color: Colors.grey.shade800),
                                ),
                                errorWidget: (context, url, error) => const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'User',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user?.role == 'premium' ? 'Premium Member' : 'Free Member',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Member since ${user?.createdAt != null ? _formatDate(user!.createdAt) : 'Unknown'}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Stats Section
            Text(
              'Your Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Videos Watched',
                    '127',
                    Icons.play_circle_outline,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Watchlist',
                    '23',
                    Icons.bookmark_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
  

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
              'Liked Videos',
              Icons.favorite,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LikedVideosScreen(),
                  ),
                );
              },
            ),
            _buildActionButton(
              context,
              'Edit Profile',
              Icons.edit,
              () {
                _openEditProfileSheet();
              },
            ),
            _buildActionButton(
              context,
              'Subscription Settings',
              Icons.subscriptions,
              () {
                _openSubscriptionSheet();
              },
            ),
            _buildActionButton(
              context,
              'Subscriptions',
              Icons.subscriptions,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionManagementScreen(),
                  ),
                );
              },
            ),
            _buildActionButton(
              context,
              'Following',
              Icons.people,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FollowingScreen(),
                  ),
                );
              },
            ),
            _buildActionButton(
              context,
              'Watch History',
              Icons.history,
              () {
                // TODO: Navigate to watch history
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Watch history coming soon!')),
                );
              },
            ),
            _buildActionButton(
              context,
              'Settings',
              Icons.settings,
              () {
                // TODO: Navigate to settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon!')),
                );
              },
            ),
            const SizedBox(height: 8),
            // Creator actions - only show if user is a creator
            if (user?.role == 'creator') ...[
              Text(
                'Creator',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                context,
                'Creator Dashboard',
                Icons.dashboard_customize,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreatorDashboardScreen(),
                    ),
                  );
                },
              ),
            ] else ...[
              Text(
                'Creator',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                context,
                'Become a Creator',
                Icons.star_border,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreatorOnboardingScreen(),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.year}';
  }

  Future<void> _openEditProfileSheet() async {
    final authUser = ref.read(authUserProvider);
    if (authUser == null) return;
    final nameController = TextEditingController(text: authUser.displayName ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Profile', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSavingProfile
                      ? null
                      : () async {
                          setState(() => _isSavingProfile = true);
                          try {
                            final profileRepo = ref.read(profileRepositoryProvider);
                            final updated = await profileRepo.updateUserProfile(
                              displayName: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
                            );
                            if (mounted) {
                              // Profile updated successfully, the auth state will be updated automatically
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Profile updated')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to update: $e')),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isSavingProfile = false);
                          }
                        },
                  icon: _isSavingProfile
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openSubscriptionSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SubscriptionSheet(ref: ref);
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
        ),
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

