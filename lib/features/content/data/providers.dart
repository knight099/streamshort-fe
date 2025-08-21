import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import 'repositories/content_repository.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ContentRepository(dio: dio);
});