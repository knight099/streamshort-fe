import 'package:json_annotation/json_annotation.dart';

part 'engagement_models.g.dart';

@JsonSerializable()
class LikeRequest {
  final String episodeId;

  const LikeRequest({required this.episodeId});

  factory LikeRequest.fromJson(Map<String, dynamic> json) =>
      _$LikeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LikeRequestToJson(this);
}

@JsonSerializable()
class LikeResponse {
  final bool liked;
  final int totalLikes;

  const LikeResponse({
    required this.liked,
    required this.totalLikes,
  });

  factory LikeResponse.fromJson(Map<String, dynamic> json) =>
      _$LikeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LikeResponseToJson(this);
}

@JsonSerializable()
class RatingRequest {
  final String episodeId;
  final int score; // 1-5

  const RatingRequest({
    required this.episodeId,
    required this.score,
  });

  factory RatingRequest.fromJson(Map<String, dynamic> json) =>
      _$RatingRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RatingRequestToJson(this);
}

@JsonSerializable()
class RatingResponse {
  final int rating;
  final double averageRating;
  final int totalRatings;

  const RatingResponse({
    required this.rating,
    required this.averageRating,
    required this.totalRatings,
  });

  factory RatingResponse.fromJson(Map<String, dynamic> json) =>
      _$RatingResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RatingResponseToJson(this);
}

@JsonSerializable()
class CommentRequest {
  final String episodeId;
  final String text;

  const CommentRequest({
    required this.episodeId,
    required this.text,
  });

  factory CommentRequest.fromJson(Map<String, dynamic> json) =>
      _$CommentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CommentRequestToJson(this);
}

@JsonSerializable()
class CommentResponse {
  final String id;
  final String userId;
  final String episodeId;
  final String text;
  final DateTime createdAt;
  final String? userDisplayName;
  final String? userAvatarUrl;

  const CommentResponse({
    required this.id,
    required this.userId,
    required this.episodeId,
    required this.text,
    required this.createdAt,
    this.userDisplayName,
    this.userAvatarUrl,
  });

  factory CommentResponse.fromJson(Map<String, dynamic> json) =>
      _$CommentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CommentResponseToJson(this);

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

@JsonSerializable()
class CommentListResponse {
  final int total;
  final List<CommentResponse> items;
  final int page;
  final int perPage;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const CommentListResponse({
    required this.total,
    required this.items,
    required this.page,
    required this.perPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory CommentListResponse.fromJson(Map<String, dynamic> json) =>
      _$CommentListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CommentListResponseToJson(this);
}
