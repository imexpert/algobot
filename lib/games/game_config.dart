import 'package:flutter/foundation.dart';

/// Oyun platformu (Google Play Games / Game Center) açma/kapama anahtarları.
///
/// `false` olduğunda hiçbir platform çağrısı yapılmaz ve platform butonları
/// gizlenir. Uygulama içi başarımlar ekranı ve yerel başarımlar her durumda
/// çalışır.
const bool kGamePlatformEnabled = true;

/// Yalnızca Android: Google Play Games Services.
const bool kPlayGamesEnabled = true;

/// Yalnızca iOS: Game Center.
const bool kGameCenterEnabled = true;

/// Hangi oyun platformu kullanılıyor (servis adı ve buton metinleri için).
enum GamePlatformKind { playGames, gameCenter, none }

/// Anahtarlar ve cihaz platformuna göre kullanılacak servis türü.
/// Parametreler testler içindir.
GamePlatformKind resolveGamePlatform({
  bool enabled = kGamePlatformEnabled,
  bool playGames = kPlayGamesEnabled,
  bool gameCenter = kGameCenterEnabled,
  TargetPlatform? platform,
  bool isWeb = kIsWeb,
}) {
  if (!enabled || isWeb) return GamePlatformKind.none;
  return switch (platform ?? defaultTargetPlatform) {
    TargetPlatform.android when playGames => GamePlatformKind.playGames,
    TargetPlatform.iOS when gameCenter => GamePlatformKind.gameCenter,
    _ => GamePlatformKind.none,
  };
}
