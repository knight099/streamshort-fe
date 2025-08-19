import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EpisodePlayerScreen extends ConsumerWidget {
  final String episodeId;

  const EpisodePlayerScreen({super.key, required this.episodeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Episode Player'),
      ),
      body: Center(
        child: Text('Episode Player for ID: $episodeId'),
      ),
    );
  }
}
