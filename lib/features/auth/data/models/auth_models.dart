import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String phone;
  final String? displayName;
  final String? avatarUrl;
  final String role; // user, creator, admin
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? accessToken;

  const User({
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
