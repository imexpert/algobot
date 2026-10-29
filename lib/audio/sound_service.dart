import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../state/settings_controller.dart';

enum Sound {
  tap('tap.wav'),
  cardAdd('card_add.wav'),
  cardRemove('card_remove.wav'),
  step('step.wav'),
  turn('turn.wav'),
  battery('battery.wav'),
  crash('crash.wav'),
  win('win.wav'),
  star('star.wav'),

  /// Açılış sesi. Profesyonel bir sesle değiştirmek için yalnızca
  /// `assets/sounds/splash.wav` dosyasını değiştirmek yeterli.
  splash('splash.wav');

  const Sound(this.file);
  final String file;
}

/// Kısa efekt seslerini çalar. Ses kapalıyken hiçbir şey çalmaz.
///
/// Ses oturumu "ortam" türündedir: iOS'ta sessiz anahtarına uyar ve
/// kullanıcının dinlediği müziği kesmez; Android'de ses odağı istemez.
class SoundService {
  SoundService(this._settings);

  final SettingsController _settings;
  final Map<Sound, AudioPlayer> _players = {};

  static final _audioContext = AudioContext(
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
  );

  /// Ses bağlamını ayarlar ve dosyaları önbelleğe alır (açılışta).
  Future<void> preload() async {
    try {
      await AudioPlayer.global.setAudioContext(_audioContext);
      await AudioCache.instance.loadAll([
        for (final s in Sound.values) 'sounds/${s.file}',
      ]);
    } catch (e) {
      debugPrint('Sesler önbelleğe alınamadı: $e');
    }
  }

  void play(Sound sound) {
    if (!_settings.soundOn) return;
    playNow(sound);
  }

  /// Sesi gerçekten çalar. Testlerde sahte uygulama bunu geçersiz kılar.
  @protected
  Future<void> playNow(Sound sound) async {
    try {
      final player = _players.putIfAbsent(sound, () {
        final p = AudioPlayer()
          ..setReleaseMode(ReleaseMode.stop)
          // Efektler için konum gerekmez. Android'de düşük gecikme modu
          // "bitti" olayı göndermediği için varsayılan konum güncelleyici
          // hiç durmuyor ve her karede çalışıyordu (pil tüketimi).
          ..positionUpdater = null;
        p.setAudioContext(_audioContext);
        return p;
      });
      await player.stop();
      await player.play(
        AssetSource('sounds/${sound.file}'),
        volume: 0.8,
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {
      // Ses çalınamazsa oyun sessizce devam eder.
    }
  }

  /// Çalan bir sesi keser (ör. açılış atlanınca).
  Future<void> stop(Sound sound) async {
    try {
      await _players[sound]?.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    for (final p in _players.values) {
      await p.dispose();
    }
    _players.clear();
  }
}
