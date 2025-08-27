import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:json_annotation/json_annotation.dart';
import '../config/environment.dart';
import '../../features/creator/data/models/creator_models.dart';
import '../../features/subscription/data/models/subscription_models.dart';

part 'api_client.g.dart';

@RestApi(baseUrl: "https://api.streamshort.in/")
abstract class ApiClient {
  factory ApiClient(Dio dio, {String? baseUrl}) = _ApiClient;
  
  static ApiClient create(Dio dio) {
    return ApiClient(dio, baseUrl: EnvironmentConfig.apiBaseUrl);
  }

  // Auth endpoints
  @POST('auth/otp/send')
  Future<PhoneOtpSendResponse> sendOtp(@Body() PhoneOtpRequest request);

  @POST('auth/otp/verify')
  Future<TokenResponse> verifyOtp(@Body() PhoneOtpVerifyRequest request);

  @POST('auth/refresh')
  Future<TokenResponse> refreshToken(@Body() RefreshRequest request);

  // Content endpoints
  @GET('content/series')
  Future<SeriesListResponse> getSeries({
    @Query('page') int? page,
    @Query('limit') int? limit,
    @Query('category') String? category,
    @Query('language') String? language,
    @Query('search') String? search,
  });

  @GET('content/series/{id}')
  Future<Series> getSeriesById(@Path('id') String id);

  @GET('content/series/{seriesId}/episodes')
  Future<List<Episode>> getEpisodes(@Path('seriesId') String seriesId);

  // Creator endpoints
  @POST('api/creators/onboard')
  Future<CreatorProfile> onboardCreator(@Body() CreatorOnboardRequest request);

  @GET('api/creators/profile')
  Future<CreatorProfile> getCreatorProfile();

  @GET('api/creators/{id}/dashboard')
  Future<CreatorDashboardResponse> getCreatorDashboard(@Path('id') String creatorId);

  // User endpoints
  @GET('api/profile')
  Future<User> getUserProfile();

  @PUT('api/profile')
  Future<User> updateUserProfile(@Body() User user);

  // Subscription endpoints
  @GET('subscriptions/plans')
  Future<List<SubscriptionPlan>> getSubscriptionPlans();

  @GET('subscriptions/user')
  Future<Subscription> getUserSubscription();

  @POST('subscriptions/create')
  Future<CreateSubscriptionResponse> createSubscription(@Body() CreateSubscriptionRequest request);
}

// Auth Models
@JsonSerializable()
class PhoneOtpRequest {
  final String phone;
  final String countryCode;

  PhoneOtpRequest({required this.phone, this.countryCode = '+91'});

  factory PhoneOtpRequest.fromJson(Map<String, dynamic> json) => _$PhoneOtpRequestFromJson(json);
  Map<String, dynamic> toJson() => _$PhoneOtpRequestToJson(this);
}

@JsonSerializable()
class PhoneOtpSendResponse {
  final String txnId;
  final int expiresIn;
  final String message;

  const PhoneOtpSendResponse({
    required this.txnId,
    required this.expiresIn,
    required this.message,
  });

  factory PhoneOtpSendResponse.fromJson(Map<String, dynamic> json) =>
      _$PhoneOtpSendResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PhoneOtpSendResponseToJson(this);
}

@JsonSerializable()
class PhoneOtpVerifyRequest {
  final String phone;
  final String otp;

  const PhoneOtpVerifyRequest({
    required this.phone,
    required this.otp,
  });

  factory PhoneOtpVerifyRequest.fromJson(Map<String, dynamic> json) =>
      _$PhoneOtpVerifyRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PhoneOtpVerifyRequestToJson(this);
}

@JsonSerializable()
class TokenResponse {
  final String accessToken;
  final String refreshToken;
  final User user;

  TokenResponse({required this.accessToken, required this.refreshToken, required this.user});

  factory TokenResponse.fromJson(Map<String, dynamic> json) => _$TokenResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TokenResponseToJson(this);
}

@JsonSerializable()
class RefreshRequest {
  final String refreshToken;

  RefreshRequest({required this.refreshToken});

  factory RefreshRequest.fromJson(Map<String, dynamic> json) => _$RefreshRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RefreshRequestToJson(this);
}

@JsonSerializable()
class User {
  final String id;
  final String phone;
  final String? displayName;
  final String? avatarUrl;
  final String role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? accessToken;

  User({
    required this.id,
    required this.phone,
    this.displayName,
    this.avatarUrl,
    required this.role,
    required this.createdAt,
    this.lastLoginAt,
    this.accessToken,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  bool get isCreator => role == 'creator';
  bool get isAdmin => role == 'admin';
}

// Content Models
@JsonSerializable()
class Series {
  final String id;
  @JsonKey(name: 'creator_id')
  final String creatorId;
  @JsonKey(name: 'creator_name')
  final String creatorName;
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
  @JsonKey(name: 'adult_content')
  final bool adultContent;
  @JsonKey(name: 'episodes')
  final List<Episode>? episodes;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Series({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.title,
    required this.synopsis,
    required this.language,
    required this.categoryTags,
    required this.priceType,
    this.priceAmount,
    this.thumbnailUrl,
    required this.status,
    this.adultContent = false,
    this.episodes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Series.fromJson(Map<String, dynamic> json) => _$SeriesFromJson(json);
  Map<String, dynamic> toJson() => _$SeriesToJson(this);

  String get category => categoryTags.isNotEmpty ? categoryTags[0] : 'Uncategorized';
  bool get isFree => priceType == 'free';
}

@JsonSerializable()
class Episode {
  final String id;
  final String title;
  @JsonKey(name: 'episode_number')
  final int episodeNumber;
  @JsonKey(name: 'duration_seconds')
  final int durationSeconds;
  @JsonKey(name: 'thumb_url')
  final String? thumbUrl;
  @JsonKey(name: 'published_at')
  final DateTime? publishedAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Episode({
    required this.id,
    required this.title,
    required this.episodeNumber,
    required this.durationSeconds,
    this.thumbUrl,
    this.publishedAt,
    required this.createdAt,
  });

  factory Episode.fromJson(Map<String, dynamic> json) => _$EpisodeFromJson(json);
  Map<String, dynamic> toJson() => _$EpisodeToJson(this);
}

@JsonSerializable()
class SeriesListResponse {
  final List<Series> items;
  final int? total;
  final int? page;
  final int? limit;

  SeriesListResponse({
    required this.items,
    this.total,
    this.page,
    this.limit,
  });

  factory SeriesListResponse.fromJson(Map<String, dynamic> json) => _$SeriesListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SeriesListResponseToJson(this);
}



