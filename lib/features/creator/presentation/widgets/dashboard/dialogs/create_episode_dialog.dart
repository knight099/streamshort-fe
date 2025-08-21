import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/creator_models.dart';
import '../../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../data/providers.dart';
import 'upload_episode_dialog.dart';

class CreateEpisodeDialog extends ConsumerStatefulWidget {
  final String? seriesId;

  const CreateEpisodeDialog({super.key, this.seriesId});

  @override
  ConsumerState<CreateEpisodeDialog> createState() => _CreateEpisodeDialogState();
}

class _CreateEpisodeDialogState extends ConsumerState<CreateEpisodeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  int _episodeNumber = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.seriesId != null) {
      // Get the next episode number for this series
      _loadNextEpisodeNumber();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadNextEpisodeNumber() async {
    try {
      final episodes = await ref.read(creatorRepositoryProvider).getCreatorEpisodes(widget.seriesId!);
      setState(() {
        _episodeNumber = episodes.total + 1;
      });
    } catch (e) {
      // If error, start with episode 1
      setState(() {
        _episodeNumber = 1;
      });
    }
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
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (seconds)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter duration';
                      }
                      final duration = int.tryParse(value);
                      if (duration == null || duration <= 0) {
                        return 'Please enter a valid duration';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Episode Number',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    controller: TextEditingController(text: _episodeNumber.toString()),
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

    setState(() => _isLoading = true);

    try {
      final request = CreateEpisodeRequest(
        seriesId: widget.seriesId!,
        title: _titleController.text.trim(),
        episodeNumber: _episodeNumber,
        durationSeconds: int.tryParse(_durationController.text) ?? 0,
      );

      final accessToken = ref.read(accessTokenProvider);
      final response = await ref.read(creatorRepositoryProvider).createEpisode(
        seriesId: request.seriesId,
        title: request.title,
        episodeNumber: request.episodeNumber,
        durationSeconds: request.durationSeconds,
        thumbUrl: request.thumbUrl,
        accessToken: accessToken,
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Episode created successfully! ID: ${response.id}'),
          ),
        );
        // Show upload dialog
        _showUploadDialog(response.id);
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

  void _showUploadDialog(String episodeId) {
    showDialog(
      context: context,
      builder: (context) => UploadEpisodeDialog(episodeId: episodeId),
    );
  }
}
