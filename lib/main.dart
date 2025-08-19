import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/content/presentation/providers/content_providers.dart';
import 'core/api/api_client.dart';

import 'core/config/environment.dart';

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
    return MaterialApp(
      title: 'Streamshort',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

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
                              builder: (context) => const CreatorDashboardScreen(),
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
  User? _user;
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
        setState(() {
          _user = authUser;
          _isLoading = false;
        });
        return;
      }

      // If not authenticated, show demo data
      setState(() {
        _user = User(
          id: 'demo_user_1',
          phone: '+919876543210',
          name: 'John Doe',
          email: 'john.doe@example.com',
          role: 'user',
          avatar: null,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        );
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
                      child: _user?.avatar != null
                          ? ClipOval(
                              child: Image.network(
                                _user!.avatar!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.white,
                                  );
                                },
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
                            _user?.name ?? 'User',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _user?.role == 'premium' ? 'Premium Member' : 'Free Member',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Member since ${_user?.createdAt != null ? _formatDate(_user!.createdAt) : 'Unknown'}',
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
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Likes Given',
                    '89',
                    Icons.favorite_outline,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Comments',
                    '15',
                    Icons.comment,
                  ),
                ),
              ],
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
            // Creator actions
            Text(
              'Creator',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              context,
              'Creator Profile',
              Icons.person_outline,
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
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.year}';
  }

  Future<void> _openEditProfileSheet() async {
    if (_user == null) return;
    final nameController = TextEditingController(text: _user?.name ?? '');
    final emailController = TextEditingController(text: _user?.email ?? '');

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
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
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
                              name: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
                              email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                            );
                            if (mounted) {
                              setState(() => _user = updated);
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
  List<SubscriptionPlan> _plans = const [];
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
                                              final req = PaymentCreateRequest(planId: p.id, paymentMethod: 'razorpay');
                                              final subRepo = widget.ref.read(subscriptionRepositoryProvider);
                                              final resp = await subRepo.createSubscription(req);
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Payment created. Open URL: ${resp.paymentUrl}')),
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

class CreatorDashboardScreen extends ConsumerStatefulWidget {
  const CreatorDashboardScreen({super.key});

  @override
  ConsumerState<CreatorDashboardScreen> createState() => _CreatorDashboardScreenState();
}

class _CreatorDashboardScreenState extends ConsumerState<CreatorDashboardScreen> {
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
      final data = await repo.getCreatorDashboard();

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
                            '${(_dashboardData!.totalViews / 1000).toStringAsFixed(1)}K',
                            Icons.visibility,
                          ),
                        ),
                        Expanded(
                          child: _buildCreatorStat(
                            context,
                            'Subscribers',
                            '${(_dashboardData!.totalSubscribers / 1000).toStringAsFixed(1)}K',
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
                            'Total Likes',
                            '${(_dashboardData!.totalLikes / 1000).toStringAsFixed(1)}K',
                            Icons.favorite,
                          ),
                        ),
                        Expanded(
                          child: _buildCreatorStat(
                            context,
                            'Revenue',
                            '\$${_dashboardData!.totalRevenue.toStringAsFixed(1)}K',
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
              '${_dashboardData!.series.length} series',
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
      final prof = await repo.getCreatorProfile();
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
                                await repo.onboardCreator(
                                  name: nameCtrl.text.trim(),
                                  email: emailCtrl.text.trim(),
                                  bio: bioCtrl.text.trim().isEmpty ? null : bioCtrl.text.trim(),
                                  website: websiteCtrl.text.trim().isEmpty ? null : websiteCtrl.text.trim(),
                                  socialLinks: socialsCtrl.text.trim().isEmpty ? null : socialsCtrl.text.trim(),
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
                  child: Text(_profile!.name.isNotEmpty ? _profile!.name.substring(0, 1).toUpperCase() : '?'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_profile!.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text(_profile!.email, style: Theme.of(context).textTheme.bodyMedium),
                    ],
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
            if (_profile!.website != null && _profile!.website!.isNotEmpty) ...[
              Text('Website', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_profile!.website!),
              const SizedBox(height: 16),
            ],
            if (_profile!.socialLinks != null && _profile!.socialLinks!.isNotEmpty) ...[
              Text('Social', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_profile!.socialLinks!),
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
      await ref.read(contentNotifierProvider.notifier).loadSeries(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        language: _selectedLanguage == 'All' ? null : _selectedLanguage,
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
              // TODO: Implement search
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search functionality coming soon!')),
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
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search series...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                  ),
                  onChanged: _onSearchChanged,
                  onSubmitted: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                ),
                const SizedBox(height: 16),
                
                // Category and Language Filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          prefixIcon: const Icon(Icons.category),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: _onCategoryChanged,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedLanguage,
                        decoration: InputDecoration(
                          labelText: 'Language',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          prefixIcon: const Icon(Icons.language),
                        ),
                        items: _languages.map((language) {
                          return DropdownMenuItem(
                            value: language,
                            child: Text(language),
                          );
                        }).toList(),
                        onChanged: _onLanguageChanged,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _buildContentFromState(contentState),
          ),
        ],
      ),
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
        child: _buildContentList(contentState.series, contentState.hasMore),
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
              image: DecorationImage(
                image: NetworkImage(series.thumbnail),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {
                  // Handle image loading error
                },
              ),
            ),
            child: Stack(
              children: [
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
                          series.rating.toStringAsFixed(1),
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
                  series.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  series.synopsis,
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
                      label: Text(series.language),
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    ),
                    Chip(
                      label: Text('${series.episodeCount} episodes'),
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

  void _showEnvironmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch Environment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
