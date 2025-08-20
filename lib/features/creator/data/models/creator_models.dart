import 'package:json_annotation/json_annotation.dart';

part 'creator_models.g.dart';

@JsonSerializable()
class CreatorOnboardRequest {
  final String displayName;
  final String? bio;
  final String kycDocumentS3Path;

  const CreatorOnboardRequest({
    required this.displayName,
    this.bio,
    required this.kycDocumentS3Path,
  });

  factory CreatorOnboardRequest.fromJson(Map<String, dynamic> json) =>
      _$CreatorOnboardRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreatorOnboardRequestToJson(this);
}

@JsonSerializable()
class CreatorProfile {
  final String id;
  final String userId;
  final String displayName;
  final String? bio;
  final String kycStatus; // pending, verified, rejected
  final Map<String, dynamic>? payoutDetails;
  final double? rating;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CreatorProfile({
    required this.id,
    required this.userId,
    required this.displayName,
    this.bio,
    required this.kycStatus,
    this.payoutDetails,
    this.rating,
    required this.createdAt,
    this.updatedAt,
  });

  factory CreatorProfile.fromJson(Map<String, dynamic> json) =>
      _$CreatorProfileFromJson(json);

  Map<String, dynamic> toJson() => _$CreatorProfileToJson(this);

  bool get isVerified => kycStatus == 'verified';
  bool get isPending => kycStatus == 'pending';
  bool get isRejected => kycStatus == 'rejected';
}

@JsonSerializable()
class CreatorDashboardResponse {
  final int views;
  final int watchTimeSeconds;
  final double earnings;
  final int totalEpisodes;
  final int totalSeries;
  final double averageRating;

  const CreatorDashboardResponse({
    required this.views,
    required this.watchTimeSeconds,
    required this.earnings,
    required this.totalEpisodes,
    required this.totalSeries,
    required this.averageRating,
  });

  factory CreatorDashboardResponse.fromJson(Map<String, dynamic> json) =>
      _$CreatorDashboardResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreatorDashboardResponseToJson(this);

  String get watchTimeFormatted {
    final hours = watchTimeSeconds ~/ 3600;
    final minutes = (watchTimeSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get earningsFormatted => '₹${earnings.toStringAsFixed(2)}';
}

// Series creation models
@JsonSerializable()
class CreateSeriesRequest {
  final String title;
  final String synopsis;
  final String language;
  final List<String> categoryTags;
  final String priceType; // free, subscription, one_time
  final double? priceAmount;
  final String? thumbnailUrl;

  const CreateSeriesRequest({
    required this.title,
    required this.synopsis,
    required this.language,
    required this.categoryTags,
    required this.priceType,
    this.priceAmount,
    this.thumbnailUrl,
  });

  factory CreateSeriesRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateSeriesRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateSeriesRequestToJson(this);
}

@JsonSerializable()
class CreateSeriesResponse {
  final String id;
  final String title;
  final String status;
  final DateTime createdAt;

  const CreateSeriesResponse({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
  });

  factory CreateSeriesResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateSeriesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreateSeriesResponseToJson(this);
}

// Episode creation models
@JsonSerializable()
class CreateEpisodeRequest {
  final String seriesId;
  final String title;
  final int episodeNumber;
  final int durationSeconds;
  final String? thumbUrl;
  final String? captionsUrl;

  const CreateEpisodeRequest({
    required this.seriesId,
    required this.title,
    required this.episodeNumber,
    required this.durationSeconds,
    this.thumbUrl,
    this.captionsUrl,
  });

  factory CreateEpisodeRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateEpisodeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateEpisodeRequestToJson(this);
}

@JsonSerializable()
class CreateEpisodeResponse {
  final String id;
  final String title;
  final int episodeNumber;
  final String status;
  final DateTime createdAt;

  const CreateEpisodeResponse({
    required this.id,
    required this.title,
    required this.episodeNumber,
    required this.status,
    required this.createdAt,
  });

  factory CreateEpisodeResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateEpisodeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreateEpisodeResponseToJson(this);
}

// Upload models
@JsonSerializable()
class GetUploadUrlRequest {
  final String filename;
  final String contentType;
  final int sizeBytes;
  final String episodeId;
  final Map<String, dynamic>? metadata;

  const GetUploadUrlRequest({
    required this.filename,
    required this.contentType,
    required this.sizeBytes,
    required this.episodeId,
    this.metadata,
  });

  factory GetUploadUrlRequest.fromJson(Map<String, dynamic> json) =>
      _$GetUploadUrlRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GetUploadUrlRequestToJson(this);
}

@JsonSerializable()
class GetUploadUrlResponse {
  final String uploadId;
  final String presignedUrl;
  final int expiresIn;
  final Map<String, dynamic> uploadHeaders;

  const GetUploadUrlResponse({
    required this.uploadId,
    required this.uploadId,
    required this.presignedUrl,
    required this.expiresIn,
    required this.uploadHeaders,
  });

  factory GetUploadUrlResponse.fromJson(Map<String, dynamic> json) =>
      _$GetUploadUrlResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GetUploadUrlResponseToJson(this);
}

@JsonSerializable()
class NotifyUploadCompleteRequest {
  final String episodeId;
  final String s3Path;
  final int sizeBytes;

  const NotifyUploadCompleteRequest({
    required this.episodeId,
    required this.s3Path,
    required this.sizeBytes,
  });

  factory NotifyUploadCompleteRequest.fromJson(Map<String, dynamic> json) =>
      _$NotifyUploadCompleteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$NotifyUploadCompleteRequestToJson(this);
}

@JsonSerializable()
class NotifyUploadCompleteResponse {
  final String status;
  final String? message;

  const NotifyUploadCompleteResponse({
    required this.status,
    this.message,
  });

  factory NotifyUploadCompleteResponse.fromJson(Map<String, dynamic> json) =>
      _$NotifyUploadCompleteResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NotifyUploadCompleteResponseToJson(this);
}

// Creator's series and episodes
@JsonSerializable()
class CreatorSeries {
  final String id;
  final String title;
  final String synopsis;
  final String language;
  final List<String> categoryTags;
  final String priceType;
  final double? priceAmount;
  final String? thumbnailUrl;
  final String status;
  final int episodeCount;
  final int totalViews;
  final double averageRating;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CreatorSeries({
    required this.id,
    required this.title,
    required this.synopsis,
    required this.language,
    required this.categoryTags,
    required this.priceType,
    this.priceAmount,
    this.thumbnailUrl,
    required this.status,
    required this.episodeCount,
    required this.totalViews,
    required this.averageRating,
    required this.createdAt,
    this.updatedAt,
  });

  factory CreatorSeries.fromJson(Map<String, dynamic> json) =>
      _$CreatorSeriesFromJson(json);

  Map<String, dynamic> toJson() => _$CreatorSeriesToJson(this);

  bool get isPublished => status == 'published';
  bool get isDraft => status == 'draft';
  bool get isFree => priceType == 'free';
}

@JsonSerializable()
class CreatorEpisode {
  final String id;
  final String seriesId;
  final String title;
  final int episodeNumber;
  final int durationSeconds;
  final String? thumbUrl;
  final String status;
  final int viewCount;
  final double? rating;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CreatorEpisode({
    required this.id,
    required this.seriesId,
    required this.title,
    required this.episodeNumber,
    required this.durationSeconds,
    this.thumbUrl,
    required this.status,
    required this.viewCount,
    this.rating,
    this.publishedAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory CreatorEpisode.fromJson(Map<String, dynamic> json) =>
      _$CreatorEpisodeFromJson(json);

  Map<String, dynamic> toJson() => _$CreatorEpisodeToJson(this);

  bool get isReady => status == 'ready';
  bool get isPublished => status == 'published';
  bool get isPendingUpload => status == 'pending_upload';
  bool get isQueuedTranscode => status == 'queued_transcode';

  String get durationFormatted {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}

@JsonSerializable()
class CreatorSeriesListResponse {
  final int total;
  final List<CreatorSeries> items;
  final int page;
  final int perPage;

  const CreatorSeriesListResponse({
    required this.total,
    required this.items,
    required this.page,
    required this.perPage,
  });

  factory CreatorSeriesListResponse.fromJson(Map<String, dynamic> json) =>
      _$CreatorSeriesListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreatorSeriesListResponseToJson(this);
}

@JsonSerializable()
class CreatorEpisodeListResponse {
  final int total;
  final List<CreatorEpisode> items;
  final int page;
  final int perPage;

  const CreatorEpisodeListResponse({
    required this.total,
    required this.items,
    required this.page,
    required this.perPage,
  });

  factory CreatorEpisodeListResponse.fromJson(Map<String, dynamic> json) =>
      _$CreatorEpisodeListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreatorEpisodeListResponseToJson(this);
}
