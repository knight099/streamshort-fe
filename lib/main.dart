import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers.dart';
import 'core/theme.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/content/presentation/providers/content_providers.dart';
import 'features/content/data/models/content_models.dart';
import 'core/api/api_client.dart' as api;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'features/creator/presentation/screens/creator_onboarding_screen.dart';
import 'features/creator/data/models/creator_models.dart';
import 'features/content/presentation/screens/series_detail_screen.dart';
import 'features/content/presentation/screens/liked_videos_screen.dart';
import 'features/content/presentation/screens/search_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/creator/presentation/screens/dashboard/creator_dashboard_screen.dart';
import 'features/creator/presentation/screens/following_screen.dart';
import 'features/subscription/presentation/screens/subscription_management_screen.dart';


import 'core/config/environment.dart';
import 'features/subscription/data/models/subscription_models.dart';

void main() {
  // Set environment - change this to switch between APIs
  EnvironmentConfig.setEnvironment(Environment.development);
  
  runApp(
    const ProviderScope(
      child: StreamshortApp(),
    ),
  );
}

class StreamshortApp extends ConsumerWidget {
  const StreamshortApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authNotifierProvider);
    
    // Initialize auth restoration on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).restoreAuth();
    });
    
    return MaterialApp(
      title: 'Streamshort',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: authState is AuthAuthenticated ? const HomeScreen() : const LoginScreen(),
    );
  }
}

// Router-based app shell is in core/app.dart. Keep demo screens below.

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isOtpSent = false;
  String? _requestId;
  String? _phoneNumber;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number')),
      );
      return;
    }

    try {
      await ref.read(authNotifierProvider.notifier).sendOtp(_phoneController.text.trim());
      setState(() {
        _isOtpSent = true;
        _phoneNumber = _phoneController.text.trim();
        // In a real app, you'd get the requestId from the response
        _requestId = 'demo_request_id_${DateTime.now().millisecondsSinceEpoch}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $e')),
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP')),
      );
      return;
    }

    try {
      await ref.read(authNotifierProvider.notifier).verifyOtp(
        _phoneNumber!,
        _otpController.text.trim(),
        _requestId!,
      );
      
      // Fetch the complete user profile to get the correct role
      try {
        final profileRepo = ref.read(profileRepositoryProvider);
        final userProfile = await profileRepo.getUserProfile();
        
        // Update the user in auth state with the complete profile
        if (userProfile.role != 'user') {
          await ref.read(authNotifierProvider.notifier).updateUserRole(userProfile.role);
        }
      } catch (e) {
        // If profile fetch fails, check for creator profile as fallback
        try {
          final accessToken = ref.read(accessTokenProvider);
          if (accessToken != null) {
            final creatorRepo = ref.read(creatorRepositoryProvider);
            final creatorProfile = await creatorRepo.getCreatorProfile(accessToken: accessToken);
            if (creatorProfile != null) {
              // User has a creator profile, update their role
              await ref.read(authNotifierProvider.notifier).updateUserRole('creator');
            }
          }
        } catch (e2) {
          // If both profile fetch and creator profile check fail, continue with regular user
          print('Profile fetch and creator profile check failed: $e, $e2');
        }
      }
      
      // Navigate to home screen on successful authentication
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to verify OTP: $e')),
      );
    }
  }

  void _resetOtp() {
    setState(() {
      _isOtpSent = false;
      _requestId = null;
      _phoneNumber = null;
      _otpController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = ref.watch(authLoadingProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo and Title
              const Icon(
                Icons.play_circle_filled,
                size: 80,
                color: Color(0xFF6366F1),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to Streamshort',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your gateway to amazing short videos',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Login Form
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isOtpSent ? 'Verify OTP' : 'Get Started',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isOtpSent 
                          ? 'Enter the verification code sent to $_phoneNumber'
                          : 'Enter your phone number to receive a verification code',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      if (!_isOtpSent) ...[
                        TextField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            hintText: 'Enter phone number',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: isLoading ? null : _sendOtp,
                          child: isLoading 
                            ? const CircularProgressIndicator()
                            : const Text('Send OTP'),
                        ),
                      ] else ...[
                        TextField(
                          controller: _otpController,
                          decoration: const InputDecoration(
                            hintText: 'Enter 6-digit OTP',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _verifyOtp,
                                child: isLoading 
                                  ? const CircularProgressIndicator()
                                  : const Text('Verify OTP'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            TextButton(
                              onPressed: isLoading ? null : _resetOtp,
                              child: const Text('Change Phone'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Access Buttons (for demo purposes)
              if (!_isOtpSent) ...[
                Text(
                  'Or try the demo features:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserProfileScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.person),
                        label: const Text('User Profile'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreatorDashboardRedirect(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.dashboard),
                        label: const Text('Creator Dashboard'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Browse Content'),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Terms and Privacy
              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

}

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
    
    // Debug logging
    // print('UserProfileScreen build - user role: ${user?.role}');
    
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
                      builder: (context) => const CreatorDashboardRedirect(),
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
        return _SubscriptionSheet(ref: ref);
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

class _SubscriptionSheet extends StatefulWidget {
  final WidgetRef ref;
  const _SubscriptionSheet({required this.ref});

  @override
  State<_SubscriptionSheet> createState() => _SubscriptionSheetState();
}

class _SubscriptionSheetState extends State<_SubscriptionSheet> {
  bool _isLoading = true;
  String? _error;
  List<SubscriptionPlan> _plans = [];
  Subscription? _current;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final subRepo = widget.ref.read(subscriptionRepositoryProvider);
      final plans = await subRepo.getSubscriptionPlans();
      final current = await subRepo.getUserSubscription();
      setState(() {
        _plans = plans;
        _current = current;
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
            : _error != null
                ? SizedBox(
                    height: 200,
                    child: Column(
                      children: [
                        Text('Failed to load subscriptions', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Subscription', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          if (_current != null)
                            Chip(
                              label: Text(_current!.status),
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_current != null)
                        Text('Current plan: ${_current!.planId}', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _plans.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final p = _plans[i];
                          final isActive = _current?.planId == p.id;
                          return Card(
                            child: ListTile(
                              title: Text(p.name),
                              subtitle: Text(p.description),
                              trailing: isActive
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : _isCreating
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                      : ElevatedButton(
                                          onPressed: () async {
                                            setState(() => _isCreating = true);
                                            try {
                                              final req = CreateSubscriptionRequest(
                                                targetType: 'plan',
                                                targetId: p.id,
                                                planId: p.id,
                                                autoRenew: true,
                                              );
                                              final subRepo = widget.ref.read(subscriptionRepositoryProvider);
                                              await subRepo.createSubscription(
                                                targetType: 'plan',
                                                targetId: p.id,
                                                planId: p.id,
                                                autoRenew: true,
                                              );
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Subscription created successfully')),
                                                );
                                                await _load();
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Failed to subscribe: $e')),
                                                );
                                              }
                                            } finally {
                                              if (mounted) setState(() => _isCreating = false);
                                            }
                                          },
                                          child: const Text('Choose'),
                                        ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
      ),
    );
  }
}

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
      final data = await repo.getCreatorDashboard(accessToken: accessToken);

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
                            '${_dashboardData!.totalSeries}',
                            Icons.people,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCreatorStat(
                            context,
                            'Total Episodes',
                            '${_dashboardData!.totalEpisodes}',
                            Icons.favorite,
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
              '${_dashboardData!.totalSeries} series',
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

// Redirect to the new comprehensive Creator Dashboard
// Redirect widget for the creator dashboard
class CreatorDashboardRedirect extends ConsumerWidget {
  const CreatorDashboardRedirect({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const CreatorDashboardScreen();
  }
}

class CreatorProfileScreen extends ConsumerStatefulWidget {
  const CreatorProfileScreen({super.key});

  @override
  ConsumerState<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends ConsumerState<CreatorProfileScreen> {
  CreatorProfile? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final repo = ref.read(creatorRepositoryProvider);
      final accessToken = ref.read(accessTokenProvider);
      final prof = await repo.getCreatorProfile(accessToken: accessToken);
      setState(() {
        _profile = prof;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showEditProfileDialog(BuildContext context) async {
    final nameCtrl = TextEditingController(text: _profile!.displayName);
    final bioCtrl = TextEditingController(text: _profile!.bio ?? '');
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              title: const Text('Edit Creator Profile'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      border: OutlineInputBorder(),
                    ),
                    controller: nameCtrl,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      border: OutlineInputBorder(),
                    ),
                    controller: bioCtrl,
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Display name is required')),
                            );
                            return;
                          }
                          
                          setModalState(() => saving = true);
                          try {
                            final repo = ref.read(creatorRepositoryProvider);
                            final accessToken = ref.read(accessTokenProvider);
                            await repo.updateCreatorProfile(
                              displayName: nameCtrl.text.trim(),
                              bio: bioCtrl.text.trim().isEmpty ? null : bioCtrl.text.trim(),
                              accessToken: accessToken,
                            );
                            await _load();
                            if (mounted) {
                              Navigator.pop(ctx);
                              await _load();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Profile updated successfully')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to update profile: $e')),
                              );
                            }
                          } finally {
                            setModalState(() => saving = false);
                          }
                        },
                  child: saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openOnboardSheet() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final bioCtrl = TextEditingController();
    final websiteCtrl = TextEditingController();
    final socialsCtrl = TextEditingController();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
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
                  Text('Creator Onboarding', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()), controller: nameCtrl),
                  const SizedBox(height: 12),
                  TextField(decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()), controller: emailCtrl, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  TextField(decoration: const InputDecoration(labelText: 'Bio', border: OutlineInputBorder()), controller: bioCtrl, maxLines: 2),
                  const SizedBox(height: 12),
                  TextField(decoration: const InputDecoration(labelText: 'Website', border: OutlineInputBorder()), controller: websiteCtrl),
                  const SizedBox(height: 12),
                  TextField(decoration: const InputDecoration(labelText: 'Social Links', border: OutlineInputBorder()), controller: socialsCtrl),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: saving
                          ? null
                          : () async {
                              setModalState(() => saving = true);
                              try {
                                final repo = ref.read(creatorRepositoryProvider);
                                final accessToken = ref.read(accessTokenProvider);
                                await repo.onboardCreator(
                                  displayName: nameCtrl.text.trim(),
                                  bio: bioCtrl.text.trim().isEmpty ? null : bioCtrl.text.trim(),
                                  kycDocumentS3Path: 's3://demo/kyc_doc_${DateTime.now().millisecondsSinceEpoch}.jpg',
                                  accessToken: accessToken,
                                );
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  await _load();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Creator profile created')),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to onboard: $e')),
                                  );
                                }
                              } finally {
                                setModalState(() => saving = false);
                              }
                            },
                      icon: saving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send),
                      label: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Creator Profile'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Creator Profile'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_profile == null) {
      // Not onboarded yet
      return Scaffold(
        appBar: AppBar(
          title: const Text('Creator Profile'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No creator profile found'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _openOnboardSheet,
                icon: const Icon(Icons.add),
                label: const Text('Onboard as Creator'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  child: Text(_profile!.displayName.isNotEmpty ? _profile!.displayName.substring(0, 1).toUpperCase() : '?'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_profile!.displayName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text(_profile!.kycStatus, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditProfileDialog(context),
                  tooltip: 'Edit Profile',
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_profile!.bio != null && _profile!.bio!.isNotEmpty) ...[
              Text('About', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_profile!.bio!),
              const SizedBox(height: 16),
            ],

          ],
        ),
      ),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedLanguage = 'All';
  Timer? _searchDebounce;

  final List<String> _categories = ['All', 'Action', 'Comedy', 'Drama', 'Horror', 'Romance', 'Sci-Fi'];
  final List<String> _languages = ['All', 'English', 'Hindi', 'Spanish', 'French', 'German'];

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to avoid modifying providers during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContent();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadContent() async {
    try {
      final includeAdultContent = ref.read(adultContentFilterProvider);
      await ref.read(contentNotifierProvider.notifier).loadSeries(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        language: _selectedLanguage == 'All' ? null : _selectedLanguage,
        includeAdultContent: includeAdultContent,
        refresh: true,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load content: $e')),
        );
      }
    }
  }

  void _onCategoryChanged(String? category) {
    if (category != null && category != _selectedCategory) {
      setState(() {
        _selectedCategory = category;
      });
      // Use post-frame callback to avoid modifying providers during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadContent();
      });
    }
  }

  void _onLanguageChanged(String? language) {
    if (language != null && language != _selectedLanguage) {
      setState(() {
        _selectedLanguage = language;
      });
      // Use post-frame callback to avoid modifying providers during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadContent();
      });
    }
  }

  void _onSearchChanged(String query) {
    // Cancel previous timer
    _searchDebounce?.cancel();
    
    // Set new timer for debounced search
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      // Use post-frame callback to avoid modifying providers during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (query.trim().isEmpty) {
          ref.read(contentNotifierProvider.notifier).refreshContent();
        } else {
          ref.read(contentNotifierProvider.notifier).searchSeries(query);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final contentState = ref.watch(contentNotifierProvider);
    final series = ref.watch(seriesListProvider);
    final hasMore = ref.watch(hasMoreContentProvider);
    final isLoading = ref.watch(contentLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Streamshort'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: EnvironmentConfig.isDevelopment 
                  ? Colors.orange 
                  : EnvironmentConfig.isStaging 
                    ? Colors.blue 
                    : Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                EnvironmentConfig.environment.name.substring(0, 3).toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildContentFromState(contentState),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showEnvironmentDialog(context);
        },
        backgroundColor: EnvironmentConfig.isDevelopment 
          ? Colors.orange 
          : EnvironmentConfig.isStaging 
            ? Colors.blue 
            : Colors.green,
        child: const Icon(Icons.settings, color: Colors.white),
      ),
    );
  }


  Widget _buildContentFromState(ContentState contentState) {
    if (contentState is ContentInitial) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No content loaded',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Pull down to refresh or use the search bar',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else if (contentState is ContentLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading content...'),
          ],
        ),
      );
    } else if (contentState is ContentLoaded) {
      return RefreshIndicator(
        onRefresh: () async {
          await ref.read(contentNotifierProvider.notifier).refreshContent();
        },
        child: _buildHome(contentState.series),
      );
    } else if (contentState is ContentError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${contentState.message}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadContent,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(contentNotifierProvider.notifier).clearError();
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Dismiss'),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return const Center(
      child: Text('Unknown state'),
    );
  }

  Widget _buildContentList(List<Series> series, bool hasMore) {
    if (series.isEmpty) {
      return const Center(
        child: Text('No series found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: series.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == series.length) {
          // Load more button
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  ref.read(contentNotifierProvider.notifier).loadMoreSeries(
                    category: _selectedCategory == 'All' ? null : _selectedCategory,
                    language: _selectedLanguage == 'All' ? null : _selectedLanguage,
                  );
                },
                child: const Text('Load More'),
              ),
            ),
          );
        }

        final seriesItem = series[index];
        return _buildSeriesCard(context, seriesItem);
      },
    );
  }

  Widget _buildSeriesCard(BuildContext context, Series series) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              image: null,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CachedNetworkImage(
                      imageUrl: series.thumbnailUrl ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey.shade900,
                        highlightColor: Colors.grey.shade800,
                        child: Container(color: Colors.grey.shade900),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade900,
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.white54),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      series.priceType == 'free' ? 'FREE' : 'PREMIUM',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'New',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  series.title ?? 'Untitled',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  series.synopsis ?? 'No description available',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                
                // Tags
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text(series.category),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    Chip(
                      label: Text(series.language ?? 'Unknown'),
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    ),
                    Chip(
                      label: Text(series.priceType == 'free' ? 'FREE' : 'PREMIUM'),
                      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Navigate to series detail
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Series detail for ${series.title} coming soon!')),
                          );
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Watch'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Add to watchlist
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Added ${series.title} to watchlist!')),
                          );
                        },
                        icon: const Icon(Icons.bookmark_add),
                        label: const Text('Watchlist'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hotstar-style home layout
  Widget _buildHome(List<Series> allSeries) {
    // Build sections
    final List<Series> featured = List<Series>.from(allSeries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final List<Series> trending = featured.take(10).toList();

    final List<Series> topRated = List<Series>.from(allSeries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final List<Series> newReleases = List<Series>.from(allSeries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final Map<String, List<Series>> byCategory = <String, List<Series>>{};
    for (final s in allSeries) {
      byCategory.putIfAbsent(s.category, () => <Series>[]).add(s);
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: 12)),
        if (featured.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildHeroCarousel(featured.take(5).toList()),
          ),
        if (trending.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildRailSection('Trending Now', trending),
          ),
        if (topRated.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildRailSection('Top Rated', topRated.take(10).toList()),
          ),
        if (newReleases.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildRailSection('New Releases', newReleases.take(10).toList()),
          ),
        for (final entry in byCategory.entries)
          if (entry.value.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildRailSection(entry.key, entry.value),
            ),
        SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildHeroCarousel(List<Series> featured) {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.92),
        itemCount: featured.length,
        itemBuilder: (context, index) {
          final s = featured[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SeriesDetailScreen(seriesId: s.id),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: s.thumbnailUrl ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey.shade900,
                        highlightColor: Colors.grey.shade800,
                        child: Container(color: Colors.grey.shade900),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade900,
                        child: const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.title ?? 'Untitled',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [const Shadow(offset: Offset(0, 1), blurRadius: 2)],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.synopsis ?? 'No description available',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SeriesDetailScreen(seriesId: s.id),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Watch'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.info_outline),
                                label: const Text('More Info'),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRailSection(String title, List<Series> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final s = items[index];
                return _buildPosterCard(s);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterCard(Series s) {
    return SizedBox(
      width: 140,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SeriesDetailScreen(seriesId: s.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: s.thumbnailUrl ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey.shade900,
                    highlightColor: Colors.grey.shade800,
                    child: Container(color: Colors.grey.shade900),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade900,
                    child: const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              s.title ?? 'Untitled',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 2),
                Text('New', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEnvironmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Environment',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(
                Icons.developer_mode,
                color: EnvironmentConfig.isDevelopment ? Colors.orange : Colors.grey,
              ),
              title: const Text('Development'),
              subtitle: const Text('localhost:8080'),
              selected: EnvironmentConfig.isDevelopment,
              onTap: () {
                EnvironmentConfig.setEnvironment(Environment.development);
                Navigator.pop(context);
                setState(() {});
                // Refresh content with new environment
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _loadContent();
                });
              },
            ),
            ListTile(
              leading: Icon(
                Icons.assessment,
                color: EnvironmentConfig.isStaging ? Colors.blue : Colors.grey,
              ),
              title: const Text('Staging'),
              subtitle: const Text('staging-api.streamshort.in'),
              selected: EnvironmentConfig.isStaging,
              onTap: () {
                EnvironmentConfig.setEnvironment(Environment.staging);
                Navigator.pop(context);
                setState(() {});
                // Refresh content with new environment
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _loadContent();
                });
              },
            ),
            ListTile(
              leading: Icon(
                Icons.cloud,
                color: EnvironmentConfig.isProduction ? Colors.green : Colors.grey,
              ),
              title: const Text('Production'),
              subtitle: const Text('api.streamshort.in'),
              selected: EnvironmentConfig.isProduction,
              onTap: () {
                EnvironmentConfig.setEnvironment(Environment.production);
                Navigator.pop(context);
                setState(() {});
                // Refresh content with new environment
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _loadContent();
                });
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Content Filters',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, _) {
                final includeAdultContent = ref.watch(adultContentFilterProvider);
                return SwitchListTile(
                  title: const Text('Show Adult Content'),
                  subtitle: const Text('Include mature content in search results'),
                  value: includeAdultContent,
                  onChanged: (value) {
                    ref.read(adultContentFilterProvider.notifier).state = value;
                    Navigator.pop(context);
                    // Refresh content with new filter
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _loadContent();
                    });
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
