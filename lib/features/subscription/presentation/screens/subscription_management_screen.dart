import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_providers.dart';
import '../widgets/subscription_list.dart';

class SubscriptionManagementScreen extends ConsumerWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subscriptions'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const SubscriptionList(),
    );
  }
}
