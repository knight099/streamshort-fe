import 'package:json_annotation/json_annotation.dart';

part 'follow_models.g.dart';

@JsonSerializable()
class FollowResponse {
  final String status;

  const FollowResponse({
    required this.status,
  });

  factory FollowResponse.fromJson(Map<String, dynamic> json) => _$FollowResponseFromJson(json);
  Map<String, dynamic> toJson() => _$FollowResponseToJson(this);
}

@JsonSerializable()
class FollowingCheckResponse {
  final bool following;

  const FollowingCheckResponse({
    required this.following,
  });

  factory FollowingCheckResponse.fromJson(Map<String, dynamic> json) => _$FollowingCheckResponseFromJson(json);
  Map<String, dynamic> toJson() => _$FollowingCheckResponseToJson(this);
}

@JsonSerializable()
class FollowedCreator {
  final String id;
  final String displayName;
  final String? bio;
  final int followerCount;
  final String? avatarUrl;
  final String? kycStatus;
  final DateTime createdAt;

  const FollowedCreator({
    required this.id,
    required this.displayName,
    this.bio,
    required this.followerCount,
    this.avatarUrl,
    this.kycStatus,
    required this.createdAt,
  });

  factory FollowedCreator.fromJson(Map<String, dynamic> json) => _$FollowedCreatorFromJson(json);
  Map<String, dynamic> toJson() => _$FollowedCreatorToJson(this);
}

@JsonSerializable()
class FollowingListResponse {
  final int total;
  final List<FollowedCreator> items;

  const FollowingListResponse({
    required this.total,
    required this.items,
  });

  factory FollowingListResponse.fromJson(Map<String, dynamic> json) => _$FollowingListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$FollowingListResponseToJson(this);
}

@JsonSerializable()
class SeriesWithCreatorData {
  final String id;
  final String creatorId;
  final String? creatorName;
  final int followerCount;
  final bool following;

  const SeriesWithCreatorData({
    required this.id,
    required this.creatorId,
    this.creatorName,
    required this.followerCount,
    required this.following,
  });

  factory SeriesWithCreatorData.fromJson(Map<String, dynamic> json) => _$SeriesWithCreatorDataFromJson(json);
  Map<String, dynamic> toJson() => _$SeriesWithCreatorDataToJson(this);
}
