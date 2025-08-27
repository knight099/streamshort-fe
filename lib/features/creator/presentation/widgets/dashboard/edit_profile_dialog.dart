import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/creator_models.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../data/providers.dart';

class EditCreatorProfileDialog extends ConsumerStatefulWidget {
  final CreatorProfile creatorProfile;
  final Function(CreatorProfile) onProfileUpdated;

  const EditCreatorProfileDialog({
    super.key,
    required this.creatorProfile,
    required this.onProfileUpdated,
  });

  @override
  ConsumerState<EditCreatorProfileDialog> createState() => _EditCreatorProfileDialogState();
}

class _EditCreatorProfileDialogState extends ConsumerState<EditCreatorProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.creatorProfile.displayName);
    _bioController = TextEditingController(text: widget.creatorProfile.bio ?? '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final accessToken = ref.read(accessTokenProvider);
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      final creatorRepo = ref.read(creatorRepositoryProvider);
      await creatorRepo.updateCreatorProfile(
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        accessToken: accessToken,
      );

      final updatedProfile = widget.creatorProfile.copyWith(
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      );
      
      if (mounted) {
        widget.onProfileUpdated(updatedProfile);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Creator Profile'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                  hintText: 'Enter your display name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a display name';
                  }
                  if (value.trim().length < 2) {
                    return 'Display name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                  hintText: 'Tell us about yourself (optional)',
                ),
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'KYC Status: ${widget.creatorProfile.kycStatus.toUpperCase()}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.creatorProfile.isVerified 
                            ? Colors.green 
                            : widget.creatorProfile.isPending 
                                ? Colors.orange 
                                : Colors.red,
                      ),
                    ),
                  ),
                ],
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
          onPressed: _isLoading ? null : _updateProfile,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update Profile'),
        ),
      ],
    );
  }
}