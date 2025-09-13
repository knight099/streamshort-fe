import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/creator_models.dart';
import '../../data/repositories/creator_repository.dart';
import '../../data/providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class CreatorProfileScreen extends ConsumerStatefulWidget {
  const CreatorProfileScreen({super.key});

  @override
  ConsumerState<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends ConsumerState<CreatorProfileScreen> {
  CreatorProfile? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final repo = ref.read(creatorRepositoryProvider);
      final accessToken = ref.read(accessTokenProvider);
      final prof = await repo.getCreatorProfile(accessToken: accessToken);
      setState(() {
        _profile = prof;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showEditProfileDialog(BuildContext context) async {
    final nameCtrl = TextEditingController(text: _profile!.displayName);
    final bioCtrl = TextEditingController(text: _profile!.bio ?? '');
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              title: const Text('Edit Creator Profile'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      border: OutlineInputBorder(),
                    ),
                    controller: nameCtrl,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      border: OutlineInputBorder(),
                    ),
                    controller: bioCtrl,
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Display name is required')),
                            );
                            return;
                          }
                          
                          setModalState(() => saving = true);
                          try {
                            final repo = ref.read(creatorRepositoryProvider);
                            final accessToken = ref.read(accessTokenProvider);
                            await repo.updateCreatorProfile(
                              displayName: nameCtrl.text.trim(),
                              bio: bioCtrl.text.trim().isEmpty ? null : bioCtrl.text.trim(),
                              accessToken: accessToken,
                            );
                            await _load();
                            if (mounted) {
                              Navigator.pop(ctx);
                              await _load();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Profile updated successfully')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to update profile: $e')),
                              );
                            }
                          } finally {
                            setModalState(() => saving = false);
                          }
                        },
                  child: saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openOnboardSheet() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final bioCtrl = TextEditingController();
    final websiteCtrl = TextEditingController();
    final socialsCtrl = TextEditingController();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Creator Onboarding', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()), controller: nameCtrl),
                  const SizedBox(height: 12),
                  TextField(decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()), controller: emailCtrl, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  TextField(decoration: const InputDecoration(labelText: 'Bio', border: OutlineInputBorder()), controller: bioCtrl, maxLines: 2),
                  const SizedBox(height: 12),
                  TextField(decoration: const InputDecoration(labelText: 'Website', border: OutlineInputBorder()), controller: websiteCtrl),
                  const SizedBox(height: 12),
                  TextField(decoration: const InputDecoration(labelText: 'Social Links', border: OutlineInputBorder()), controller: socialsCtrl),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: saving
                          ? null
                          : () async {
                              setModalState(() => saving = true);
                              try {
                                final repo = ref.read(creatorRepositoryProvider);
                                final accessToken = ref.read(accessTokenProvider);
                                await repo.onboardCreator(
                                  displayName: nameCtrl.text.trim(),
                                  bio: bioCtrl.text.trim().isEmpty ? null : bioCtrl.text.trim(),
                                  kycDocumentS3Path: 's3://demo/kyc_doc_${DateTime.now().millisecondsSinceEpoch}.jpg',
                                  accessToken: accessToken,
                                );
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  await _load();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Creator profile created')),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to onboard: $e')),
                                  );
                                }
                              } finally {
                                setModalState(() => saving = false);
                              }
                            },
                      icon: saving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send),
                      label: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Creator Profile'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Creator Profile'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_profile == null) {
      // Not onboarded yet
      return Scaffold(
        appBar: AppBar(
          title: const Text('Creator Profile'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No creator profile found'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _openOnboardSheet,
                icon: const Icon(Icons.add),
                label: const Text('Onboard as Creator'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  child: Text(_profile!.displayName.isNotEmpty ? _profile!.displayName.substring(0, 1).toUpperCase() : '?'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_profile!.displayName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text(_profile!.kycStatus, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditProfileDialog(context),
                  tooltip: 'Edit Profile',
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_profile!.bio != null && _profile!.bio!.isNotEmpty) ...[
              Text('About', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_profile!.bio!),
              const SizedBox(height: 16),
            ],

          ],
        ),
      ),
    );
  }
}
