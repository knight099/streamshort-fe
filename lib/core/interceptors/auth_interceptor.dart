import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

class AuthInterceptor extends Interceptor {
  final Ref ref;

  AuthInterceptor(this.ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Attach Authorization header from auth state if available
    final token = ref.read(accessTokenProvider);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    // Ensure JSON content-type for POST/PUT by default
    if (options.method == 'POST' || options.method == 'PUT' || options.method == 'PATCH') {
      options.headers.putIfAbsent('Content-Type', () => 'application/json');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      print('Unauthorized request: ${err.requestOptions.path}');
      // Could implement token refresh logic here
    }
    handler.next(err);
  }
}
