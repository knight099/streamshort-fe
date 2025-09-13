// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../data/models/auth_models.dart';
// import '../providers/auth_providers.dart';
// import '../../../profile/presentation/screens/profile_screen.dart';
// import '../../../creator/presentation/screens/dashboard/creator_dashboard_screen.dart';
// import '../../../content/presentation/screens/home_screen.dart';
// import '../../../creator/presentation/screens/creator_onboarding_screen.dart';
// import '../../../subscription/presentation/screens/subscription_management_screen.dart';
// import '../../../content/presentation/screens/liked_videos_screen.dart';
// import '../../../creator/presentation/screens/following_screen.dart';
// import '../../../profile/data/repositories/profile_repository.dart';
// import '../../../creator/data/repositories/creator_repository.dart';
// import '../../../subscription/data/repositories/subscription_repository.dart';
// import '../../../subscription/data/models/subscription_models.dart';
// import '../../../profile/presentation/providers/profile_providers.dart';
// import '../../../creator/data/providers.dart';
// import '../../../subscription/data/providers.dart';

// class LoginScreen extends ConsumerStatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   ConsumerState<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends ConsumerState<LoginScreen> {
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _otpController = TextEditingController();
//   bool _isOtpSent = false;
//   String? _requestId;
//   String? _phoneNumber;

//   @override
//   void dispose() {
//     _phoneController.dispose();
//     _otpController.dispose();
//     super.dispose();
//   }

//   Future<void> _sendOtp() async {
//     if (_phoneController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please enter a phone number')),
//       );
//       return;
//     }

//     try {
//       await ref.read(authNotifierProvider.notifier).sendOtp(_phoneController.text.trim());
//         setState(() {
//           _isOtpSent = true;
//         _phoneNumber = _phoneController.text.trim();
//         // In a real app, you'd get the requestId from the response
//         _requestId = 'demo_request_id_${DateTime.now().millisecondsSinceEpoch}';
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('OTP sent successfully!')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to send OTP: $e')),
//       );
//     }
//   }

//   Future<void> _verifyOtp() async {
//     if (_otpController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please enter the OTP')),
//       );
//       return;
//     }

//     try {
//       await ref.read(authNotifierProvider.notifier).verifyOtp(
//         _phoneNumber!,
//         _otpController.text.trim(),
//         _requestId!,
//       );
      
//       // Fetch the complete user profile to get the correct role
//       try {
//         final profileRepo = ref.read(profileRepositoryProvider);
//         final userProfile = await profileRepo.getUserProfile();
        
//         // Update the user in auth state with the complete profile
//         if (userProfile.role != 'user') {
//           await ref.read(authNotifierProvider.notifier).updateUserRole(userProfile.role);
//         }
//       } catch (e) {
//         // If profile fetch fails, check for creator profile as fallback
//         try {
//           final accessToken = ref.read(accessTokenProvider);
//           if (accessToken != null) {
//             final creatorRepo = ref.read(creatorRepositoryProvider);
//             final creatorProfile = await creatorRepo.getCreatorProfile(accessToken: accessToken);
//             if (creatorProfile != null) {
//               // User has a creator profile, update their role
//               await ref.read(authNotifierProvider.notifier).updateUserRole('creator');
//             }
//           }
//         } catch (e2) {
//           // If both profile fetch and creator profile check fail, continue with regular user
//           print('Profile fetch and creator profile check failed: $e, $e2');
//         }
//       }
      
//       // Navigate to home screen on successful authentication
//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => const HomeScreen(),
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to verify OTP: $e')),
//       );
//     }
//   }

//   void _resetOtp() {
//     setState(() {
//       _isOtpSent = false;
//       _requestId = null;
//       _phoneNumber = null;
//       _otpController.clear();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authState = ref.watch(authNotifierProvider);
//     final isLoading = ref.watch(authLoadingProvider);
    
//     return Scaffold(
//       body: SafeArea(
//           child: Padding(
//           padding: const EdgeInsets.all(24.0),
//                 child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//               // App Logo and Title
//               const Icon(
//                 Icons.play_circle_filled,
//                 size: 80,
//                 color: Color(0xFF6366F1),
//                           ),
//                           const SizedBox(height: 24),
//                           Text(
//                 'Welcome to Streamshort',
//                 style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                               fontWeight: FontWeight.bold,
//                             ),
//                 textAlign: TextAlign.center,
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                 'Your gateway to amazing short videos',
//                 style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                   color: Theme.of(context).colorScheme.onSurfaceVariant,
//                 ),
//                             textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 48),

//               // Login Form
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(24.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       Text(
//                         _isOtpSent ? 'Verify OTP' : 'Get Started',
//                         style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                           fontWeight: FontWeight.w600,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         _isOtpSent 
//                           ? 'Enter the verification code sent to $_phoneNumber'
//                           : 'Enter your phone number to receive a verification code',
//                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                           color: Theme.of(context).colorScheme.onSurfaceVariant,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                       const SizedBox(height: 24),

//                       if (!_isOtpSent) ...[
//                         TextField(
//                           controller: _phoneController,
//                           decoration: const InputDecoration(
//                             hintText: 'Enter phone number',
//                             border: OutlineInputBorder(),
//                             prefixIcon: Icon(Icons.phone),
//                           ),
//                               keyboardType: TextInputType.phone,
//                           enabled: !isLoading,
//                         ),
//                         const SizedBox(height: 24),
//                         ElevatedButton(
//                           onPressed: isLoading ? null : _sendOtp,
//                           child: isLoading 
//                             ? const CircularProgressIndicator()
//                             : const Text('Send OTP'),
//                         ),
//                       ] else ...[
//                         TextField(
//                           controller: _otpController,
//                           decoration: const InputDecoration(
//                             hintText: 'Enter 6-digit OTP',
//                             border: OutlineInputBorder(),
//                             prefixIcon: Icon(Icons.lock),
//                           ),
//                                         keyboardType: TextInputType.number,
//                                         maxLength: 6,
//                           enabled: !isLoading,
//                         ),
//                         const SizedBox(height: 24),
//                         Row(
//                           children: [
//                             Expanded(
//                             child: ElevatedButton(
//                                 onPressed: isLoading ? null : _verifyOtp,
//                                 child: isLoading 
//                                   ? const CircularProgressIndicator()
//                                   : const Text('Verify OTP'),
//                               ),
//                             ),
//                             const SizedBox(width: 16),
//                             TextButton(
//                               onPressed: isLoading ? null : _resetOtp,
//                               child: const Text('Change Phone'),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),

//               // Quick Access Buttons (for demo purposes)
//               if (!_isOtpSent) ...[
//                                   Text(
//                   'Or try the demo features:',
//                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                     color: Theme.of(context).colorScheme.onSurfaceVariant,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 16),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton.icon(
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => const UserProfileScreen(),
//                             ),
//                           );
//                         },
//                         icon: const Icon(Icons.person),
//                         label: const Text('User Profile'),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: OutlinedButton.icon(
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => const CreatorDashboardRedirect(),
//                             ),
//                           );
//                         },
//                         icon: const Icon(Icons.dashboard),
//                         label: const Text('Creator Dashboard'),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 SizedBox(
//                   width: double.infinity,
//                   child: OutlinedButton.icon(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const HomeScreen(),
//                         ),
//                       );
//                     },
//                     icon: const Icon(Icons.home),
//                     label: const Text('Browse Content'),
//                   ),
//                 ),
//               ],

//               const SizedBox(height: 24),

//               // Terms and Privacy
//               Text(
//                 'By continuing, you agree to our Terms of Service and Privacy Policy',
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                   color: Theme.of(context).colorScheme.onSurfaceVariant,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// Redirect widget for the creator dashboard
// class CreatorDashboardRedirect extends ConsumerWidget {
//   const CreatorDashboardRedirect({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return const CreatorDashboardScreen();
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/auth_models.dart';
import '../providers/auth_providers.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../creator/presentation/screens/dashboard/creator_dashboard_screen.dart';
import '../../../content/presentation/screens/home_screen.dart';
import '../../../creator/presentation/screens/creator_onboarding_screen.dart';
import '../../../subscription/presentation/screens/subscription_management_screen.dart';
import '../../../content/presentation/screens/liked_videos_screen.dart';
import '../../../creator/presentation/screens/following_screen.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../../creator/data/repositories/creator_repository.dart';
import '../../../subscription/data/repositories/subscription_repository.dart';
import '../../../subscription/data/models/subscription_models.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../creator/data/providers.dart';
import '../../../subscription/data/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with TickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final PageController _pageController = PageController();
  
  bool _isOtpSent = false;
  String? _requestId;
  String? _phoneNumber;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Create animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);

    // Set status bar
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.trim().isEmpty) {
      _showCustomSnackBar('Please enter a valid phone number', isError: true);
      return;
    }

    // Add haptic feedback
    HapticFeedback.lightImpact();

    try {
      await ref.read(authNotifierProvider.notifier).sendOtp(_phoneController.text.trim());
      
      setState(() {
        _isOtpSent = true;
        _phoneNumber = _phoneController.text.trim();
        _requestId = 'demo_request_id_${DateTime.now().millisecondsSinceEpoch}';
      });

      // Animate to OTP screen
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      _showCustomSnackBar('Verification code sent successfully!', isError: false);
      
      // Auto-focus OTP field
      Future.delayed(const Duration(milliseconds: 400), () {
        FocusScope.of(context).nextFocus();
      });

    } catch (e) {
      _showCustomSnackBar('Failed to send OTP. Please try again.', isError: true);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length != 6) {
      _showCustomSnackBar('Please enter the complete 6-digit code', isError: true);
      return;
    }

    HapticFeedback.mediumImpact();

    try {
      await ref.read(authNotifierProvider.notifier).verifyOtp(
        _phoneNumber!,
        _otpController.text.trim(),
        _requestId!,
      );
      
      // Fetch user profile and update role
      await _updateUserRole();
      
      if (mounted) {
        HapticFeedback.heavyImpact();
        _showCustomSnackBar('Welcome to Streamshort!', isError: false);
        
        // Navigate with smooth transition
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      _showCustomSnackBar('Invalid code. Please check and try again.', isError: true);
    }
  }

  Future<void> _updateUserRole() async {
    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      final userProfile = await profileRepo.getUserProfile();
      
      if (userProfile.role != 'user') {
        await ref.read(authNotifierProvider.notifier).updateUserRole(userProfile.role);
      }
    } catch (e) {
      try {
        final accessToken = ref.read(accessTokenProvider);
        if (accessToken != null) {
          final creatorRepo = ref.read(creatorRepositoryProvider);
          final creatorProfile = await creatorRepo.getCreatorProfile(accessToken: accessToken);
          if (creatorProfile != null) {
            await ref.read(authNotifierProvider.notifier).updateUserRole('creator');
          }
        }
      } catch (e2) {
        debugPrint('Profile fetch failed: $e, $e2');
      }
    }
  }

  void _showCustomSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  void _resetOtp() {
    setState(() {
      _isOtpSent = false;
      _requestId = null;
      _phoneNumber = null;
      _otpController.clear();
    });
    
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = ref.watch(authLoadingProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0F23),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F0F23),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPhoneInputScreen(isLoading),
                  _buildOtpVerificationScreen(isLoading),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInputScreen(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Spacer(),
          
          // Animated Logo Section
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6),
                        Color(0xFFEC4899),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_circle_filled,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 40),
          
          // Title with Gradient Text
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFF10B981)],
            ).createShader(bounds),
            child: const Text(
              'Welcome to Streamshort',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Discover amazing short videos\nfrom creators worldwide',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 60),
          
          // Phone Input Section
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Enter your phone number to receive\na verification code',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                _buildModernTextField(
                  controller: _phoneController,
                  hint: 'Enter phone number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  enabled: !isLoading,
                ),
                
                const SizedBox(height: 24),
                
                _buildGradientButton(
                  onPressed: isLoading ? null : _sendOtp,
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Send Verification Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Quick Demo Access
          _buildDemoSection(),
          
          const SizedBox(height: 24),
          
          // Terms and Privacy
          Text(
            'By continuing, you agree to our Terms of Service\nand Privacy Policy',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpVerificationScreen(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Spacer(),
          
          // Back Button
          Row(
            children: [
              IconButton(
                onPressed: isLoading ? null : _resetOtp,
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // OTP Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 40,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            'Verify Your Number',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'We\'ve sent a 6-digit verification code to\n$_phoneNumber',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          // OTP Input
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Column(
              children: [
                _buildOtpTextField(
                  controller: _otpController,
                  enabled: !isLoading,
                ),
                
                const SizedBox(height: 32),
                
                _buildGradientButton(
                  onPressed: isLoading ? null : _verifyOtp,
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verify Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                
                const SizedBox(height: 16),
                
                TextButton(
                  onPressed: isLoading ? null : () {
                    // TODO: Implement resend OTP
                    _showCustomSnackBar('Code resent successfully!', isError: false);
                  },
                  child: Text(
                    'Didn\'t receive the code? Resend',
                    style: TextStyle(
                      color: const Color(0xFF6366F1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.5),
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF6366F1),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildOtpTextField({
    required TextEditingController controller,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        enabled: enabled,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 8,
        ),
        decoration: InputDecoration(
          hintText: '• • • • • •',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.3),
            letterSpacing: 8,
          ),
          border: InputBorder.none,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: onPressed != null
            ? const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              )
            : LinearGradient(
                colors: [
                  Colors.grey.withOpacity(0.3),
                  Colors.grey.withOpacity(0.2),
                ],
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed != null ? [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ] : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildDemoSection() {
    return Column(
      children: [
        Text(
          'Quick Demo Access',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildDemoButton(
                'Profile',
                Icons.person_outline,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserProfileScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDemoButton(
                'Creator',
                Icons.dashboard_outlined,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatorDashboardRedirect(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDemoButton(
                'Browse',
                Icons.explore_outlined,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDemoButton(String label, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(
                icon,
                color: const Color(0xFF6366F1),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Enhanced Creator Dashboard Redirect
class CreatorDashboardRedirect extends ConsumerWidget {
  const CreatorDashboardRedirect({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const CreatorDashboardScreen();
  }
}

