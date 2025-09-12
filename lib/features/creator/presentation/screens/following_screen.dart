import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/follow_providers.dart';
import '../widgets/follow_button.dart';
import '../../data/models/follow_models.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FollowingScreen extends ConsumerStatefulWidget {
  const FollowingScreen({super.key});

  @override
  ConsumerState<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends ConsumerState<FollowingScreen> {
  @override
  void initState() {
    super.initState();
    // Load following list on screen init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(followingListNotifierProvider.notifier).loadFollowingList(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final followingState = ref.watch(followingListNotifierProvider);
    final followingList = ref.watch(followingListProvider);
    final hasMore = ref.watch(hasMoreFollowingProvider);
    final isLoading = ref.watch(followingListLoadingProvider);
    final error = ref.watch(followingListErrorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Following'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(followingListNotifierProvider.notifier).loadFollowingList(refresh: true);
            },
          ),
        ],
      ),
      body: _buildBody(context, followingState, followingList, hasMore, isLoading, error),
    );
  }

  Widget _buildBody(
    BuildContext context,
    FollowingListState state,
    List<FollowedCreator> followingList,
    bool hasMore,
    bool isLoading,
    String? error,
  ) {
    if (state is FollowingListLoading && followingList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is FollowingListError && followingList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load following list',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(followingListNotifierProvider.notifier).loadFollowingList(refresh: true);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (followingList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No creators followed yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Start following creators to see their content here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(followingListNotifierProvider.notifier).loadFollowingList(refresh: true);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: followingList.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == followingList.length) {
            // Load more button
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () {
                          ref.read(followingListNotifierProvider.notifier).loadFollowingList();
                        },
                        child: const Text('Load More'),
                      ),
              ),
            );
          }

          final creator = followingList[index];
          return _buildCreatorCard(context, creator);
        },
      ),
    );
  }

  Widget _buildCreatorCard(BuildContext context, FollowedCreator creator) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Creator avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage: creator.avatarUrl != null
                  ? CachedNetworkImageProvider(creator.avatarUrl!)
                  : null,
              child: creator.avatarUrl == null
                  ? Text(
                      creator.displayName.isNotEmpty
                          ? creator.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Creator info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    creator.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (creator.bio != null && creator.bio!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      creator.bio!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${creator.followerCount} followers',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (creator.kycStatus != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: creator.kycStatus == 'verified'
                                ? Colors.green
                                : Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            creator.kycStatus!.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: creator.kycStatus == 'verified'
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Follow button
            CompactFollowButton(
              creatorId: creator.id,
              isFollowing: true, // All creators in this list are being followed
              onFollowChanged: () {
                // Remove from local list
                ref.read(followingListNotifierProvider.notifier).unfollowCreator(creator.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
