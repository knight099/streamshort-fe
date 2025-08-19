import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreatorOnboardingScreen extends ConsumerWidget {
  const CreatorOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Onboarding'),
      ),
      body: const Center(
        child: Text('Creator Onboarding Screen'),
      ),
    );
  }
}
