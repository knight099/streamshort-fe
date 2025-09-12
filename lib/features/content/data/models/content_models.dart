import 'package:json_annotation/json_annotation.dart';

part 'content_models.g.dart';

@JsonSerializable()
class Series {
  final String id;
  @JsonKey(name: 'creator_id')
  final String creatorId;
  @JsonKey(name: 'creator_name')
  final String? creatorName;
  final String? title;
  final String? synopsis;
  final String? language;
  @JsonKey(name: 'category_tags')
  final List<String>? categoryTags;
  @JsonKey(name: 'price_type')
  final String? priceType;
  @JsonKey(name: 'price_amount')
  final double? priceAmount;
  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;
  @JsonKey(name: 'banner_url')
  final String? bannerUrl;
  final String? status;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  final List<Episode>? episodes;
  @JsonKey(name: 'episode_count')
  final int? episodeCount;
  @JsonKey(name: 'view_count')
  final int? viewCount;
  final double? rating;
  @JsonKey(name: 'follower_count')
  final int? followerCount;
  final bool? following;

  const Series({
    required this.id,
    required this.creatorId,
    this.creatorName,
    this.title,
    this.synopsis,
    this.language,
    this.categoryTags,
    this.priceType,
    this.priceAmount,
    this.thumbnailUrl,
    this.bannerUrl,
    this.status,
    required this.createdAt,
    this.updatedAt,
    this.episodes,
    this.episodeCount,
    this.viewCount,
    this.rating,
    this.followerCount,
    this.following,
  });

  factory Series.fromJson(Map<String, dynamic> json) => _$SeriesFromJson(json);
  Map<String, dynamic> toJson() => _$SeriesToJson(this);

  bool get isPublished => status == 'published';
  bool get isFree => priceType == 'free';
  String get category => (categoryTags?.isNotEmpty ?? false) ? categoryTags![0] : 'Uncategorized';
  String get thumbnail => thumbnailUrl ?? '';
  String get banner => bannerUrl ?? '';
  int get episodeCountValue => episodeCount ?? episodes?.length ?? 0;
  int get viewCountValue => viewCount ?? 0;
  double get ratingValue => rating ?? 0.0;
  int get followerCountValue => followerCount ?? 0;
  bool get isFollowing => following ?? false;
  
  String get followerCountFormatted {
    final count = followerCountValue;
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}

@JsonSerializable()
class Episode {
  final String id;
  @JsonKey(name: 'series_id')

  final String? seriesId;
  final String? title;
  @JsonKey(name: 'episode_number')
  final int? episodeNumber;
  @JsonKey(name: 'duration_seconds')
  final int? durationSeconds;
  @JsonKey(name: 's3_master_path')
  final String? s3MasterPath;
  @JsonKey(name: 'hls_manifest_url')
  final String? hlsManifestUrl;
  @JsonKey(name: 'thumb_url')
  final String? thumbUrl;
  @JsonKey(name: 'captions_url')
  final String? captionsUrl;
  final String? status;
  @JsonKey(name: 'published_at')
  final DateTime? publishedAt;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const Episode({
    required this.id,
    this.seriesId,
    this.title,
    this.episodeNumber,
    this.durationSeconds,
    this.s3MasterPath,
    this.hlsManifestUrl,
    this.thumbUrl,
    this.captionsUrl,
    this.status,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Episode.fromJson(Map<String, dynamic> json) => _$EpisodeFromJson(json);
  Map<String, dynamic> toJson() => _$EpisodeToJson(this);

  bool get isPublished => status == 'published';
  String get durationFormatted {
    final duration = durationSeconds ?? 0;
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}

@JsonSerializable()
class SeriesListResponse {
  final int total;
  final List<Series> items;
  final int? page;
  @JsonKey(name: 'per_page')
  final int? perPage;

  const SeriesListResponse({
    required this.total,
    required this.items,
    this.page,
    this.perPage,
  });

  factory SeriesListResponse.fromJson(Map<String, dynamic> json) =>
      _$SeriesListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SeriesListResponseToJson(this);
}