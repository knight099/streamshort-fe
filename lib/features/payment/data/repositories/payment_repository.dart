import 'package:streamshort/core/api/api_client.dart';
import 'package:streamshort/features/payment/data/models/payment_models.dart';

class PaymentRepository {
  final ApiClient _apiClient;

  PaymentRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(_createDio());

  static Dio _createDio() {
    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    return dio;
  }

  Future<PaymentCreateResponse> createSubscription(PaymentCreateRequest request) async {
    try {
      final response = await _apiClient.createSubscription(request);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      // TODO: Implement payment verification
      // This would typically involve verifying the Razorpay signature
      // and updating the subscription status
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    try {
      // TODO: Implement API call to get payment history
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.response?.statusCode) {
        case 400:
          return Exception('Invalid request. Please check your input.');
        case 401:
          return Exception('Unauthorized. Please login again.');
        case 402:
          return Exception('Payment failed. Please try again.');
        case 409:
          return Exception('Payment already processed.');
        case 500:
          return Exception('Server error. Please try again later.');
        default:
          return Exception('Network error. Please check your connection.');
      }
    }
    return Exception('An unexpected error occurred.');
  }
}
