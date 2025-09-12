import 'package:json_annotation/json_annotation.dart';

part 'profile_models.g.dart';

@JsonSerializable()
class UserProfileResponse {
  @JsonKey(name: 'user_id')
  final String userId;
  final String phone;

  const UserProfileResponse({
    required this.userId,
    required this.phone,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$UserProfileResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileResponseToJson(this);
}
