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
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
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
      await ref.read(creatorRepositoryProvider).createEpisode(
        seriesId: widget.seriesId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Episode created successfully!'),
          ),
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