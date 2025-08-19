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
