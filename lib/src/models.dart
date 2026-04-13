enum Platform {
  ios,
  android,
  web;

  String toJson() => name;
}

enum EntitlementStatus {
  active,
  grace,
  expired,
  cancelled,
  refunded;

  static EntitlementStatus fromJson(String value) {
    return EntitlementStatus.values.firstWhere((e) => e.name == value);
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
  final String entitlement;
  final EntitlementStatus status;
  final EntitlementSource source;
  final String productId;
  final String? expiresAt;
  final String? renewedAt;
  final String? graceExpiresAt;

  const Entitlement({
    required this.entitlement,
    required this.status,
    required this.source,
    required this.productId,
    this.expiresAt,
    this.renewedAt,
    this.graceExpiresAt,
  });

  factory Entitlement.fromJson(Map<String, dynamic> json) {
    return Entitlement(
      entitlement: json['entitlement'] as String,
      status: EntitlementStatus.fromJson(json['status'] as String),
      source: EntitlementSource.fromJson(json['source'] as String),
      productId: json['product_id'] as String,
      expiresAt: json['expires_at'] as String?,
      renewedAt: json['renewed_at'] as String?,
      graceExpiresAt: json['grace_expires_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entitlement': entitlement,
      'status': status.name,
      'source': source.toJson(),
      'product_id': productId,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (renewedAt != null) 'renewed_at': renewedAt,
      if (graceExpiresAt != null) 'grace_expires_at': graceExpiresAt,
    };
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
