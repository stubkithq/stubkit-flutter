# Stubkit Flutter SDK

Flutter/Dart SDK for [Stubkit](https://stubkit.com) subscription validation API. Verify in-app purchases and manage entitlements across iOS, Android, and web.

## Installation

```bash
flutter pub add stubkit
```

Or add to your `pubspec.yaml`:

```yaml
dependencies:
  stubkit: ^1.0.0
```

## Quick Start

### 1. Configure

```dart
import 'package:stubkit/stubkit.dart';

void main() {
  Stubkit.configure(apiKey: 'pk_live_xxx', appId: 'myapp');
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

### 3. Sync purchase (after in_app_purchase)

```dart
final entitlements = await Stubkit.shared.syncPurchase(
  userId: 'user_123',
  platform: Platform.android,
  productId: 'com.myapp.pro',
  receipt: purchaseDetails.verificationData.serverVerificationData,
);
```

### 4. Get all entitlements

```dart
final entitlements = await Stubkit.shared.getEntitlements('user_123');
for (final e in entitlements) {
  print('${e.entitlement}: ${e.status}');
}
```

### 5. Force refresh

```dart
final refreshed = await Stubkit.shared.refresh('user_123');
```

## API Reference

### `Stubkit.configure({apiKey, appId, baseUrl?})`

Initialize the SDK. Call once at app startup.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `apiKey` | `String` | Yes | Your Stubkit API key |
| `appId` | `String` | Yes | Your app identifier |
| `baseUrl` | `String` | No | API base URL (default: `https://api.stubkit.com`) |

### `Stubkit.shared.isActive(userId, entitlement): Future<bool>`

Returns `true` if the user has an active (or grace period) entitlement.

### `Stubkit.shared.getEntitlements(userId): Future<List<Entitlement>>`

Returns all entitlements for a user.

### `Stubkit.shared.syncPurchase({userId, platform, productId, receipt, transactionId?}): Future<List<Entitlement>>`

Syncs a purchase receipt with Stubkit. Returns updated entitlements.

### `Stubkit.shared.refresh(userId): Future<List<Entitlement>>`

Force-refreshes entitlements from the server.

## Models

### `Platform`
`ios`, `android`, `web`

### `EntitlementStatus`
`active`, `grace`, `expired`, `cancelled`, `refunded`

### `EntitlementSource`
`iap`, `stripe`, `adminGrant`, `trial`

### `Entitlement`
```dart
class Entitlement {
  final String entitlement;
  final EntitlementStatus status;
  final EntitlementSource source;
  final String productId;
  final String? expiresAt;
  final String? renewedAt;
  final String? graceExpiresAt;
}
```

## Error Handling

All methods throw `StubkitError` on failure:

```dart
try {
  final entitlements = await Stubkit.shared.getEntitlements('user_123');
} on StubkitError catch (e) {
  print('Error: ${e.code} - ${e.message}');
}
```

`isActive` returns `false` instead of throwing on errors.

## Requirements

- Dart SDK >= 3.0.0
- Flutter 3.10+

## License

MIT - Cryptosam LLC
