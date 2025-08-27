import 'package:dio/dio.dart';
import '../models/subscription_models.dart';

class SubscriptionRepository {
  final Dio _dio;

  SubscriptionRepository({required Dio dio}) : _dio = dio;

  Future<List<SubscriptionPlan>> getSubscriptionPlans({String? accessToken}) async {
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }

      final response = await _dio.get('/api/subscriptions/plans');
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        final data = response.data;
        if (data is List) {
          return data.map((item) => SubscriptionPlan.fromJson(item)).toList();
        }
        throw Exception('Unexpected response format');
      }
      throw Exception('Failed to fetch subscription plans');
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to fetch subscription plans: $e');
    }
  }

  Future<Subscription?> getUserSubscription({String? accessToken}) async {
    try {
      final response = await getUserSubscriptions(accessToken: accessToken);
      return response.subscriptions.firstOrNull;
    } catch (e) {
      return null;
    }
  }

  Future<SubscriptionListResponse> getUserSubscriptions({
    int page = 1,
    int perPage = 20,
    String? accessToken,
  }) async {
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }

      final response = await _dio.get(
        '/api/subscriptions',
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        final data = response.data;
        if (data is Map) {
          return SubscriptionListResponse.fromJson(Map<String, dynamic>.from(data));
        }
        throw Exception('Unexpected response format');
      }
      throw Exception('Failed to fetch user subscriptions');
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to fetch user subscriptions: $e');
    }
  }

  Future<Subscription> getSubscription(String id, {String? accessToken}) async {
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }

      final response = await _dio.get('/api/subscriptions/$id');
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        final data = response.data;
        if (data is Map) {
          return Subscription.fromJson(Map<String, dynamic>.from(data));
        }
        throw Exception('Unexpected response format');
      }
      throw Exception('Failed to fetch subscription');
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to fetch subscription: $e');
    }
  }

  Future<SubscriptionCheckResponse> checkSubscription({
    required String targetType,
    required String targetId,
    String? accessToken,
  }) async {
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }

      final response = await _dio.get(
        '/api/subscriptions/check',
        queryParameters: {
          'target_type': targetType,
          'target_id': targetId,
        },
      );

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        final data = response.data;
        if (data is Map) {
          return SubscriptionCheckResponse.fromJson(Map<String, dynamic>.from(data));
        }
        throw Exception('Unexpected response format');
      }
      throw Exception('Failed to check subscription');
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to check subscription: $e');
    }
  }

  Future<CreateSubscriptionResponse> createSubscription({
    required String targetType,
    required String targetId,
    required String planId,
    bool autoRenew = true,
    String? accessToken,
  }) async {
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }

      final request = CreateSubscriptionRequest(
        targetType: targetType,
        targetId: targetId,
        planId: planId,
        autoRenew: autoRenew,
      );

      final response = await _dio.post(
        '/api/payments/create-subscription',
        data: request.toJson(),
      );

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        final data = response.data;
        if (data is Map) {
          return CreateSubscriptionResponse.fromJson(Map<String, dynamic>.from(data));
        }
        throw Exception('Unexpected response format');
      }
      throw Exception('Failed to create subscription');
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to create subscription: $e');
    }
  }

  Future<CancelSubscriptionResponse> cancelSubscription({
    required String subscriptionId,
    String? accessToken,
  }) async {
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }

      final response = await _dio.post('/api/subscriptions/$subscriptionId/cancel');
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        final data = response.data;
        if (data is Map) {
          return CancelSubscriptionResponse.fromJson(Map<String, dynamic>.from(data));
        }
        throw Exception('Unexpected response format');
      }
      throw Exception('Failed to cancel subscription');
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to cancel subscription: $e');
    }
  }

  Future<RenewSubscriptionResponse> renewSubscription({
    required String subscriptionId,
    String? accessToken,
  }) async {
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }

      final response = await _dio.post('/api/subscriptions/$subscriptionId/renew');
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        final data = response.data;
        if (data is Map) {
          return RenewSubscriptionResponse.fromJson(Map<String, dynamic>.from(data));
        }
        throw Exception('Unexpected response format');
      }
      throw Exception('Failed to renew subscription');
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to renew subscription: $e');
    }
  }

  Exception _handleError(DioException e) {
    String _msg(String fallback) {
      final data = e.response?.data;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data as Map);
        final m = map['message']?.toString();
        if (m != null && m.isNotEmpty) return m;
      }
      if (data is String && data.isNotEmpty) return data;
      return fallback;
    }

    switch (e.response?.statusCode) {
      case 400:
        return Exception('Invalid request: ${_msg('Bad request')}');
      case 401:
        return Exception('Unauthorized: ${_msg('Please login again')}');
      case 403:
        return Exception('Forbidden: ${_msg('Access denied')}');
      case 404:
        return Exception('Not found: ${_msg('Subscription not found')}');
      case 500:
        return Exception('Server error: ${_msg('Internal server error')}');
      default:
        return Exception('Network error: ${e.message}');
    }
  }
}