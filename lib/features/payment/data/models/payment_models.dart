import 'package:json_annotation/json_annotation.dart';

part 'payment_models.g.dart';

@JsonSerializable()
class PaymentCreateRequest {
  final String? userId;
  final String targetType; // series, creator
  final String targetId;
  final String planId;

  const PaymentCreateRequest({
    this.userId,
    required this.targetType,
    required this.targetId,
    required this.planId,
  });

  factory PaymentCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$PaymentCreateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentCreateRequestToJson(this);
}

@JsonSerializable()
class PaymentCreateResponse {
  final String razorpayOrderId;
  final String razorpaySubscriptionId;
  final String subscriptionId;
  final String checkoutUrl;

  const PaymentCreateResponse({
    required this.razorpayOrderId,
    required this.razorpaySubscriptionId,
    required this.subscriptionId,
    required this.checkoutUrl,
  });

  factory PaymentCreateResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentCreateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentCreateResponseToJson(this);
}

@JsonSerializable()
class PaymentWebhookPayload {
  final String event;
  final Map<String, dynamic> payload;

  const PaymentWebhookPayload({
    required this.event,
    required this.payload,
  });

  factory PaymentWebhookPayload.fromJson(Map<String, dynamic> json) =>
      _$PaymentWebhookPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentWebhookPayloadToJson(this);
}

@JsonSerializable()
class Subscription {
  final String id;
  final String userId;
  final String targetType;
  final String targetId;
  final String razorpaySubscriptionId;
  final String status; // active, cancelled, expired
  final DateTime startDate;
  final DateTime endDate;
  final double amount;
  final String currency;
  final String? planName;

  const Subscription({
    required this.id,
    required this.userId,
    required this.targetType,
    required this.targetId,
    required this.razorpaySubscriptionId,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.amount,
    required this.currency,
    this.planName,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionToJson(this);

  bool get isActive => status == 'active';
  bool get isExpired => status == 'expired';
  bool get isCancelled => status == 'cancelled';
  
  String get amountFormatted => '₹${amount.toStringAsFixed(2)}';
  
  bool get isExpiringSoon {
    final now = DateTime.now();
    final daysUntilExpiry = endDate.difference(now).inDays;
    return daysUntilExpiry <= 7 && daysUntilExpiry > 0;
  }
}

@JsonSerializable()
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String billingCycle; // monthly, yearly
  final int durationDays;
  final List<String> features;
  final bool isPopular;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.billingCycle,
    required this.durationDays,
    required this.features,
    this.isPopular = false,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPlanFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionPlanToJson(this);

  String get priceFormatted => '₹${price.toStringAsFixed(2)}';
  String get billingCycleFormatted => billingCycle == 'monthly' ? '/month' : '/year';
}
