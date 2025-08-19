import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:streamshort/core/theme.dart';
import 'package:streamshort/features/auth/presentation/providers/auth_providers.dart';
import 'package:streamshort/features/auth/presentation/widgets/otp_input_field.dart';

class OtpVerificationScreen extends HookConsumerWidget {
  final String phone;

  const OtpVerificationScreen({super.key, required this.phone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otpController = useTextEditingController();
    final isLoading = ref.watch(authLoadingProvider);
    final authState = ref.watch(authStateProvider);
    final countdown = useState(300); // 5 minutes countdown

    useEffect(() {
      // Start countdown timer
      final timer = Stream.periodic(const Duration(seconds: 1), (i) {
        if (countdown.value > 0) {
          countdown.value--;
        }
      }).listen((_) {});
      
      return timer.cancel;
    }, []);

    useEffect(() {
      // Listen to auth state changes
      ref.listen(authStateProvider, (previous, next) {
        if (next.isAuthenticated) {
          context.go('/home');
        }
      });
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Phone number display
              Text(
                'We\'ve sent a code to',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                phone,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // OTP Input
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Enter Verification Code',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the 6-digit code sent to your phone',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      OtpInputField(
                        controller: otpController,
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 24),
                      
                      ElevatedButton(
                        onPressed: isLoading || otpController.text.length != 6
                            ? null
                            : () async {
                                await ref
                                    .read(authProvider.notifier)
                                    .verifyOtp(phone, otpController.text);
                              },
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Verify OTP'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Resend OTP
              if (countdown.value > 0) ...[
                Text(
                  'Resend code in ${(countdown.value ~/ 60).toString().padLeft(2, '0')}:${(countdown.value % 60).toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ] else ...[
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          countdown.value = 300;
                          await ref
                              .read(authProvider.notifier)
                              .sendOtp(phone);
                        },
                  child: const Text('Resend Code'),
                ),
              ],

              const SizedBox(height: 16),

              // Change phone number
              TextButton(
                onPressed: isLoading ? null : () => context.pop(),
                child: const Text('Change Phone Number'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
