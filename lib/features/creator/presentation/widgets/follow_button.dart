import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/follow_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class FollowButton extends ConsumerStatefulWidget {
  final String creatorId;
  final String creatorName;
  final int followerCount;
  final bool isFollowing;
  final VoidCallback? onFollowChanged;

  const FollowButton({
    super.key,
    required this.creatorId,
    required this.creatorName,
    required this.followerCount,
    required this.isFollowing,
    this.onFollowChanged,
  });

  @override
  ConsumerState<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<FollowButton> {
  bool _isFollowing = false;
  int _followerCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.isFollowing;
    _followerCount = widget.followerCount;
  }

  @override
  void didUpdateWidget(FollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFollowing != widget.isFollowing) {
      _isFollowing = widget.isFollowing;
    }
    if (oldWidget.followerCount != widget.followerCount) {
      _followerCount = widget.followerCount;
    }
  }

  Future<void> _handleFollowToggle() async {
    if (_isLoading) return;

    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      // Redirect to login
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Optimistic update
    final previousFollowing = _isFollowing;
    final previousCount = _followerCount;
    
    setState(() {
      _isFollowing = !_isFollowing;
      if (_isFollowing) {
        _followerCount++;
      } else {
        _followerCount = (_followerCount - 1).clamp(0, double.infinity).toInt();
      }
    });

    try {
      if (previousFollowing) {
        await ref.read(followNotifierProvider.notifier).unfollowCreator(widget.creatorId);
      } else {
        await ref.read(followNotifierProvider.notifier).followCreator(widget.creatorId);
      }

      // Success - optimistic update was correct
      if (mounted) {
        widget.onFollowChanged?.call();
      }
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        _isFollowing = previousFollowing;
        _followerCount = previousCount;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${_isFollowing ? 'unfollow' : 'follow'} ${widget.creatorName}'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _handleFollowToggle,
            ),
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Creator name and follower count
        Row(
          children: [
            Text(
              widget.creatorName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_followerCount.toString()} followers',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Follow button
        SizedBox(
          width: 120,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleFollowToggle,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFollowing 
                  ? Theme.of(context).colorScheme.surfaceVariant
                  : Theme.of(context).colorScheme.primary,
              foregroundColor: _isFollowing 
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isFollowing 
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  )
                : Text(
                    _isFollowing ? 'Following' : 'Follow',
                    style: const TextStyle(fontSize: 14),
                  ),
          ),
        ),
      ],
    );
  }
}

class CompactFollowButton extends ConsumerStatefulWidget {
  final String creatorId;
  final bool isFollowing;
  final VoidCallback? onFollowChanged;

  const CompactFollowButton({
    super.key,
    required this.creatorId,
    required this.isFollowing,
    this.onFollowChanged,
  });

  @override
  ConsumerState<CompactFollowButton> createState() => _CompactFollowButtonState();
}

class _CompactFollowButtonState extends ConsumerState<CompactFollowButton> {
  bool _isFollowing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.isFollowing;
  }

  @override
  void didUpdateWidget(CompactFollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFollowing != widget.isFollowing) {
      _isFollowing = widget.isFollowing;
    }
  }

  Future<void> _handleFollowToggle() async {
    if (_isLoading) return;

    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      // Redirect to login
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Optimistic update
    final previousFollowing = _isFollowing;
    
    setState(() {
      _isFollowing = !_isFollowing;
    });

    try {
      if (previousFollowing) {
        await ref.read(followNotifierProvider.notifier).unfollowCreator(widget.creatorId);
      } else {
        await ref.read(followNotifierProvider.notifier).followCreator(widget.creatorId);
      }

      // Success - optimistic update was correct
      if (mounted) {
        widget.onFollowChanged?.call();
      }
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        _isFollowing = previousFollowing;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${_isFollowing ? 'unfollow' : 'follow'}'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _handleFollowToggle,
            ),
          ),
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
    return SizedBox(
      width: 80,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _handleFollowToggle,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        child: _isLoading
            ? SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            : Text(
                _isFollowing ? 'Following' : 'Follow',
                style: const TextStyle(fontSize: 12),
              ),
      ),
    );
  }
}
