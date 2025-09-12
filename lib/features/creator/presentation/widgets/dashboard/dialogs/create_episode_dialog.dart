import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/creator_models.dart';
import '../../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../data/providers.dart';
import 'upload_episode_dialog.dart';

class CreateEpisodeDialog extends ConsumerStatefulWidget {
  final String? seriesId;
  final String? manifestUrl;

  const CreateEpisodeDialog({
    super.key,
    this.seriesId,
    this.manifestUrl,
  });

  @override
  ConsumerState<CreateEpisodeDialog> createState() => _CreateEpisodeDialogState();
}

class _CreateEpisodeDialogState extends ConsumerState<CreateEpisodeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _episodeNumberController = TextEditingController();
  final _durationMinutesController = TextEditingController();
  final _durationSecondsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _episodeNumberController.dispose();
    _durationMinutesController.dispose();
    _durationSecondsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Episode'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Episode Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _episodeNumberController,
              decoration: const InputDecoration(
                labelText: 'Episode Number',
                border: OutlineInputBorder(),
                hintText: 'e.g., 1, 2, 3...',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter episode number';
                }
                final number = int.tryParse(value.trim());
                if (number == null || number <= 0) {
                  return 'Please enter a valid episode number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _durationMinutesController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (Minutes)',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., 5',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final number = int.tryParse(value.trim());
                      if (number == null || number < 0) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _durationSecondsController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (Seconds)',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., 30',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final number = int.tryParse(value.trim());
                      if (number == null || number < 0 || number >= 60) {
                        return '0-59';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createEpisode,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createEpisode() async {
      if (!_formKey.currentState!.validate()) return;
    if (widget.seriesId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Series ID is required')),
      );
      return;
    }
    if (widget.manifestUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload the video first')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final accessToken = ref.read(accessTokenProvider);
      
      // Parse episode number
      final episodeNumber = int.parse(_episodeNumberController.text.trim());
      
      // Parse duration
      final minutes = int.parse(_durationMinutesController.text.trim());
      final seconds = int.parse(_durationSecondsController.text.trim());
      final durationSeconds = (minutes * 60) + seconds;
      
      final episodeId = await ref.read(creatorRepositoryProvider).createEpisode(
        seriesId: widget.seriesId!,
        title: _titleController.text.trim(),
        episodeNumber: episodeNumber,
        durationSeconds: durationSeconds,
        manifestUrl: widget.manifestUrl!,
        accessToken: accessToken,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Episode created successfully! Please upload the video.'),
          ),
        );
        Navigator.pop(context, true);
        
        // Show upload dialog
        showDialog(
          context: context,
          builder: (context) => UploadEpisodeDialog(episodeId: episodeId),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating episode: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}