import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:streamshort/features/payment/data/models/payment_models.dart';

final paymentProvider = StateNotifierProvider<PaymentNotifier, AsyncValue<PaymentCreateResponse?>>((ref) {
  return PaymentNotifier();
});

final paymentHistoryProvider = StateNotifierProvider<PaymentHistoryNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return PaymentHistoryNotifier();
});

class PaymentNotifier extends StateNotifier<AsyncValue<PaymentCreateResponse?>> {
  PaymentNotifier() : super(const AsyncValue.initial());

  Future<void> createSubscription({
    required String targetType,
    required String targetId,
    required String planId,
  }) async {
    try {
      state = const AsyncValue.loading();
      // TODO: Implement API call to create subscription
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> processPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      state = const AsyncValue.loading();
      // TODO: Implement payment verification and processing
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void reset() {
    state = const AsyncValue.initial();
  }
}

class PaymentHistoryNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  PaymentHistoryNotifier() : super(const AsyncValue.loading());

  Future<void> loadPaymentHistory() async {
    try {
      state = const AsyncValue.loading();
      // TODO: Implement API call to load payment history
      state = const AsyncValue.data([]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
