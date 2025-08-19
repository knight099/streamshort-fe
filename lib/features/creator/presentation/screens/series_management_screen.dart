import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SeriesManagementScreen extends ConsumerWidget {
  const SeriesManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Series'),
      ),
      body: const Center(
        child: Text('Series Management Screen'),
      ),
    );
  }
}
