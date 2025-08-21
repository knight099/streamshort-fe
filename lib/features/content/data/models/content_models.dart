import 'package:json_annotation/json_annotation.dart';

part 'content_models.g.dart';

@JsonSerializable()
class Series {
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
  @JsonKey(name: 'banner_url')
  final String? bannerUrl;
  final String status;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  final List<Episode>? episodes;
  @JsonKey(name: 'episode_count')
  final int episodeCount;
  @JsonKey(name: 'view_count')
  final int viewCount;
  final double rating;

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
    this.bannerUrl,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.episodes,
    required this.episodeCount,
    required this.viewCount,
    required this.rating,
  });

  factory Series.fromJson(Map<String, dynamic> json) => _$SeriesFromJson(json);
  Map<String, dynamic> toJson() => _$SeriesToJson(this);

  bool get isPublished => status == 'published';
  bool get isFree => priceType == 'free';
  String get category => categoryTags.isNotEmpty ? categoryTags[0] : 'Uncategorized';
  String get thumbnail => thumbnailUrl ?? '';
  String get banner => bannerUrl ?? '';
}

@JsonSerializable()
class Episode {
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

  bool get isPublished => status == 'published';
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
  @JsonKey(name: 'per_page')
  final int perPage;

  const SeriesListResponse({
    required this.total,
    required this.items,
    required this.page,
    required this.perPage,
  });

  factory SeriesListResponse.fromJson(Map<String, dynamic> json) =>
      _$SeriesListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SeriesListResponseToJson(this);
}