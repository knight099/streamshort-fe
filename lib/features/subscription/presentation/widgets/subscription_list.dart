import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/subscription_models.dart';
import '../providers/subscription_providers.dart';

class SubscriptionList extends ConsumerStatefulWidget {
  const SubscriptionList({super.key});

  @override
  ConsumerState<SubscriptionList> createState() => _SubscriptionListState();
}

class _SubscriptionListState extends ConsumerState<SubscriptionList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userSubscriptionsProvider.notifier).loadSubscriptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionsState = ref.watch(userSubscriptionsProvider);

    if (subscriptionsState is UserSubscriptionsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (subscriptionsState is UserSubscriptionsError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Failed to load subscriptions',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                ref.read(userSubscriptionsProvider.notifier).loadSubscriptions(refresh: true);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (subscriptionsState is UserSubscriptionsLoaded) {
      if (subscriptionsState.subscriptions.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.subscriptions_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'No active subscriptions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Subscribe to your favorite content to watch premium episodes',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          await ref.read(userSubscriptionsProvider.notifier).loadSubscriptions(refresh: true);
        },
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: subscriptionsState.subscriptions.length + (subscriptionsState.hasMore ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index == subscriptionsState.subscriptions.length) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(userSubscriptionsProvider.notifier).loadMore();
                    },
                    child: const Text('Load More'),
                  ),
                ),
              );
            }

            final subscription = subscriptionsState.subscriptions[index];
            return _buildSubscriptionCard(context, subscription);
          },
        ),
      );
    }

    return const Center(child: Text('Unknown state'));
  }

  Widget _buildSubscriptionCard(BuildContext context, Subscription subscription) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscription.targetType == 'series' ? 'Series Subscription' : 'Creator Subscription',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Plan ID: ${subscription.planId}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(subscription.status.toUpperCase()),
                  backgroundColor: subscription.isActive
                      ? Colors.green.withOpacity(0.1)
                      : subscription.isCancelled
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: subscription.isActive
                        ? Colors.green
                        : subscription.isCancelled
                            ? Colors.orange
                            : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Date',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _formatDate(subscription.startDate),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Date',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _formatDate(subscription.endDate),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '${subscription.currency} ${subscription.amount}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  subscription.autoRenew ? Icons.autorenew : Icons.block,
                  size: 16,
                  color: subscription.autoRenew ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  subscription.autoRenew ? 'Auto-renew' : 'No auto-renew',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: subscription.autoRenew ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            if (subscription.isActive) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      ref.read(userSubscriptionsProvider.notifier).cancelSubscription(subscription.id);
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ] else if (subscription.isCancelled) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      ref.read(userSubscriptionsProvider.notifier).renewSubscription(subscription.id);
                    },
                    child: const Text('Renew'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
