import 'package:dio/dio.dart';
import '../models/content_models.dart';

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

      return SeriesListResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch series: $e');
    }
  }

  Future<Series> getSeriesDetail({
    required String seriesId,
    String? accessToken,
  }) async {
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }

      final response = await _dio.get('/content/series/$seriesId');
      return Series.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch series detail: $e');
    }
  }

  Future<List<Episode>> getPublishedEpisodesForSeries({
    required String seriesId,
    String? accessToken,
  }) async {
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }

      final response = await _dio.get('/content/series/$seriesId/episodes');
      final list = (response.data as List)
          .map((e) => Episode.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      throw Exception('Failed to fetch episodes: $e');
    }
  }

  Future<String> getEpisodeManifestUrl({
    required String episodeId,
    String? accessToken,
  }) async {
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }

      // Auth-protected playback manifest endpoint
      final response = await _dio.get('/api/episodes/$episodeId/manifest');
      final data = response.data as Map<String, dynamic>;
      final url = data['manifest_url'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('Manifest URL missing');
      }
      return url;
    } catch (e) {
      throw Exception('Failed to fetch manifest: $e');
    }
  }
}