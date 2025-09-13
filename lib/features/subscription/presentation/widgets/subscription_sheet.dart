import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/subscription_models.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../data/providers.dart';

class SubscriptionSheet extends StatefulWidget {
  final WidgetRef ref;
  const SubscriptionSheet({required this.ref, super.key});

  @override
  State<SubscriptionSheet> createState() => _SubscriptionSheetState();
}

class _SubscriptionSheetState extends State<SubscriptionSheet> {
  bool _isLoading = true;
  String? _error;
  List<SubscriptionPlan> _plans = [];
  Subscription? _current;
  bool _isCreating = false;

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
      final subRepo = widget.ref.read(subscriptionRepositoryProvider);
      final plans = await subRepo.getSubscriptionPlans();
      final current = await subRepo.getUserSubscription();
      setState(() {
        _plans = plans;
        _current = current;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
            : _error != null
                ? SizedBox(
                    height: 200,
                    child: Column(
                      children: [
                        Text('Failed to load subscriptions', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Subscription', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          if (_current != null)
                            Chip(
                              label: Text(_current!.status),
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_current != null)
                        Text('Current plan: ${_current!.planId}', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _plans.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final p = _plans[i];
                          final isActive = _current?.planId == p.id;
                          return Card(
                            child: ListTile(
                              title: Text(p.name),
                              subtitle: Text(p.description),
                              trailing: isActive
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : _isCreating
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                      : ElevatedButton(
                                          onPressed: () async {
                                            setState(() => _isCreating = true);
                                            try {
                                              final req = CreateSubscriptionRequest(
                                                targetType: 'plan',
                                                targetId: p.id,
                                                planId: p.id,
                                                autoRenew: true,
                                              );
                                              final subRepo = widget.ref.read(subscriptionRepositoryProvider);
                                              await subRepo.createSubscription(
                                                targetType: 'plan',
                                                targetId: p.id,
                                                planId: p.id,
                                                autoRenew: true,
                                              );
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Subscription created successfully')),
                                                );
                                                await _load();
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Failed to subscribe: $e')),
                                                );
                                              }
                                            } finally {
                                              if (mounted) setState(() => _isCreating = false);
                                            }
                                          },
                                          child: const Text('Choose'),
                                        ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
      ),
    );
  }
}
