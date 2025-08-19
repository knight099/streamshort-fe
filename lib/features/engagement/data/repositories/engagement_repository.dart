import 'package:streamshort/core/api/api_client.dart';
import 'package:streamshort/features/engagement/data/models/engagement_models.dart';

class EngagementRepository {
  final ApiClient _apiClient;

  EngagementRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(_createDio());

  static Dio _createDio() {
    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    return dio;
  }

  Future<LikeResponse> toggleLike(String episodeId) async {
    try {
      final response = await _apiClient.toggleLike(episodeId);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<RatingResponse> submitRating(String episodeId, int score) async {
    try {
      final request = RatingRequest(episodeId: episodeId, score: score);
      final response = await _apiClient.submitRating(episodeId, request);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<CommentListResponse> getComments(String episodeId, {int page = 1}) async {
    try {
      final response = await _apiClient.getComments(episodeId, page: page);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<CommentResponse> postComment(String episodeId, String text) async {
    try {
      final request = CommentRequest(episodeId: episodeId, text: text);
      final response = await _apiClient.postComment(episodeId, request);
      return response;
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
        case 404:
          return Exception('Episode not found.');
        case 429:
          return Exception('Too many requests. Please wait before trying again.');
        case 500:
          return Exception('Server error. Please try again later.');
        default:
          return Exception('Network error. Please check your connection.');
      }
    }
    return Exception('An unexpected error occurred.');
  }
}
