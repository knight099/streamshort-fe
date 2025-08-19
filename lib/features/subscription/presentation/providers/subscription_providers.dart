import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:streamshort/features/payment/data/models/payment_models.dart';

final subscriptionPlansProvider = StateNotifierProvider<SubscriptionPlansNotifier, AsyncValue<List<SubscriptionPlan>>>((ref) {
  return SubscriptionPlansNotifier();
});

final userSubscriptionsProvider = StateNotifierProvider<UserSubscriptionsNotifier, AsyncValue<List<Subscription>>>((ref) {
  return UserSubscriptionsNotifier();
});

class SubscriptionPlansNotifier extends StateNotifier<AsyncValue<List<SubscriptionPlan>>> {
  SubscriptionPlansNotifier() : super(const AsyncValue.loading());

  Future<void> loadPlans() async {
    try {
      state = const AsyncValue.loading();
      // TODO: Implement API call to load subscription plans
      final plans = [
        SubscriptionPlan(
          id: 'plan_monthly',
          name: 'Monthly Plan',
          description: 'Access to all content for 1 month',
          price: 99.0,
          currency: 'INR',
          billingCycle: 'monthly',
          durationDays: 30,
          features: ['Unlimited episodes', 'HD quality', 'Offline downloads'],
          isPopular: false,
        ),
        SubscriptionPlan(
          id: 'plan_yearly',
          name: 'Yearly Plan',
          description: 'Access to all content for 1 year (Save 20%)',
          price: 999.0,
          currency: 'INR',
          billingCycle: 'yearly',
          durationDays: 365,
          features: ['Unlimited episodes', 'HD quality', 'Offline downloads', 'Early access'],
          isPopular: true,
        ),
      ];
      state = AsyncValue.data(plans);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class UserSubscriptionsNotifier extends StateNotifier<AsyncValue<List<Subscription>>> {
  UserSubscriptionsNotifier() : super(const AsyncValue.loading());

  Future<void> loadSubscriptions() async {
    try {
      state = const AsyncValue.loading();
      // TODO: Implement API call to load user subscriptions
      state = const AsyncValue.data([]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createSubscription({
    required String targetType,
    required String targetId,
    required String planId,
  }) async {
    try {
      // TODO: Implement subscription creation API call
      await loadSubscriptions();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
