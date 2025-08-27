import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/providers.dart';
import 'repositories/creator_repository.dart';

final creatorRepositoryProvider = Provider<CreatorRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  final dio = ref.read(dioProvider);
  return CreatorRepository(apiClient, dio);
});