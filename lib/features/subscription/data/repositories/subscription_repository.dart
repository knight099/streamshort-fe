import 'package:dio/dio.dart';
import 'package:streamshort/core/api/api_client.dart';

class SubscriptionRepository {
  final ApiClient _apiClient;

  SubscriptionRepository(this._apiClient);

  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    try {
      return await _apiClient.getSubscriptionPlans();
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to load subscription plans: $e');
    }
  }

  Future<Subscription?> getUserSubscription() async {
    try {
      return await _apiClient.getUserSubscription();
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to load user subscription: $e');
    }
  }

  Future<PaymentCreateResponse> createSubscription(PaymentCreateRequest request) async {
    try {
      final response = await _apiClient.createSubscription(request);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to create subscription: $e');
    }
  }

  Exception _handleError(DioException error) {
    switch (error.response?.statusCode) {
      case 400:
        return Exception('Invalid request. Please check your input.');
      case 401:
        return Exception('Unauthorized. Please login again.');
      case 402:
        return Exception('Payment required. Please check your payment method.');
      case 500:
        return Exception('Server error. Please try again later.');
      default:
        return Exception('Network error. Please check your connection.');
    }
  }
}
