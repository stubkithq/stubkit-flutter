import 'http.dart';
import 'models.dart';

export 'models.dart';

class Stubkit {
  final StubkitHTTP _http;
  final String _appId;

  static Stubkit? _instance;

  Stubkit._({
    required StubkitHTTP http,
    required String appId,
  })  : _http = http,
        _appId = appId;

  static Stubkit get shared {
    if (_instance == null) {
      throw StubkitError(
        'not_configured',
        'Call Stubkit.configure() before accessing Stubkit.shared',
      );
    }
    return _instance!;
  }

  /// Configure the SDK. Call once at app startup.
  ///
  /// [publishableKey] — `pk_live_...` / `pk_test_...`. Safe to ship in the app.
  /// [appId] — Your stubkit app identifier.
  /// [getAuthToken] — Async callback returning your tenant JWT (end-user identity).
  /// [baseUrl] — Override for staging / self-hosted.
  static void configure({
    required String publishableKey,
    required String appId,
    required GetAuthToken getAuthToken,
    String baseUrl = 'https://api.stubkit.com',
  }) {
    _instance = Stubkit._(
      http: StubkitHTTP(
        publishableKey: publishableKey,
        getAuthToken: getAuthToken,
        baseUrl: baseUrl,
      ),
      appId: appId,
    );
  }

  /// Check if a user has an active entitlement.
  Future<bool> isActive(String userId, String entitlement) async {
    final list = await getEntitlements(userId);
    Entitlement? match;
    for (final e in list) {
      if (e.id == entitlement) {
        match = e;
        break;
      }
    }
    if (match == null) return false;
    if (match.status == EntitlementStatus.active ||
        match.status == EntitlementStatus.grace) {
      return true;
    }
    if (match.status == EntitlementStatus.cancelled && match.expiresAt != null) {
      final exp = DateTime.tryParse(match.expiresAt!);
      return exp != null && exp.isAfter(DateTime.now());
    }
    return false;
  }

  /// Get all entitlements for a user. Uses the tenant JWT.
  Future<List<Entitlement>> getEntitlements(String userId) async {
    final path = '/v1/entitlement/$_appId/${Uri.encodeComponent(userId)}';
    final data = await _http.get(path, StubkitAuth.tenantJwt);
    final list = data['entitlements'] as List<dynamic>? ?? [];
    return list.map((e) => Entitlement.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Force refresh entitlements (bypass cache). Uses the tenant JWT.
  Future<List<Entitlement>> refresh(String userId) async {
    final path = '/v1/entitlement/$_appId/${Uri.encodeComponent(userId)}/refresh';
    final data = await _http.post(path, auth: StubkitAuth.tenantJwt);
    final list = data['entitlements'] as List<dynamic>? ?? [];
    return list.map((e) => Entitlement.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Sync a purchase receipt. Uses the tenant JWT.
  Future<List<Entitlement>> syncPurchase({
    required String userId,
    required Platform platform,
    required String productId,
    required String receipt,
    String? transactionId,
    String? purchaseToken,
  }) async {
    final body = <String, dynamic>{
      'app_id': _appId,
      'user_id': userId,
      'platform': platform.toJson(),
      'product_id': productId,
      'receipt': receipt,
      if (transactionId != null) 'transaction_id': transactionId,
      if (purchaseToken != null) 'purchase_token': purchaseToken,
    };
    final data = await _http.post(
      '/v1/purchases',
      body: body,
      auth: StubkitAuth.tenantJwt,
    );
    final list = data['entitlements'] as List<dynamic>? ?? [];
    return list.map((e) => Entitlement.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetch paywall config. Uses the publishable key.
  Future<Offering> getOffering({String slug = 'default', String? locale}) async {
    final query = locale != null ? '?locale=${Uri.encodeQueryComponent(locale)}' : '';
    final path = '/v1/offerings/$_appId/$slug$query';
    final data = await _http.get(path, StubkitAuth.publishable);
    return Offering.fromJson(data);
  }

  /// Record a behavioural event. Uses the publishable key.
  /// Returns an optional paywall suggestion when an event-rule matches.
  Future<TrackResult> track({
    required String event,
    required String userId,
    Map<String, dynamic> properties = const {},
  }) async {
    final body = {
      'event': event,
      'user_id': userId,
      'properties': properties,
    };
    final data = await _http.post(
      '/v1/events/track',
      body: body,
      auth: StubkitAuth.publishable,
    );
    return TrackResult.fromJson(data);
  }
}
