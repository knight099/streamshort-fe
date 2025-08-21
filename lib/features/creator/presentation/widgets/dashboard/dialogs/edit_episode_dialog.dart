import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/creator_models.dart';
import '../../../../data/providers.dart';
import '../../../../../auth/presentation/providers/auth_providers.dart';

class EditEpisodeDialog extends ConsumerStatefulWidget {
  final CreatorEpisode episode;

  const EditEpisodeDialog({super.key, required this.episode});

  @override
  ConsumerState<EditEpisodeDialog> createState() => _EditEpisodeDialogState();
}

class _EditEpisodeDialogState extends ConsumerState<EditEpisodeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _episodeNumberController;
  late TextEditingController _durationSecondsController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.episode.title);
    _episodeNumberController = TextEditingController(text: widget.episode.episodeNumber.toString());
    _durationSecondsController = TextEditingController(text: widget.episode.durationSeconds.toString());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _episodeNumberController.dispose();
    _durationSecondsController.dispose();
    super.dispose();
  }

  Future<void> _updateEpisode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final accessToken = ref.read(accessTokenProvider);
      await ref.read(creatorRepositoryProvider).updateEpisode(
            episodeId: widget.episode.id,
            title: _titleController.text.trim(),
            episodeNumber: int.parse(_episodeNumberController.text.trim()),
            durationSeconds: int.parse(_durationSecondsController.text.trim()),
            accessToken: accessToken,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Episode updated successfully!')),
        );
        Navigator.pop(context, true); // Indicate success and refresh needed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update episode: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Episode'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _episodeNumberController,
                decoration: const InputDecoration(labelText: 'Episode Number'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an episode number';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _durationSecondsController,
                decoration: const InputDecoration(labelText: 'Duration (seconds)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter duration in seconds';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateEpisode,
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('Update Episode'),
        ),
      ],
    );
  }
}
