# Stubkit Flutter SDK

Flutter/Dart SDK for [Stubkit](https://stubkit.com) subscription validation API. Verify in-app purchases and manage entitlements across iOS, Android, and web.

## Installation

Add to your `pubspec.yaml` via a git reference (stubkit is distributed
straight from GitHub; no pub.dev publication required):

```yaml
dependencies:
  stubkit:
    git:
      url: https://github.com/stubkithq/stubkit-flutter
      ref: v1.0.1
```

Then run `flutter pub get`.

## Quick Start

The SDK uses two auth inputs: a **publishable key** (safe to ship in the
app) for offering + event calls, and a **tenant JWT** callback that returns
the end-user's identity token for entitlement + purchase calls.

### 1. Configure

```dart
import 'package:stubkit/stubkit.dart';

void main() {
  Stubkit.configure(
    publishableKey: 'pk_live_xxxxxxxxxxxxxxxxxxxxxxxx',
    appId: 'your-app-id',
    getAuthToken: () async {
      // Return your tenant JWT — Supabase access token / Clerk JWT /
      // Firebase ID token / custom RS256 token.
      return await authProvider.currentAccessToken();
    },
  );
  runApp(MyApp());
}
```

### 2. Check entitlement

```dart
final isPro = await Stubkit.shared.isActive('user_123', 'pro');
if (isPro) {
  // Unlock pro features
}
```

### 3. Fetch paywall config

```dart
final offering = await Stubkit.shared.getOffering();
print(offering.title);       // "Unlock Pro"
print(offering.features);    // ["Unlimited projects", ...]
```

### 4. Sync purchase (after in_app_purchase)

```dart
final entitlements = await Stubkit.shared.syncPurchase(
  userId: 'user_123',
  platform: Platform.android,
  productId: 'com.myapp.pro',
  receipt: purchaseDetails.verificationData.serverVerificationData,
);
```

### 5. Track behavioural events

```dart
final result = await Stubkit.shared.track(
  event: 'hit_export_limit',
  userId: 'user_123',
  properties: {'count': 5, 'plan': 'free'},
);
if (result.showPaywall != null) {
  presentPaywall(result.showPaywall!);
}
```

### 6. Force refresh

```dart
final refreshed = await Stubkit.shared.refresh('user_123');
```

## API Reference

### `Stubkit.configure({publishableKey, appId, getAuthToken, baseUrl?})`

Initialize the SDK. Call once at app startup.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `publishableKey` | `String` | Yes | `pk_live_…` / `pk_test_…` |
| `appId` | `String` | Yes | Your stubkit app identifier |
| `getAuthToken` | `Future<String> Function()` | Yes | Returns your tenant JWT |
| `baseUrl` | `String` | No | API base URL (default: `https://api.stubkit.com`) |

### Entitlement & purchases (uses tenant JWT)

- `isActive(userId, entitlement)` → `Future<bool>`
- `getEntitlements(userId)` → `Future<List<Entitlement>>`
- `syncPurchase({userId, platform, productId, receipt, transactionId?, purchaseToken?})` → `Future<List<Entitlement>>`
- `refresh(userId)` → `Future<List<Entitlement>>`

### Paywalls & events (uses publishable key)

- `getOffering({slug = 'default', locale})` → `Future<Offering>`
- `track({event, userId, properties})` → `Future<TrackResult>`

## Error handling

```dart
try {
  final entitlements = await Stubkit.shared.getEntitlements('user_123');
} on StubkitError catch (e) {
  print('Error: ${e.code} - ${e.message}');
}
```

`isActive` returns `false` instead of throwing on errors.

## Migrating from 1.0.0

The single-key `configure(apiKey:, appId:)` is gone. Replace with:

```dart
Stubkit.configure(
  publishableKey: 'pk_live_x',
  appId: 'app',
  getAuthToken: () async => await auth.token(),
);
```

Offering and event calls use the publishable key automatically;
entitlement and purchase calls use the JWT returned from `getAuthToken`.

## Requirements

- Dart SDK >= 3.0.0
- Flutter 3.10+

## Links

- [Documentation](https://docs.stubkit.com)
- [Tenant JWT setup](https://docs.stubkit.com/getting-started/tenant-jwt)
- [Dashboard](https://app.stubkit.com)

## License

MIT — Cryptosam LLC
