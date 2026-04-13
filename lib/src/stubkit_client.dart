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

  static void configure({
    required String apiKey,
    required String appId,
    String baseUrl = 'https://api.stubkit.com',
  }) {
    _instance = Stubkit._(
      http: StubkitHTTP(apiKey: apiKey, baseUrl: baseUrl),
      appId: appId,
    );
  }

  Future<bool> isActive(String userId, String entitlement) async {
    try {
      final data = await _http.get(
        '/v1/apps/$_appId/users/$userId/entitlements/$entitlement',
      );
      final status = EntitlementStatus.fromJson(data['status'] as String);
      return status == EntitlementStatus.active ||
          status == EntitlementStatus.grace;
    } on StubkitError {
      return false;
    }
  }

  Future<List<Entitlement>> getEntitlements(String userId) async {
    final data = await _http.get(
      '/v1/apps/$_appId/users/$userId/entitlements',
    );
    final list = data['entitlements'] as List<dynamic>? ?? [];
    return list
        .map((e) => Entitlement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Entitlement>> syncPurchase({
    required String userId,
    required Platform platform,
    required String productId,
    required String receipt,
    String? transactionId,
  }) async {
    final body = <String, dynamic>{
      'user_id': userId,
      'platform': platform.toJson(),
      'product_id': productId,
      'receipt': receipt,
      if (transactionId != null) 'transaction_id': transactionId,
    };
    final data = await _http.post('/v1/apps/$_appId/purchases', body: body);
    final list = data['entitlements'] as List<dynamic>? ?? [];
    return list
        .map((e) => Entitlement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Entitlement>> refresh(String userId) async {
    final data = await _http.post(
      '/v1/apps/$_appId/users/$userId/refresh',
    );
    final list = data['entitlements'] as List<dynamic>? ?? [];
    return list
        .map((e) => Entitlement.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
