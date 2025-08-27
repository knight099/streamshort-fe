import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/subscription_models.dart';
import '../providers/subscription_providers.dart';
import 'subscription_plan_card.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionDialog extends ConsumerStatefulWidget {
  final String targetType;
  final String targetId;
  final String title;
  final String description;

  const SubscriptionDialog({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.title,
    required this.description,
  });

  @override
  ConsumerState<SubscriptionDialog> createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends ConsumerState<SubscriptionDialog> {
  String? _selectedPlanId;
  bool _autoRenew = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subscriptionPlansProvider.notifier).loadPlans();
    });
  }

  Future<void> _subscribe() async {
    if (_selectedPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plan')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      await ref.read(subscriptionCheckProvider.notifier).createSubscription(
        targetType: widget.targetType,
        targetId: widget.targetId,
        planId: _selectedPlanId!,
        autoRenew: _autoRenew,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create subscription: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansState = ref.watch(subscriptionPlansProvider);

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Choose a Plan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (plansState is SubscriptionPlansLoading)
            const Center(child: CircularProgressIndicator())
          else if (plansState is SubscriptionPlansError)
            Center(
              child: Column(
                children: [
                  Text(
                    'Failed to load plans',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(subscriptionPlansProvider.notifier).loadPlans();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (plansState is SubscriptionPlansLoaded)
            SizedBox(
              height: 300,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: plansState.plans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final plan = plansState.plans[index];
                  return SubscriptionPlanCard(
                    plan: plan,
                    isSelected: _selectedPlanId == plan.id,
                    isLoading: _isCreating,
                    onTap: () {
                      setState(() {
                        _selectedPlanId = plan.id;
                      });
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Auto-renew subscription'),
            subtitle: const Text('Automatically renew when subscription expires'),
            value: _autoRenew,
            onChanged: _isCreating ? null : (value) {
              setState(() {
                _autoRenew = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _subscribe,
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Subscribe'),
        ),
      ],
    );
  }
}
