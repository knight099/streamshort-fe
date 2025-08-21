import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../models/creator_models.dart';
import '../models/episode_update_request.dart';

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
      // Ensure Authorization header is present (from arg or existing Dio state)
      final headerToken = accessToken;
      if (headerToken != null && headerToken.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $headerToken';
      }
      final existingAuth = _dio.options.headers['Authorization']?.toString();
      final authHeader = (headerToken != null && headerToken.isNotEmpty)
          ? 'Bearer $headerToken'
          : (existingAuth != null && existingAuth.isNotEmpty ? existingAuth : null);

      // Send snake_case body expected by backend
      final resp = await _dio.post(
        'api/creators/onboard',
        data: {
          'display_name': displayName,
          'bio': bio,
          'kyc_document_s3_path': kycDocumentS3Path,
        },
        options: Options(headers: {
          if (authHeader != null) 'Authorization': authHeader,
          'Content-Type': 'application/json',
        }),
      );

      if (resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
        final data = resp.data;
        if (data is Map) {
          final map = Map<String, dynamic>.from(data as Map);
          return _parseCreatorProfile(map);
        }
        throw Exception('Unexpected response format');
      }
      final msg = resp.data is Map && resp.data['message'] != null ? resp.data['message'] : 'Failed to onboard creator';
      throw Exception(msg.toString());
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

  Future<CreatorProfile> updateCreatorProfile({
    required String displayName,
    String? bio,
    String? accessToken,
  }) async {
    try {
      // Add Authorization header if token is provided
      if (accessToken != null && accessToken.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }
      
      // Send snake_case body expected by backend
      final resp = await _dio.put(
        'api/creators/profile',
        data: {
          'display_name': displayName,
          if (bio != null) 'bio': bio,
        },
        options: Options(headers: {
          'Content-Type': 'application/json',
        }),
      );

      if (resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
        final data = resp.data;
        if (data is Map) {
          final map = Map<String, dynamic>.from(data as Map);
          return _parseCreatorProfile(map);
        }
        throw Exception('Unexpected response format');
      }
      final msg = resp.data is Map && resp.data['message'] != null ? resp.data['message'] : 'Failed to update creator profile';
      throw Exception(msg.toString());
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to update creator profile: $e');
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

  String _asString(dynamic v, {String def = ''}) {
    if (v == null) return def;
    if (v is String) return v;
    return v.toString();
  }

  List<String> _asList(dynamic v, {List<String> def = const []}) {
    if (v == null) return def;
    if (v is List) {
      return v.map((e) => _asString(e)).toList();
    }
    return def;
  }

  DateTime _asDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (e) {
        return DateTime.now();
      }
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
      kycDocumentS3Path: json['kyc_document_s3_path'] != null ? _asString(json['kyc_document_s3_path']) : null,
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
      categoryTags: _asList(m['category_tags'], def: ['Misc']),
      language: _asString(m['language'], def: 'English'),
      priceType: _asString(m['price_type'], def: 'free'),
      priceAmount: m['price_amount'] == null ? null : _asDouble(m['price_amount']),
      thumbnailUrl: _asString(m['thumbnail_url'], def: ''),

      creatorId: _asString(m['creator_id'], def: ''),
      creatorName: _asString(m['creator_name'], def: ''),
      status: _asString(m['status'], def: 'draft'),

      episodes: m['episodes'] == null ? null : (m['episodes'] as List).map((e) => _parseEpisode(Map<String, dynamic>.from(e as Map))).toList(),
      createdAt: _asDate(m['created_at']),
      updatedAt: _asDate(m['updated_at']),
    );
  }

  Episode _parseEpisode(Map<String, dynamic> m) {
    return Episode(
      id: _asString(m['id'], def: ''),

      title: _asString(m['title'], def: 'Episode'),
      episodeNumber: _asInt(m['episode_number']),
      durationSeconds: _asInt(m['duration_seconds']),
      thumbUrl: _asString(m['thumb_url'], def: ''),
      publishedAt: m['published_at'] == null ? null : _asDate(m['published_at']),
      createdAt: _asDate(m['created_at']),
    );
  }

  // ---------- Content Creation Methods ----------

    Future<CreatorContentResponse> getCreatorContent({String? accessToken}) async {
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }
      
      final resp = await _dio.get('api/creators/content');
      
      if (resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
        final data = resp.data;
        if (data is Map) {
          final map = Map<String, dynamic>.from(data as Map);
          return _parseCreatorContentResponse(map);
        }
        throw Exception('Unexpected response format');
      }
      throw Exception('Failed to fetch creator content');
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to fetch creator content: $e');
    }
  }

  Future<CreatorEpisodeListResponse> getCreatorEpisodes(String seriesId, {int page = 1, int perPage = 20}) async {
    try {
      final resp = await _dio.get('api/content/series/$seriesId/episodes', queryParameters: {
        'page': page,
        'per_page': perPage,
      });
      
      if (resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
        final data = resp.data;
        if (data is Map) {
          final map = Map<String, dynamic>.from(data as Map);
          final episodeList = <CreatorEpisode>[];
          final episodeRaw = map['items'];
          if (episodeRaw is List) {
            for (final item in episodeRaw) {
              if (item is Map) {
                final m = Map<String, dynamic>.from(item as Map);
                episodeList.add(_parseCreatorEpisode(m));
              }
            }
          }
          
          return CreatorEpisodeListResponse(
            total: _asInt(map['total']),
            items: episodeList,
            page: _asInt(map['page']),
            perPage: _asInt(map['per_page']),
          );
        }
        throw Exception('Unexpected response format');
      }
      throw Exception('Failed to fetch creator episodes');
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to fetch creator episodes: $e');
    }
  }

  CreatorSeries _parseCreatorSeries(Map<String, dynamic> m) {
    return CreatorSeries(
      id: _asString(m['id']),
      title: _asString(m['title']),
      synopsis: _asString(m['synopsis']),
      language: _asString(m['language']),
      categoryTags: m['category_tags'] is List 
          ? (m['category_tags'] as List).map((e) => _asString(e)).toList()
          : <String>[],
      priceType: _asString(m['price_type']),
      priceAmount: m['price_amount'] != null ? _asDouble(m['price_amount']) : null,
      thumbnailUrl: m['thumbnail_url'] != null ? _asString(m['thumbnail_url']) : null,
      status: _asString(m['status']),
      episodeCount: _asInt(m['episode_count']),
      episodes: <CreatorEpisode>[],
      createdAt: _asDate(m['created_at']),
      updatedAt: m['updated_at'] != null ? _asDate(m['updated_at']) : null,
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

  // ---------- Content Creation Methods ----------
  
  Future<CreateSeriesResponse> createSeries({
    required String title,
    required String synopsis,
    required String language,
    required List<String> categoryTags,
    required String priceType,
    double? priceAmount,
    String? thumbnailUrl,
    String? accessToken,
  }) async {
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }
      
      final resp = await _dio.post(
        'api/content/series',
        data: {
          'title': title,
          'synopsis': synopsis,
          'language': language,
          'category_tags': categoryTags,
          'price_type': priceType,
          if (priceAmount != null) 'price_amount': priceAmount,
          if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        },
        options: Options(headers: {
          'Content-Type': 'application/json',
        }),
      );

      if (resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
        final data = resp.data;
        if (data is Map) {
          final map = Map<String, dynamic>.from(data as Map);
          return _parseCreateSeriesResponse(map);
        }
        throw Exception('Unexpected response format');
      }
      final msg = resp.data is Map && resp.data['message'] != null ? resp.data['message'] : 'Failed to create series';
      throw Exception(msg.toString());
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to create series: $e');
    }
  }

  Future<CreateEpisodeResponse> createEpisode({
    required String seriesId,
    required String title,
    required int episodeNumber,
    required int durationSeconds,
    String? thumbUrl,
    String? accessToken,
  }) async {
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }
      
      final resp = await _dio.post(
        'api/content/series/$seriesId/episodes',
        data: {
          'title': title,
          'episode_number': episodeNumber,
          'duration_seconds': durationSeconds,
          if (thumbUrl != null) 'thumb_url': thumbUrl,
        },
        options: Options(headers: {
          'Content-Type': 'application/json',
        }),
      );

      if (resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
        final data = resp.data;
        if (data is Map) {
          final map = Map<String, dynamic>.from(data as Map);
          return _parseCreateEpisodeResponse(map);
        }
        throw Exception('Unexpected response format');
      }
      final msg = resp.data is Map && resp.data['message'] != null ? resp.data['message'] : 'Failed to create episode';
      throw Exception(msg.toString());
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to create episode: $e');
    }
  }

  Future<GetUploadUrlResponse> getUploadUrl({
    required String fileName,
    required String contentType,
    required int sizeBytes,
    String? accessToken,
  }) async {
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }
      
      final resp = await _dio.post(
        'api/content/upload-url',
        data: {
          'filename': fileName,
          'content_type': contentType,
          'size_bytes': sizeBytes
        },
        options: Options(headers: {
          'Content-Type': 'application/json',
        }),
      );

      if (resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
        final data = resp.data;
        if (data is Map) {
          final map = Map<String, dynamic>.from(data as Map);
          return _parseGetUploadUrlResponse(map);
        }
        throw Exception('Unexpected response format');
      }
      final msg = resp.data is Map && resp.data['message'] != null ? resp.data['message'] : 'Failed to get upload URL';
      throw Exception(msg.toString());
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to get upload URL: $e');
    }
  }

  Future<void> updateEpisode({
    required String episodeId,
    required String title,
    required int episodeNumber,
    required int durationSeconds,
    String? accessToken,
  }) async {
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }

      final response = await _dio.put(
        '/api/content/episodes/$episodeId',
        data: {
          'title': title,
          'episode_number': episodeNumber,
          'duration_seconds': durationSeconds,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update episode');
      }
    } catch (e) {
      throw Exception('Failed to update episode: $e');
    }
  }

  Future<void> deleteEpisode({
    required String episodeId,
    String? accessToken,
  }) async {
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }

      final response = await _dio.delete(
        '/api/content/episodes/$episodeId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete episode');
      }
    } catch (e) {
      throw Exception('Failed to delete episode: $e');
    }
  }

  Future<void> updateEpisodeStatus({
    required String episodeId,
    required String status,
    String? accessToken,
  }) async {
    try {
      final response = await _dio.put(
        '/api/content/episodes/$episodeId/status',
        data: EpisodeUpdateRequest(status: status).toJson(),
        options: Options(
          headers: {
            if (accessToken != null) 'Authorization': 'Bearer $accessToken',
          },
        ),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update episode status');
      }
    } catch (e) {
      throw Exception('Failed to update episode status: $e');
    }
  }

  Future<void> updateSeries({
    required String seriesId,
    required String title,
    required String synopsis,
    required String language,
    required List<String> categoryTags,
    required String priceType,
    double? priceAmount,
    String? accessToken,
  }) async {
    try {
      final response = await _dio.put(
        '/api/content/series/$seriesId',
        data: {
          'title': title,
          'synopsis': synopsis,
          'language': language,
          'category_tags': categoryTags,
          'price_type': priceType,
          'price_amount': priceAmount,
        },
        options: Options(
          headers: {
            if (accessToken != null) 'Authorization': 'Bearer $accessToken',
          },
        ),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update series');
      }
    } catch (e) {
      throw Exception('Failed to update series: $e');
    }
  }

  Future<void> updateSeriesStatus({
    required String seriesId,
    required String status,
    String? accessToken,
  }) async {
    try {
      final response = await _dio.put(
        '/api/content/series/$seriesId/status',
        data: SeriesUpdateRequest(status: status).toJson(),
        options: Options(
          headers: {
            if (accessToken != null) 'Authorization': 'Bearer $accessToken',
          },
        ),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update series status');
      }
    } catch (e) {
      throw Exception('Failed to update series status: $e');
    }
  }

  Future<void> notifyUploadComplete({
    required String uploadId,
    required String fileUrl,
    required int sizeBytes,
    String? accessToken,
  }) async {
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }
      
      final resp = await _dio.post(
        'api/content/uploads/$uploadId/notify',
        data: {
          's3_path': fileUrl,
          'size_bytes': sizeBytes
        },
        options: Options(headers: {
          'Content-Type': 'application/json',
        }),
      );

      if (resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
        return; // Success
      }
      final msg = resp.data is Map && resp.data['message'] != null ? resp.data['message'] : 'Failed to notify upload complete';
      throw Exception(msg.toString());
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to notify upload complete: $e');
    }
  }

  // ---------- Response Parsers ----------
  
  CreateSeriesResponse _parseCreateSeriesResponse(Map<String, dynamic> m) {
    return CreateSeriesResponse(
      id: _asString(m['id']),
      creatorId: _asString(m['creator_id']),
      title: _asString(m['title']),
      synopsis: _asString(m['synopsis']),
      language: _asString(m['language']),
      categoryTags: m['category_tags'] is List 
          ? (m['category_tags'] as List).map((e) => _asString(e)).toList()
          : <String>[],
      priceType: _asString(m['price_type']),
      priceAmount: m['price_amount'] != null ? _asDouble(m['price_amount']) : null,
      thumbnailUrl: m['thumbnail_url'] != null ? _asString(m['thumbnail_url']) : null,
      status: _asString(m['status']),
      createdAt: _asDate(m['created_at']),
      updatedAt: m['updated_at'] != null ? _asDate(m['updated_at']) : null,
    );
  }

  CreateEpisodeResponse _parseCreateEpisodeResponse(Map<String, dynamic> m) {
    return CreateEpisodeResponse(
      id: _asString(m['id']),
      seriesId: _asString(m['series_id']),
      title: _asString(m['title']),
      episodeNumber: _asInt(m['episode_number']),
      durationSeconds: _asInt(m['duration_seconds']),
      s3MasterPath: m['s3_master_path'] != null ? _asString(m['s3_master_path']) : null,
      hlsManifestUrl: m['hls_manifest_url'] != null ? _asString(m['hls_manifest_url']) : null,
      thumbUrl: m['thumb_url'] != null ? _asString(m['thumb_url']) : null,
      captionsUrl: m['captions_url'] != null ? _asString(m['captions_url']) : null,
      status: _asString(m['status']),
      publishedAt: m['published_at'] != null ? _asDate(m['published_at']) : null,
      createdAt: _asDate(m['created_at']),
      updatedAt: m['updated_at'] != null ? _asDate(m['updated_at']) : null,
    );
  }

  GetUploadUrlResponse _parseGetUploadUrlResponse(Map<String, dynamic> m) {
    return GetUploadUrlResponse(
      uploadId: _asString(m['upload_id']),
      uploadUrl: _asString(m['upload_url']),
      fields: m['fields'] is Map ? Map<String, String>.from(m['fields'] as Map) : <String, String>{},
    );
  }

  CreatorContentResponse _parseCreatorContentResponse(Map<String, dynamic> m) {
    final seriesList = <CreatorSeries>[];
    final seriesRaw = m['series'];
    if (seriesRaw is List) {
      for (final item in seriesRaw) {
        if (item is Map) {
          final seriesMap = Map<String, dynamic>.from(item as Map);
          seriesList.add(_parseCreatorSeriesWithEpisodes(seriesMap));
        }
      }
    }
    
    return CreatorContentResponse(
      series: seriesList,
      total: _asInt(m['total']),
    );
  }

  CreatorSeries _parseCreatorSeriesWithEpisodes(Map<String, dynamic> m) {
    final episodesList = <CreatorEpisode>[];
    final episodesRaw = m['episodes'];
    if (episodesRaw is List) {
      for (final item in episodesRaw) {
        if (item is Map) {
          final episodeMap = Map<String, dynamic>.from(item as Map);
          episodesList.add(_parseCreatorEpisode(episodeMap));
        }
      }
    }

    return CreatorSeries(
      id: _asString(m['id']),
      title: _asString(m['title']),
      synopsis: _asString(m['synopsis']),
      language: _asString(m['language']),
      categoryTags: m['category_tags'] is List 
          ? (m['category_tags'] as List).map((e) => _asString(e)).toList()
          : <String>[],
      priceType: _asString(m['price_type']),
      priceAmount: m['price_amount'] != null ? _asDouble(m['price_amount']) : null,
      thumbnailUrl: m['thumbnail_url'] != null ? _asString(m['thumbnail_url']) : null,
      status: _asString(m['status']),
      episodeCount: _asInt(m['episode_count']),
      createdAt: _asDate(m['created_at']),
      updatedAt: m['updated_at'] != null ? _asDate(m['updated_at']) : null,
      episodes: episodesList,
    );
  }

  CreatorEpisode _parseCreatorEpisode(Map<String, dynamic> m) {
    return CreatorEpisode(
      id: _asString(m['id']),
      title: _asString(m['title']),
      episodeNumber: _asInt(m['episode_number']),
      durationSeconds: _asInt(m['duration_seconds']),
      status: _asString(m['status']),
      publishedAt: m['published_at'] != null ? _asDate(m['published_at']) : null,
      createdAt: _asDate(m['created_at']),
      updatedAt: m['updated_at'] != null ? _asDate(m['updated_at']) : null,
    );
  }
}
