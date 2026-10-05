import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'app_services.dart';
import 'audio/sound_service.dart';
import 'state/settings_controller.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Yerel açılış ekranı, Flutter açılış ekranının ilk karesi çizilene
  // kadar kalır (beyaz ekran yanıp sönmez).
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Ayarlar hızlıdır ve açılış sesinin ilk karede ses tercihine uyması için
  // gereklidir; geri kalan her şey açılış animasyonuyla paralel yüklenir.
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsController(prefs);
  final sound = SoundService(settings);

  runApp(
    AlgoBotApp(
      settings: settings,
      sound: sound,
      services: loadAppServices(prefs, sound),
    ),
  );
}
