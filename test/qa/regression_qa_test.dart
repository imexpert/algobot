// QA: QA_RAPORU.md'deki düzeltilmiş hataların gerileme testleri (QA-1 …).
// Her test bir bulguya karşılık gelir; yeniden kırmızıya dönerse hata geri
// gelmiş demektir.
import 'dart:async';

import 'package:algobot/app_services.dart';
import 'package:algobot/audio/sound_service.dart';
import 'package:algobot/state/settings_controller.dart';
import 'package:algobot/ui/widgets/board_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:algobot/data/levels.dart';
import 'package:algobot/data/progress_repository.dart';
import 'package:algobot/l10n/l10n.dart';
import 'package:algobot/models/age_group.dart';
import 'package:algobot/models/command.dart';
import 'package:algobot/state/progress_controller.dart';
import 'package:algobot/ui/screens/level_select_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_db.dart';
import 'qa_harness.dart';

Future<void> _startSkip(WidgetTester tester) async {
  await tapIt(tester, find.bySemanticsLabel(en.jokerSkip));
  await settle(tester, 300);
  await tester.tap(find.text(en.skipConfirmYes).last);
  await settle(tester, 200);
  expect(find.text(en.skippedLabel), findsOneWidget);
}

void main() {
  testWidgets('QA-1: Atlama animasyonu sırasında Çalıştır atlamayı bozar', (
    tester,
  ) async {
    final app = await qaSetUp(tester);
    final level = lvl(AgeGroup.ages8to12, 3);
    await openLevel(tester, level);
    await addAll(tester, [Command.forward]);
    await _startSkip(tester);

    await tester.tap(find.text(en.run), warnIfMissed: false);
    await settle(tester, 6000);

    // Beklenen: sonraki seviyeye geçilmiş, can düşmemiş olmalı.
    expect(find.text(en.skippedLabel), findsNothing, reason: '"Atlandı" kaldı');
    expect(
      find.text(en.levelTitle(lvl(AgeGroup.ages8to12, 4))),
      findsOneWidget,
      reason: 'Seviye 4\'e geçilmedi',
    );
    expect(app.sessions.sessionFor(level).lives, 3);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('QA-2: Atlama animasyonu sırasında palete dokunmak atlanan '
      'seviyeye program kaydeder', (tester) async {
    final app = await qaSetUp(tester);
    final level = lvl(AgeGroup.ages8to12, 3);
    await openLevel(tester, level);
    await _startSkip(tester);
    await tester.tap(card(en, Command.forward), warnIfMissed: false);
    await settle(tester, 3000);
    await flushDb(tester);
    expect(app.sessions.sessionFor(level).program, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('QA-3: Son can gidince panel açılmadan önceki kısa arada '
      '0 canla program çalıştırılabiliyor', (tester) async {
    final app = await qaSetUp(tester);
    final level = lvl(AgeGroup.ages8to12, 2);
    await openLevel(tester, level);
    await addAll(tester, crashProgram(level));
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text(en.run));
      await settle(tester, runtime(level));
      await tester.tap(find.text(en.tryAgain));
      await settle(tester, 300);
    }
    await tester.tap(find.text(en.run));
    var waited = 0;
    while (find.text(en.tryAgain).evaluate().isEmpty && waited < 10000) {
      await tester.pump(const Duration(milliseconds: 50));
      waited += 50;
    }
    expect(app.sessions.sessionFor(level).lives, 0);
    await tester.tap(find.text(en.tryAgain));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text(en.run), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(en.stop), findsNothing, reason: '0 canla çalıştı');
    await settle(tester, 2000);
    await tester.pumpWidget(const SizedBox());
  });

  for (final locale in const [Locale('tr'), Locale('en')]) {
    testWidgets('QA-4: Canı bitmiş seviye kartı 360dp + 1.3x yazıda taşar '
        '(${locale.languageCode})', (tester) async {
      final l = lookupAppLocalizations(locale);
      final errors = <String>[];
      final old = FlutterError.onError;
      FlutterError.onError = (d) =>
          errors.add(d.exceptionAsString().split('\n').first);
      try {
        final app = await qaSetUp(
          tester,
          locale: locale,
          textScale: 1.3,
          stars: {for (var i = 1; i <= 9; i++) (AgeGroup.ages8to12, i): 3},
        );
        final level = lvl(AgeGroup.ages8to12, 10);
        for (var i = 0; i < 3; i++) {
          app.sessions.loseLife(level);
        }
        await push(tester, const LevelSelectScreen());
        await tester.scrollUntilVisible(
          find.text(l.levelTitle(level)),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await settle(tester, 1200);
      } finally {
        FlutterError.onError = old;
      }
      expect(errors, isEmpty, reason: errors.join('\n'));
      await tester.pumpWidget(const SizedBox());
    });
  }

  test(
    'QA-5: İlerleme kaydı başarısız olunca yakalanmamış hata oluşur',
    () async {
      final db = await openTestDatabase();
      final progress = ProgressController(ProgressRepository(db), allLevelSets);
      await progress.load();
      await db.close();
      final uncaught = <Object>[];
      await runZonedGuarded(() async {
        progress.record(levelsFor(AgeGroup.ages8to12).first, 3);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }, (e, _) => uncaught.add(e));
      expect(uncaught, isEmpty, reason: uncaught.join('\n'));
      // Bellekte yine de kaydedilmiş olmalı.
      expect(progress.starsFor(levelsFor(AgeGroup.ages8to12).first), 3);
    },
  );

  testWidgets('QA-11: Yalnızca boş döngü çalıştırılmaz, can düşmez', (
    tester,
  ) async {
    final app = await qaSetUp(tester);
    final level = lvl(AgeGroup.ages8to12, 9); // Dünya 2, blok döngü
    await openLevel(tester, level);
    await tapIt(
      tester,
      find.bySemanticsLabel(en.paletteCardLabel(en.cmdRepeat)),
    );
    await settle(tester, 300);
    await tester.tap(find.text(en.run));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(en.emptyProgram), findsOneWidget);
    expect(find.text(en.stop), findsNothing);
    await settle(tester, 1500);
    expect(app.sessions.sessionFor(level).lives, 3);
    await tester.pumpWidget(const SizedBox());
  });

  test('QA-7: Açılış ses önbelleğini beklemez', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    SharedPreferences.setMockInitialValues({
      ProgressRepository.migratedKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    final hanging = Completer<void>();
    final sound = _HangingSound(SettingsController(prefs), hanging.future);
    final services = await loadAppServices(
      prefs,
      sound,
      timeout: const Duration(seconds: 5),
    ).timeout(const Duration(seconds: 4));
    expect(sound.preloadStarted, isTrue);
    // Gerçek (dosya) veritabanı kullanılıyor, bellek içi yedek değil.
    services.progress.record(levelsFor(AgeGroup.ages8to12).first, 1);
    hanging.complete();
  });

  test('QA-10: "Hakkında" metni değerlendirme butonuyla çelişmez', () {
    expect(
      tr.about(tr.aboutPrivacy('none')),
      contains('Oynamak için internet gerekmez'),
    );
    expect(
      en.about(en.aboutPrivacy('none')),
      contains('No internet needed to play'),
    );
  });

  testWidgets('QA-9: Geniş yatay ekranda tahta ve kontroller yan yana', (
    tester,
  ) async {
    await qaSetUp(tester, size: const Size(1280, 800));
    final level = lvl(AgeGroup.ages8to12, 4);
    await openLevel(tester, level);
    final board = tester.getRect(find.byType(BoardView));
    final run = tester.getRect(find.text(en.run));
    expect(run.left, greaterThan(board.right), reason: 'kontroller sağda');
    expect(board.height, greaterThan(500), reason: 'tahta yüksekliği');
    // Dikey tablette tek sütun kalır.
    await tester.pumpWidget(const SizedBox());
    await qaSetUp(tester, size: const Size(800, 1280));
    await openLevel(tester, level);
    expect(
      tester.getRect(find.text(en.run)).top,
      greaterThan(tester.getRect(find.byType(BoardView)).bottom),
    );
    await tester.pumpWidget(const SizedBox());
  });
}

class _HangingSound extends SoundService {
  _HangingSound(super.settings, this._wait);
  final Future<void> _wait;
  bool preloadStarted = false;

  @override
  Future<void> preload() {
    preloadStarted = true;
    return _wait;
  }
}
