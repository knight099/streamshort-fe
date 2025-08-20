import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../models/creator_models.dart';

class CreatorRepository {
  final ApiClient _apiClient;
  final Dio _dio;

  CreatorRepository(this._apiClient, this._dio);

  Future<CreatorProfile> onboardCreator({ 
    required String displayName, 
    required String kycDocumentS3Path, 
    String? bio,
    String? accessToken,
  }) async {
    try {
      final request = CreatorOnboardRequest(
        displayName: displayName,
        bio: bio,
        kycDocumentS3Path: kycDocumentS3Path,
      );
      
      // Add Authorization header if token is provided
      if (accessToken != null && accessToken.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }
      
      final response = await _apiClient.onboardCreator(request);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to onboard creator: $e');
    }
  }

  Future<CreatorProfile> getCreatorProfile({String? accessToken}) async {
    try {
      // Add Authorization header if token is provided
      if (accessToken != null && accessToken.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }
      
      // Use Dio directly to gracefully handle non-standard payloads
      final resp = await _dio.get('api/creators/profile');
      if (resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
        final data = resp.data;
        if (data is Map) {
          final map = Map<String, dynamic>.from(data as Map);
          return _parseCreatorProfile(map);
        }
        throw Exception('Unexpected response format');
      }
      final msg = resp.data is Map && resp.data['message'] != null ? resp.data['message'] : 'Failed to fetch creator profile';
      throw Exception(msg.toString());
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to fetch creator profile: $e');
    }
  }

  Future<CreatorDashboardResponse> getCreatorDashboard({String? creatorId, String? accessToken}) async {
    try {
      // Add Authorization header if token is provided
      if (accessToken != null && accessToken.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }
      
      // If no creatorId provided, try to get it from the current user's creator profile
      String dashboardCreatorId = creatorId ?? '';
      if (dashboardCreatorId.isEmpty) {
        try {
          final profile = await getCreatorProfile(accessToken: accessToken);
          dashboardCreatorId = profile.id;
        } catch (e) {
          throw Exception('Creator ID required. Please complete creator onboarding first.');
        }
      }

      final resp = await _dio.get('api/creators/$dashboardCreatorId/dashboard');
      if (resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
        final data = resp.data;
        if (data is Map) {
          final map = Map<String, dynamic>.from(data as Map);
          return _parseCreatorDashboard(map);
        }
        throw Exception('Unexpected response format');
      }
      final msg = resp.data is Map && resp.data['message'] != null ? resp.data['message'] : 'Failed to fetch dashboard';
      throw Exception(msg.toString());
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to fetch creator dashboard: $e');
    }
  }

  // ---------- Flexible parsers (coerce numeric strings, tolerate missing fields) ----------
  int _asInt(dynamic v, {int def = 0}) {
    if (v == null) return def;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) {
      final n = int.tryParse(v);
      return n ?? def;
    }
    return def;
  }

  double _asDouble(dynamic v, {double def = 0}) {
    if (v == null) return def;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) {
      final n = double.tryParse(v);
      return n ?? def;
    }
    return def;
  }

  String _asString(dynamic v, {String def = ''}) => v is String ? v : v?.toString() ?? def;

  DateTime _asDate(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) {
      final d = DateTime.tryParse(v);
      return d ?? DateTime.now();
    }
    return DateTime.now();
  }

  CreatorProfile _parseCreatorProfile(Map<String, dynamic> json) {
    return CreatorProfile(
      id: _asString(json['id'], def: ''),
      userId: _asString(json['user_id'], def: ''),
      displayName: _asString(json['display_name'], def: ''),
      bio: json['bio'] == null ? null : _asString(json['bio']),
      kycStatus: _asString(json['kyc_status'], def: 'pending'),
      payoutDetails: json['payout_details'],
      rating: json['rating'] == null ? null : _asDouble(json['rating']),
      createdAt: _asDate(json['created_at']),
      updatedAt: json['updated_at'] == null ? null : _asDate(json['updated_at']),
    );
  }

  CreatorDashboardResponse _parseCreatorDashboard(Map<String, dynamic> json) {
    final seriesList = <Series>[];
    final seriesRaw = json['series'];
    if (seriesRaw is List) {
      for (final item in seriesRaw) {
        if (item is Map) {
          final m = Map<String, dynamic>.from(item as Map);
          seriesList.add(_parseSeries(m));
        }
      }
    }

    final recentList = <Episode>[];
    final recentRaw = json['recentEpisodes'];
    if (recentRaw is List) {
      for (final item in recentRaw) {
        if (item is Map) {
          final m = Map<String, dynamic>.from(item as Map);
          recentList.add(_parseEpisode(m));
        }
      }
    }

    return CreatorDashboardResponse(
      views: _asInt(json['totalViews']),
      watchTimeSeconds: _asInt(json['watchTimeSeconds'] ?? 0),
      earnings: _asDouble(json['totalRevenue'] ?? 0.0),
      totalEpisodes: _asInt(json['totalEpisodes'] ?? 0),
      totalSeries: _asInt(json['totalSeries'] ?? 0),
      averageRating: _asDouble(json['averageRating'] ?? 0.0),
    );
  }

  Series _parseSeries(Map<String, dynamic> m) {
    return Series(
      id: _asString(m['id'], def: ''),
      title: _asString(m['title'], def: 'Untitled'),
      synopsis: _asString(m['synopsis'], def: ''),
      category: _asString(m['category'], def: 'Misc'),
      language: _asString(m['language'], def: 'English'),
      priceType: _asString(m['priceType'], def: 'free'),
      price: m['price'] == null ? null : _asDouble(m['price']),
      thumbnail: _asString(m['thumbnail'], def: ''),
      banner: _asString(m['banner'], def: ''),
      creatorId: _asString(m['creatorId'], def: ''),
      episodeCount: _asInt(m['episodeCount']),
      rating: _asDouble(m['rating']),
      viewCount: _asInt(m['viewCount']),
      createdAt: _asDate(m['createdAt']),
      updatedAt: _asDate(m['updatedAt']),
    );
  }

  Episode _parseEpisode(Map<String, dynamic> m) {
    return Episode(
      id: _asString(m['id'], def: ''),
      seriesId: _asString(m['seriesId'], def: ''),
      title: _asString(m['title'], def: 'Episode'),
      description: _asString(m['description'], def: ''),
      episodeNumber: _asInt(m['episodeNumber']),
      videoUrl: _asString(m['videoUrl'], def: ''),
      thumbnail: _asString(m['thumbnail'], def: ''),
      duration: Duration(seconds: _asInt(m['durationSeconds'] ?? m['duration'])),
      isPremium: (_asString(m['isPremium']).toLowerCase() == 'true') || m['isPremium'] == true,
      createdAt: _asDate(m['createdAt']),
      updatedAt: _asDate(m['updatedAt']),
    );
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
        return Exception('Not found: ${_msg('Creator not found')}');
      case 500:
        return Exception('Server error: ${_msg('Internal server error')}');
      default:
        return Exception('Network error: ${e.message}');
    }
  }
}
