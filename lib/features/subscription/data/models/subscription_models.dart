import 'package:json_annotation/json_annotation.dart';

part 'subscription_models.g.dart';

@JsonSerializable()
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  @JsonKey(name: 'price_amount')
  final double priceAmount;
  @JsonKey(name: 'price_currency')
  final String priceCurrency;
  @JsonKey(name: 'billing_interval')
  final String billingInterval;
  @JsonKey(name: 'trial_days')
  final int? trialDays;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.priceAmount,
    required this.priceCurrency,
    required this.billingInterval,
    this.trialDays,
    required this.createdAt,
    this.updatedAt,
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
  @JsonKey(name: 'plan_id')
  final String planId;
  final String status;
  @JsonKey(name: 'current_period_start')
  final DateTime currentPeriodStart;
  @JsonKey(name: 'current_period_end')
  final DateTime currentPeriodEnd;
  @JsonKey(name: 'trial_end')
  final DateTime? trialEnd;
  @JsonKey(name: 'cancel_at')
  final DateTime? cancelAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const Subscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.status,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    this.trialEnd,
    this.cancelAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionToJson(this);
}

@JsonSerializable()
class PaymentCreateRequest {
  final String planId;
  @JsonKey(name: 'payment_method')
  final String paymentMethod;

  const PaymentCreateRequest({
    required this.planId,
    required this.paymentMethod,
  });

  factory PaymentCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$PaymentCreateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentCreateRequestToJson(this);
}

@JsonSerializable()
class PaymentCreateResponse {
  @JsonKey(name: 'payment_url')
  final String paymentUrl;
  @JsonKey(name: 'payment_id')
  final String paymentId;

  const PaymentCreateResponse({
    required this.paymentUrl,
    required this.paymentId,
  });

  factory PaymentCreateResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentCreateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentCreateResponseToJson(this);
}
