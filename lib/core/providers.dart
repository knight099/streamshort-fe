import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'api/api_client.dart';
import '../features/auth/data/repositories/auth_repository.dart';
import '../features/content/data/repositories/content_repository.dart';
import '../features/creator/data/repositories/creator_repository.dart';
import '../features/profile/data/repositories/profile_repository.dart';
import '../features/subscription/data/repositories/subscription_repository.dart';
import 'config/environment.dart';
import 'interceptors/auth_interceptor.dart';

// Dio Provider
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  
  // Configure Dio
  dio.options.connectTimeout = const Duration(seconds: 30);
  dio.options.receiveTimeout = const Duration(seconds: 30);
  dio.options.sendTimeout = const Duration(seconds: 30);
  dio.options.baseUrl = EnvironmentConfig.apiBaseUrl;
  dio.options.receiveDataWhenStatusError = true;
  
  // Add interceptors for logging, auth, etc.
  if (EnvironmentConfig.enableLogging) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print(obj),
    ));
  }
  // Auth interceptor to add Authorization header from auth state
  dio.interceptors.add(AuthInterceptor(ref));
  
  
  return dio;
});

// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.read(dioProvider);
  return ApiClient.create(dio);
});

// Repository Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  final dio = ref.read(dioProvider);
  return AuthRepository(apiClient, dio);
});

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final dio = ref.read(dioProvider);
  return ContentRepository(dio: dio);
});

final creatorRepositoryProvider = Provider<CreatorRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  final dio = ref.read(dioProvider);
  return CreatorRepository(apiClient, dio);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return ProfileRepository(apiClient);
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return SubscriptionRepository(apiClient);
});
