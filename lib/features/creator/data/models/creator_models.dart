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
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'display_name')
  final String displayName;
  final String? bio;
  @JsonKey(name: 'kyc_status')
  final String kycStatus; // pending, verified, rejected
  @JsonKey(name: 'kyc_document_s3_path')
  final String? kycDocumentS3Path;
  @JsonKey(name: 'payout_details')
  final Map<String, dynamic>? payoutDetails;
  final double? rating;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const CreatorProfile({
    required this.id,
    required this.userId,
    required this.displayName,
    this.bio,
    required this.kycStatus,
    this.kycDocumentS3Path,
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

  CreatorProfile copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? bio,
    String? kycStatus,
    String? kycDocumentS3Path,
    Map<String, dynamic>? payoutDetails,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CreatorProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      kycStatus: kycStatus ?? this.kycStatus,
      kycDocumentS3Path: kycDocumentS3Path ?? this.kycDocumentS3Path,
      payoutDetails: payoutDetails ?? this.payoutDetails,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@JsonSerializable()
class CreatorDashboardResponse {
  final int views;
  final int watchTimeSeconds;
  final double earnings;
  final int? followerCount;

  const CreatorDashboardResponse({
    required this.views,
    required this.watchTimeSeconds,
    required this.earnings,
    this.followerCount,
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
  
  String get followerCountFormatted {
    if (followerCount != null && followerCount! >= 1000000) {
      return '${(followerCount! / 1000000).toStringAsFixed(1)}M';
    } else if (followerCount != null && followerCount! >= 1000) {
      return '${(followerCount! / 1000).toStringAsFixed(1)}K';
    }
    return followerCount?.toString() ?? '0';
  }
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
  @JsonKey(name: 'creator_id')
  final String creatorId;
  final String title;
  final String synopsis;
  final String language;
  @JsonKey(name: 'category_tags')
  final List<String> categoryTags;
  @JsonKey(name: 'price_type')
  final String priceType;
  @JsonKey(name: 'price_amount')
  final double? priceAmount;
  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;
  final String status;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const CreateSeriesResponse({
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
  @JsonKey(name: 'series_id')
  final String seriesId;
  final String title;
  @JsonKey(name: 'episode_number')
  final int episodeNumber;
  @JsonKey(name: 'duration_seconds')
  final int durationSeconds;
  @JsonKey(name: 's3_master_path')
  final String? s3MasterPath;
  @JsonKey(name: 'hls_manifest_url')
  final String? hlsManifestUrl;
  @JsonKey(name: 'thumb_url')
  final String? thumbUrl;
  @JsonKey(name: 'captions_url')
  final String? captionsUrl;
  final String status;
  @JsonKey(name: 'published_at')
  final DateTime? publishedAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const CreateEpisodeResponse({
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
  @JsonKey(name: 'upload_id')
  final String uploadId;
  @JsonKey(name: 'upload_url')
  final String uploadUrl;
  final Map<String, String> fields;

  const GetUploadUrlResponse({
    required this.uploadId,
    required this.uploadUrl,
    required this.fields,
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
  @JsonKey(name: 'category_tags')
  final List<String> categoryTags;
  @JsonKey(name: 'price_type')
  final String priceType;
  @JsonKey(name: 'price_amount')
  final double? priceAmount;
  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;
  final String status;
  @JsonKey(name: 'episode_count')
  final int episodeCount;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  final List<CreatorEpisode> episodes;

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
    required this.createdAt,
    this.updatedAt,
    required this.episodes,
  });

  factory CreatorSeries.fromJson(Map<String, dynamic> json) =>
      _$CreatorSeriesFromJson(json);

  Map<String, dynamic> toJson() => _$CreatorSeriesToJson(this);

  bool get isPublished => status == 'published';
  bool get isDraft => status == 'draft';
  bool get isFree => priceType == 'free';
}

@JsonSerializable()
class CreatorContentResponse {
  final List<CreatorSeries> series;
  final int total;

  const CreatorContentResponse({
    required this.series,
    required this.total,
  });

  factory CreatorContentResponse.fromJson(Map<String, dynamic> json) =>
      _$CreatorContentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreatorContentResponseToJson(this);
}

@JsonSerializable()
class CreatorEpisode {
  final String id;
  final String title;
  @JsonKey(name: 'episode_number')
  final int episodeNumber;
  @JsonKey(name: 'duration_seconds')
  final int durationSeconds;
  final String status;
  @JsonKey(name: 'published_at')
  final DateTime? publishedAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const CreatorEpisode({
    required this.id,
    required this.title,
    required this.episodeNumber,
    required this.durationSeconds,
    required this.status,
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
