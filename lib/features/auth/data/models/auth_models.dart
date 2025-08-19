import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

@JsonSerializable()
class PhoneOtpRequest {
  final String phone;

  const PhoneOtpRequest({required this.phone});

  factory PhoneOtpRequest.fromJson(Map<String, dynamic> json) =>
      _$PhoneOtpRequestFromJson(json);

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
  final int expiresIn;

  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) =>
      _$TokenResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TokenResponseToJson(this);
}

@JsonSerializable()
class RefreshRequest {
  final String refreshToken;

  const RefreshRequest({required this.refreshToken});

  factory RefreshRequest.fromJson(Map<String, dynamic> json) =>
      _$RefreshRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RefreshRequestToJson(this);
}

@JsonSerializable()
class User {
  final String id;
  final String phone;
  final String? displayName;
  final String? avatarUrl;
  final String role; // user, creator, admin
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const User({
    required this.id,
    required this.phone,
    this.displayName,
    this.avatarUrl,
    required this.role,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  bool get isCreator => role == 'creator';
  bool get isAdmin => role == 'admin';
}
