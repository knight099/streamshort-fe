import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';

class ContentRepository {
  final Dio _dio;

  ContentRepository({required Dio dio}) : _dio = dio;

  Future<SeriesListResponse> getPublishedSeries({
    int page = 1,
    int limit = 20,
    bool? includeAdultContent,
    String? accessToken,
  }) async {
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }

      final response = await _dio.get(
        '/content/series',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (includeAdultContent != null) 'include_adult': includeAdultContent,
        },
      );

      return SeriesListResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch series: $e');
    }
  }
}