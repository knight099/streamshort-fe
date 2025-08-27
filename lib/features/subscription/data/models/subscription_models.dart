import 'package:json_annotation/json_annotation.dart';

part 'subscription_models.g.dart';

@JsonSerializable()
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final int duration;
  final double amount;
  final String currency;
  @JsonKey(name: 'is_active')
  final bool isActive;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.amount,
    required this.currency,
    required this.isActive,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPlanFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionPlanToJson(this);
}

@JsonSerializable()
class Subscription {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'target_type')
  final String targetType;
  @JsonKey(name: 'target_id')
  final String targetId;
  @JsonKey(name: 'razorpay_subscription_id')
  final String? razorpaySubscriptionId;
  final String status;
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  @JsonKey(name: 'end_date')
  final DateTime endDate;
  @JsonKey(name: 'auto_renew')
  final bool autoRenew;
  @JsonKey(name: 'plan_id')
  final String planId;
  final double amount;
  final String currency;

  const Subscription({
    required this.id,
    required this.userId,
    required this.targetType,
    required this.targetId,
    this.razorpaySubscriptionId,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.autoRenew,
    required this.planId,
    required this.amount,
    required this.currency,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionToJson(this);

  bool get isActive => status == 'active';
  bool get isCancelled => status == 'cancelled';
  bool get isExpired => status == 'expired';
}

@JsonSerializable()
class SubscriptionListResponse {
  final int total;
  final int page;
  @JsonKey(name: 'per_page')
  final int perPage;
  @JsonKey(name: 'total_pages')
  final int totalPages;
  final List<Subscription> subscriptions;

  const SubscriptionListResponse({
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
    required this.subscriptions,
  });

  factory SubscriptionListResponse.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionListResponseToJson(this);
}

@JsonSerializable()
class SubscriptionCheckResponse {
  @JsonKey(name: 'has_access')
  final bool hasAccess;
  @JsonKey(name: 'target_type')
  final String targetType;
  @JsonKey(name: 'target_id')
  final String targetId;
  @JsonKey(name: 'subscription_details')
  final Subscription? subscriptionDetails;

  const SubscriptionCheckResponse({
    required this.hasAccess,
    required this.targetType,
    required this.targetId,
    this.subscriptionDetails,
  });

  factory SubscriptionCheckResponse.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionCheckResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionCheckResponseToJson(this);
}

@JsonSerializable()
class CreateSubscriptionRequest {
  @JsonKey(name: 'target_type')
  final String targetType;
  @JsonKey(name: 'target_id')
  final String targetId;
  @JsonKey(name: 'plan_id')
  final String planId;
  @JsonKey(name: 'auto_renew')
  final bool autoRenew;

  const CreateSubscriptionRequest({
    required this.targetType,
    required this.targetId,
    required this.planId,
    required this.autoRenew,
  });

  factory CreateSubscriptionRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateSubscriptionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateSubscriptionRequestToJson(this);
}

@JsonSerializable()
class CreateSubscriptionResponse {
  @JsonKey(name: 'subscription_id')
  final String subscriptionId;
  final String status;
  @JsonKey(name: 'plan_id')
  final String planId;
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  @JsonKey(name: 'end_date')
  final DateTime endDate;
  @JsonKey(name: 'next_billing')
  final DateTime? nextBilling;
  @JsonKey(name: 'checkout_url')
  final String checkoutUrl;

  const CreateSubscriptionResponse({
    required this.subscriptionId,
    required this.status,
    required this.planId,
    required this.startDate,
    required this.endDate,
    this.nextBilling,
    required this.checkoutUrl,
  });

  factory CreateSubscriptionResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateSubscriptionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreateSubscriptionResponseToJson(this);
}

@JsonSerializable()
class CancelSubscriptionResponse {
  final String message;
  @JsonKey(name: 'subscription_id')
  final String subscriptionId;
  final String status;

  const CancelSubscriptionResponse({
    required this.message,
    required this.subscriptionId,
    required this.status,
  });

  factory CancelSubscriptionResponse.fromJson(Map<String, dynamic> json) =>
      _$CancelSubscriptionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CancelSubscriptionResponseToJson(this);
}

@JsonSerializable()
class RenewSubscriptionResponse {
  final String message;
  @JsonKey(name: 'subscription_id')
  final String subscriptionId;
  final String status;
  @JsonKey(name: 'new_end_date')
  final DateTime newEndDate;

  const RenewSubscriptionResponse({
    required this.message,
    required this.subscriptionId,
    required this.status,
    required this.newEndDate,
  });

  factory RenewSubscriptionResponse.fromJson(Map<String, dynamic> json) =>
      _$RenewSubscriptionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RenewSubscriptionResponseToJson(this);
}
