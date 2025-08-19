import 'package:json_annotation/json_annotation.dart';

part 'content_models.g.dart';

@JsonSerializable()
class Series {
  final String id;
  final String creatorId;
  final String title;
  final String synopsis;
  final String language;
  final List<String> categoryTags;
  final String priceType; // free, subscription, one_time
  final double? priceAmount;
  final String? thumbnailUrl;
  final String status; // draft, published
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Series({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.synopsis,
    required this.language,
    required this.categoryTags,
    required this.priceType,
    this.priceAmount,
    this.thumbnailUrl,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Series.fromJson(Map<String, dynamic> json) => _$SeriesFromJson(json);

  Map<String, dynamic> toJson() => _$SeriesToJson(this);

  bool get isFree => priceType == 'free';
  bool get isSubscription => priceType == 'subscription';
  bool get isOneTime => priceType == 'one_time';
  bool get isPublished => status == 'published';
}

@JsonSerializable()
class Episode {
  final String id;
  final String seriesId;
  final String title;
  final int episodeNumber;
  final int durationSeconds;
  final String? s3MasterPath;
  final String? hlsManifestUrl;
  final String? thumbUrl;
  final String? captionsUrl;
  final String status; // pending_upload, queued_transcode, ready, published
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Episode({
    required this.id,
    required this.seriesId,
    required this.title,
    required this.episodeNumber,
    required this.durationSeconds,
    this.s3MasterPath,
    this.hlsManifestUrl,
    this.thumbUrl,
    this.captionsUrl,
    required this.status,
    this.publishedAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory Episode.fromJson(Map<String, dynamic> json) => _$EpisodeFromJson(json);

  Map<String, dynamic> toJson() => _$EpisodeToJson(this);

  bool get isReady => status == 'ready';
  bool get isPublished => status == 'published';
  bool get hasVideo => hlsManifestUrl != null;
  
  String get durationFormatted {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}

@JsonSerializable()
class SeriesListResponse {
  final int total;
  final List<Series> items;
  final int page;
  final int perPage;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const SeriesListResponse({
    required this.total,
    required this.items,
    required this.page,
    required this.perPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory SeriesListResponse.fromJson(Map<String, dynamic> json) =>
      _$SeriesListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SeriesListResponseToJson(this);
}

@JsonSerializable()
class UploadRequest {
  final String filename;
  final String contentType;
  final int sizeBytes;
  final Map<String, dynamic>? metadata;

  const UploadRequest({
    required this.filename,
    required this.contentType,
    required this.sizeBytes,
    this.metadata,
  });

  factory UploadRequest.fromJson(Map<String, dynamic> json) =>
      _$UploadRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UploadRequestToJson(this);
}

@JsonSerializable()
class UploadUrlResponse {
  final String uploadId;
  final String presignedUrl;
  final int expiresIn;
  final Map<String, dynamic> uploadHeaders;

  const UploadUrlResponse({
    required this.uploadId,
    required this.presignedUrl,
    required this.expiresIn,
    required this.uploadHeaders,
  });

  factory UploadUrlResponse.fromJson(Map<String, dynamic> json) =>
      _$UploadUrlResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UploadUrlResponseToJson(this);
}

@JsonSerializable()
class UploadNotifyRequest {
  final String s3Path;
  final int sizeBytes;

  const UploadNotifyRequest({
    required this.s3Path,
    required this.sizeBytes,
  });

  factory UploadNotifyRequest.fromJson(Map<String, dynamic> json) =>
      _$UploadNotifyRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UploadNotifyRequestToJson(this);
}

@JsonSerializable()
class UploadNotifyResponse {
  final String status;

  const UploadNotifyResponse({required this.status});

  factory UploadNotifyResponse.fromJson(Map<String, dynamic> json) =>
      _$UploadNotifyResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UploadNotifyResponseToJson(this);
}

@JsonSerializable()
class ManifestResponse {
  final String manifestUrl;
  final DateTime expiresAt;

  const ManifestResponse({
    required this.manifestUrl,
    required this.expiresAt,
  });

  factory ManifestResponse.fromJson(Map<String, dynamic> json) =>
      _$ManifestResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ManifestResponseToJson(this);
}
