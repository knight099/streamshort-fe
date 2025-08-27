import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/subscription_models.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/providers.dart';

// Repository provider
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SubscriptionRepository(dio: dio);
});

// Subscription plans state
abstract class SubscriptionPlansState {
  const SubscriptionPlansState();
}

class SubscriptionPlansInitial extends SubscriptionPlansState {
  const SubscriptionPlansInitial();
}

class SubscriptionPlansLoading extends SubscriptionPlansState {
  const SubscriptionPlansLoading();
}

class SubscriptionPlansLoaded extends SubscriptionPlansState {
  final List<SubscriptionPlan> plans;

  const SubscriptionPlansLoaded(this.plans);
}

class SubscriptionPlansError extends SubscriptionPlansState {
  final String message;

  const SubscriptionPlansError(this.message);
}

// Subscription plans notifier
class SubscriptionPlansNotifier extends StateNotifier<SubscriptionPlansState> {
  final SubscriptionRepository _repository;
  final String? _accessToken;

  SubscriptionPlansNotifier(this._repository, this._accessToken)
      : super(const SubscriptionPlansInitial());

  Future<void> loadPlans() async {
    try {
      state = const SubscriptionPlansLoading();
      final plans = await _repository.getSubscriptionPlans(accessToken: _accessToken);
      state = SubscriptionPlansLoaded(plans);
    } catch (e) {
      state = SubscriptionPlansError(e.toString());
    }
  }
}

// Subscription plans provider
final subscriptionPlansProvider =
    StateNotifierProvider<SubscriptionPlansNotifier, SubscriptionPlansState>((ref) {
  final repository = ref.watch(subscriptionRepositoryProvider);
  final accessToken = ref.watch(accessTokenProvider);
  return SubscriptionPlansNotifier(repository, accessToken);
});

// User subscriptions state
abstract class UserSubscriptionsState {
  const UserSubscriptionsState();
}

class UserSubscriptionsInitial extends UserSubscriptionsState {
  const UserSubscriptionsInitial();
}

class UserSubscriptionsLoading extends UserSubscriptionsState {
  const UserSubscriptionsLoading();
}

class UserSubscriptionsLoaded extends UserSubscriptionsState {
  final List<Subscription> subscriptions;
  final bool hasMore;
  final int page;

  const UserSubscriptionsLoaded({
    required this.subscriptions,
    required this.hasMore,
    required this.page,
  });
}

class UserSubscriptionsError extends UserSubscriptionsState {
  final String message;

  const UserSubscriptionsError(this.message);
}

// User subscriptions notifier
class UserSubscriptionsNotifier extends StateNotifier<UserSubscriptionsState> {
  final SubscriptionRepository _repository;
  final String? _accessToken;

  UserSubscriptionsNotifier(this._repository, this._accessToken)
      : super(const UserSubscriptionsInitial());

  Future<void> loadSubscriptions({bool refresh = false}) async {
    try {
      if (state is! UserSubscriptionsLoaded || refresh) {
        state = const UserSubscriptionsLoading();
        final response = await _repository.getUserSubscriptions(
          page: 1,
          perPage: 20,
          accessToken: _accessToken,
        );
        state = UserSubscriptionsLoaded(
          subscriptions: response.subscriptions,
          hasMore: response.page < response.totalPages,
          page: response.page,
        );
      }
    } catch (e) {
      state = UserSubscriptionsError(e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state is UserSubscriptionsLoaded) {
      final currentState = state as UserSubscriptionsLoaded;
      if (!currentState.hasMore) return;

      try {
        final response = await _repository.getUserSubscriptions(
          page: currentState.page + 1,
          perPage: 20,
          accessToken: _accessToken,
        );

        state = UserSubscriptionsLoaded(
          subscriptions: [...currentState.subscriptions, ...response.subscriptions],
          hasMore: response.page < response.totalPages,
          page: response.page,
        );
      } catch (e) {
        state = UserSubscriptionsError(e.toString());
      }
    }
  }

  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      await _repository.cancelSubscription(
        subscriptionId: subscriptionId,
        accessToken: _accessToken,
      );
      loadSubscriptions(refresh: true);
    } catch (e) {
      state = UserSubscriptionsError(e.toString());
    }
  }

  Future<void> renewSubscription(String subscriptionId) async {
    try {
      await _repository.renewSubscription(
        subscriptionId: subscriptionId,
        accessToken: _accessToken,
      );
      loadSubscriptions(refresh: true);
    } catch (e) {
      state = UserSubscriptionsError(e.toString());
    }
  }
}

// User subscriptions provider
final userSubscriptionsProvider =
    StateNotifierProvider<UserSubscriptionsNotifier, UserSubscriptionsState>((ref) {
  final repository = ref.watch(subscriptionRepositoryProvider);
  final accessToken = ref.watch(accessTokenProvider);
  return UserSubscriptionsNotifier(repository, accessToken);
});

// Subscription check state
abstract class SubscriptionCheckState {
  const SubscriptionCheckState();
}

class SubscriptionCheckInitial extends SubscriptionCheckState {
  const SubscriptionCheckInitial();
}

class SubscriptionCheckLoading extends SubscriptionCheckState {
  const SubscriptionCheckLoading();
}

class SubscriptionCheckLoaded extends SubscriptionCheckState {
  final bool hasAccess;
  final Subscription? subscription;

  const SubscriptionCheckLoaded({
    required this.hasAccess,
    this.subscription,
  });
}

class SubscriptionCheckError extends SubscriptionCheckState {
  final String message;

  const SubscriptionCheckError(this.message);
}

// Subscription check notifier
class SubscriptionCheckNotifier extends StateNotifier<SubscriptionCheckState> {
  final SubscriptionRepository _repository;
  final String? _accessToken;

  SubscriptionCheckNotifier(this._repository, this._accessToken)
      : super(const SubscriptionCheckInitial());

  Future<void> checkAccess({
    required String targetType,
    required String targetId,
  }) async {
    try {
      state = const SubscriptionCheckLoading();
      final response = await _repository.checkSubscription(
        targetType: targetType,
        targetId: targetId,
        accessToken: _accessToken,
      );
      state = SubscriptionCheckLoaded(
        hasAccess: response.hasAccess,
        subscription: response.subscriptionDetails,
      );
    } catch (e) {
      state = SubscriptionCheckError(e.toString());
    }
  }

  Future<void> createSubscription({
    required String targetType,
    required String targetId,
    required String planId,
    bool autoRenew = true,
  }) async {
    try {
      state = const SubscriptionCheckLoading();
      final response = await _repository.createSubscription(
        targetType: targetType,
        targetId: targetId,
        planId: planId,
        autoRenew: autoRenew,
        accessToken: _accessToken,
      );
      // After creating subscription, check access again
      await checkAccess(targetType: targetType, targetId: targetId);
    } catch (e) {
      state = SubscriptionCheckError(e.toString());
    }
  }
}

// Subscription check provider
final subscriptionCheckProvider =
    StateNotifierProvider<SubscriptionCheckNotifier, SubscriptionCheckState>((ref) {
  final repository = ref.watch(subscriptionRepositoryProvider);
  final accessToken = ref.watch(accessTokenProvider);
  return SubscriptionCheckNotifier(repository, accessToken);
});