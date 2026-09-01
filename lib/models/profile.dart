class Profile {
  final String id;
  final String subscriptionStatus;
  final DateTime? subscriptionExpiry;

  Profile({
    required this.id,
    required this.subscriptionStatus,
    this.subscriptionExpiry,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String? ?? '',
      subscriptionStatus: json['subscription_status'] as String? ?? 'free',
      subscriptionExpiry: json['subscription_expiry'] != null
          ? DateTime.tryParse(json['subscription_expiry'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subscription_status': subscriptionStatus,
      'subscription_expiry': subscriptionExpiry?.toIso8601String(),
    };
  }

  bool get isPremium => subscriptionStatus == 'premium';
}