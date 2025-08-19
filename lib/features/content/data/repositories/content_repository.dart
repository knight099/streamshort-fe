import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';

class ContentRepository {
  final ApiClient _apiClient;

  ContentRepository(this._apiClient);

  Future<SeriesListResponse> getSeries({
    int page = 1,
    int limit = 20,
    String? category,
    String? language,
    String? search,
  }) async {
    try {
      final response = await _apiClient.getSeries(
        page: page,
        limit: limit,
        category: category,
        language: language,
        search: search,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to fetch series: $e');
    }
  }

  Future<Series> getSeriesById(String id) async {
    try {
      final response = await _apiClient.getSeriesById(id);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to fetch series: $e');
    }
  }

  Future<List<Episode>> getEpisodes(String seriesId) async {
    try {
      final response = await _apiClient.getEpisodes(seriesId);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to fetch episodes: $e');
    }
  }

  Exception _handleError(DioException e) {
    switch (e.response?.statusCode) {
      case 400:
        return Exception('Invalid request: ${e.response?.data?['message'] ?? 'Bad request'}');
      case 401:
        return Exception('Unauthorized: ${e.response?.data?['message'] ?? 'Please login again'}');
      case 403:
        return Exception('Forbidden: ${e.response?.data?['message'] ?? 'Access denied'}');
      case 404:
        return Exception('Not found: ${e.response?.data?['message'] ?? 'Content not found'}');
      case 500:
        return Exception('Server error: ${e.response?.data?['message'] ?? 'Internal server error'}');
      default:
        return Exception('Network error: ${e.message}');
    }
  }
}
