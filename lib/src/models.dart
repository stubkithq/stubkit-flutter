enum Platform {
  ios,
  android,
  web;

  String toJson() => name;

  static Platform fromJson(String value) {
    return Platform.values.firstWhere((e) => e.name == value, orElse: () => Platform.ios);
  }
}

enum EntitlementStatus {
  active,
  grace,
  expired,
  cancelled,
  refunded;

  static EntitlementStatus fromJson(String value) {
    return EntitlementStatus.values
        .firstWhere((e) => e.name == value, orElse: () => EntitlementStatus.expired);
  }
}

enum EntitlementSource {
  iap,
  stripe,
  adminGrant,
  trial;

  static EntitlementSource fromJson(String value) {
    const mapping = {
      'iap': EntitlementSource.iap,
      'stripe': EntitlementSource.stripe,
      'admin_grant': EntitlementSource.adminGrant,
      'trial': EntitlementSource.trial,
    };
    return mapping[value] ?? EntitlementSource.iap;
  }

  String toJson() {
    const mapping = {
      EntitlementSource.iap: 'iap',
      EntitlementSource.stripe: 'stripe',
      EntitlementSource.adminGrant: 'admin_grant',
      EntitlementSource.trial: 'trial',
    };
    return mapping[this]!;
  }
}

class Entitlement {
  final String id;
  final EntitlementStatus status;
  final EntitlementSource source;
  final Platform platform;
  final String productId;
  final String? expiresAt;

  const Entitlement({
    required this.id,
    required this.status,
    required this.source,
    required this.platform,
    required this.productId,
    this.expiresAt,
  });

  factory Entitlement.fromJson(Map<String, dynamic> json) {
    return Entitlement(
      id: json['id'] as String,
      status: EntitlementStatus.fromJson(json['status'] as String),
      source: EntitlementSource.fromJson(json['source'] as String),
      platform: Platform.fromJson(json['platform'] as String),
      productId: json['product_id'] as String,
      expiresAt: json['expires_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.name,
      'source': source.toJson(),
      'platform': platform.toJson(),
      'product_id': productId,
      if (expiresAt != null) 'expires_at': expiresAt,
    };
  }
}

class OfferingProduct {
  final String productId;
  final Platform platform;
  final int? periodDays;
  final int? priceUsdCents;
  final String entitlement;

  const OfferingProduct({
    required this.productId,
    required this.platform,
    required this.entitlement,
    this.periodDays,
    this.priceUsdCents,
  });

  factory OfferingProduct.fromJson(Map<String, dynamic> json) {
    return OfferingProduct(
      productId: json['product_id'] as String,
      platform: Platform.fromJson(json['platform'] as String),
      periodDays: json['period_days'] as int?,
      priceUsdCents: json['price_usd_cents'] as int?,
      entitlement: json['entitlement'] as String,
    );
  }
}

class Offering {
  final String slug;
  final String title;
  final String? subtitle;
  final List<String> features;
  final String ctaLabel;
  final String? locale;
  final List<OfferingProduct> products;

  const Offering({
    required this.slug,
    required this.title,
    required this.ctaLabel,
    this.subtitle,
    this.features = const [],
    this.locale,
    this.products = const [],
  });

  factory Offering.fromJson(Map<String, dynamic> json) {
    return Offering(
      slug: json['slug'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      features: (json['features'] as List<dynamic>? ?? []).cast<String>(),
      ctaLabel: json['cta_label'] as String,
      locale: json['locale'] as String?,
      products: (json['products'] as List<dynamic>? ?? [])
          .map((p) => OfferingProduct.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TrackResult {
  final String? matchedRuleId;
  final Offering? showPaywall;

  const TrackResult({this.matchedRuleId, this.showPaywall});

  factory TrackResult.fromJson(Map<String, dynamic> json) {
    return TrackResult(
      matchedRuleId: json['matched_rule_id'] as String?,
      showPaywall: json['show_paywall'] != null
          ? Offering.fromJson(json['show_paywall'] as Map<String, dynamic>)
          : null,
    );
  }
}

class StubkitError extends Error {
  final String code;
  @override
  final String message;

  StubkitError(this.code, this.message);

  @override
  String toString() => 'StubkitError([$code] $message)';
}
