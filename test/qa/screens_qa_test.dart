// QA: tüm ekran ve panellerde taşma (overflow), çeviri anahtarı sızıntısı ve
// erişilebilirlik (dokunma hedefi, kontrast, etiket) taraması.
import 'package:algobot/characters/character_registry.dart';
import 'package:algobot/data/levels.dart';
import 'package:algobot/l10n/l10n.dart';
import 'package:algobot/models/age_group.dart';
import 'package:algobot/review/review_service.dart';
import 'package:algobot/ui/screens/character_select_screen.dart';
import 'package:algobot/ui/screens/game_screen.dart';
import 'package:algobot/ui/screens/level_select_screen.dart';
import 'package:algobot/ui/widgets/new_friend_dialog.dart';
import 'package:algobot/ui/widgets/review_prompt_dialog.dart';
import 'package:flutter/material.dart';
import 'package:algobot/models/age_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'qa_harness.dart';

/// Ekranda görünen tüm metinler.
Iterable<String> _texts(WidgetTester tester) sync* {
  for (final w in tester.widgetList(find.byType(Text))) {
    final t = w as Text;
    yield t.data ?? t.textSpan?.toPlainText() ?? '';
  }
  for (final w in tester.widgetList(find.byType(RichText))) {
    yield (w as RichText).text.toPlainText();
  }
}

/// ARB anahtarı gibi görünen (ör. `level812n05Title`) ya da çevrilmemiş
/// metinler.
final _keyLike = RegExp(r'^[a-z]+[0-9]*[A-Z][A-Za-z0-9]*$|^[a-z]+_[a-z0-9_]+$');

void _expectNoKeys(WidgetTester tester, String where) {
  final leaked = _texts(tester).where((t) => _keyLike.hasMatch(t.trim()));
  expect(leaked, isEmpty, reason: '$where: anahtar gibi görünen metin');
}

/// Taşma ve diğer çizim hatalarını ekran adıyla toplar.
class _Errors {
  final list = <String>[];
  String where = '';
  late final FlutterExceptionHandler? _old;

  void install() {
    _old = FlutterError.onError;
    FlutterError.onError = (details) {
      list.add('[$where] ${details.exceptionAsString().split('\n').first}');
    };
  }

  void restore() => FlutterError.onError = _old;
}

void main() {
  const sizes = {
    'telefon 360x640': Size(360, 640),
    'tablet 800x1280': Size(800, 1280),
  };

  for (final locale in const [Locale('tr'), Locale('en')]) {
    final l = lookupAppLocalizations(locale);
    for (final size in sizes.entries) {
      for (final scale in [1.0, 1.3]) {
        final name = '${locale.languageCode} · ${size.key} · ${scale}x';

        testWidgets('İlk açılış ekranları taşmasız: $name', (tester) async {
          final errors = _Errors()..install();
          try {
            await qaSetUp(
              tester,
              age: null,
              locale: locale,
              size: size.value,
              textScale: scale,
            );
            errors.where = 'yaş seçimi';
            await settle(tester, 600);
            _expectNoKeys(tester, errors.where);
            await tester.tap(find.text(l.ageShortOf(AgeGroup.ages5to7)).first);
            await settle(tester, 800);
            errors.where = 'arkadaş seçimi';
            _expectNoKeys(tester, errors.where);
            await tapIt(tester, find.text(l.start));
            await settle(tester, 800);
            errors.where = 'seviye seçimi (ilk açılış sonrası)';
            _expectNoKeys(tester, errors.where);
          } finally {
            errors.restore();
          }
          expect(errors.list, isEmpty, reason: errors.list.join('\n'));
          await tester.pumpWidget(const SizedBox());
        });

        testWidgets('Menü, seviye seçimi, karakterler, ebeveyn paneli ve '
            'diyaloglar taşmasız: $name', (tester) async {
          final errors = _Errors()..install();
          try {
            final app = await qaSetUp(
              tester,
              locale: locale,
              size: size.value,
              textScale: scale,
              stars: {for (var i = 1; i <= 9; i++) (AgeGroup.ages8to12, i): 3},
            );
            final level = lvl(AgeGroup.ages8to12, 10);
            errors.where = 'ana menü';
            _expectNoKeys(tester, errors.where);

            errors.where = 'seviye seçimi';
            await push(tester, const LevelSelectScreen());
            _expectNoKeys(tester, errors.where);
            // Sona kadar kaydır (Dünya 2), sonra geri sayımlı karta dön.
            final scrollable = find.byType(Scrollable).first;
            await tester.scrollUntilVisible(
              find.text(l.levelTitle(lvl(AgeGroup.ages8to12, 16))),
              300,
              scrollable: scrollable,
            );
            await settle(tester, 300);
            Navigator.of(tester.element(find.byType(LevelSelectScreen))).pop();
            await settle(tester, 600);
            // Canı bitmiş seviye kartındaki geri sayım taşması bilinen hata
            // (regression_qa_test.dart); panel burada oyun ekranından açılır.
            errors.where = 'canlar bitti paneli';
            for (var i = 0; i < 3; i++) {
              app.sessions.loseLife(level);
            }
            await push(tester, GameScreen(level: level));
            await settle(tester, 600);
            expect(find.text(l.outOfLivesTitle), findsOneWidget);
            _expectNoKeys(tester, errors.where);
            await tester.tap(find.text(l.mainMenu));
            await settle(tester, 800);

            errors.where = 'karakter seçimi';
            await push(tester, const CharacterSelectScreen());
            _expectNoKeys(tester, errors.where);
            Navigator.of(
              tester.element(find.byType(CharacterSelectScreen)),
            ).pop();
            await settle(tester, 600);

            errors.where = 'ebeveyn kapısı';
            await tester.tap(find.byTooltip(l.parent));
            await settle(tester, 500);
            _expectNoKeys(tester, errors.where);
            await answerGate(tester, l);
            errors.where = 'ayarlar paneli';
            _expectNoKeys(tester, errors.where);
            await tapIt(tester, find.text(l.resetProgress));
            await settle(tester, 300);
            errors.where = 'sıfırlama onayı';
            await tester.tap(find.text(l.cancel));
            await settle(tester, 300);
            await tapIt(tester, find.text(l.close).last);
            await settle(tester, 400);

            final ctx = tester.element(find.byType(Navigator).first);
            final character = CharacterRegistry.byId('pati');
            errors.where = 'yeni arkadaş diyaloğu';
            NewFriendDialog.show(Navigator.of(ctx).context, character).ignore();
            await settle(tester, 500);
            _expectNoKeys(tester, errors.where);
            await tester.tap(find.text(l.later));
            await settle(tester, 400);

            errors.where = 'değerlendirme kartı';
            ReviewPromptDialog.show(
              Navigator.of(ctx).context,
              character,
            ).ignore();
            await settle(tester, 500);
            _expectNoKeys(tester, errors.where);
            await tester.tap(find.text(l.later));
            await settle(tester, 400);
            expect(ReviewService.appStoreId, isNotEmpty);
          } finally {
            errors.restore();
          }
          expect(errors.list, isEmpty, reason: errors.list.join('\n'));
          await tester.pumpWidget(const SizedBox());
        });

        testWidgets('Seviye sonu paneli ve oyun içi paneller taşmasız: $name', (
          tester,
        ) async {
          final errors = _Errors()..install();
          try {
            for (final age in AgeGroup.values) {
              await qaSetUp(
                tester,
                age: age,
                locale: locale,
                size: size.value,
                textScale: scale,
              );
              final level = lvl(age, 1);
              errors.where = 'oyun ${age.name}';
              await openLevel(tester, level);
              final intro = find.text(l.levelIntro(level));
              if (intro.evaluate().isNotEmpty) await tester.tap(intro.first);
              await addAll(tester, level.referenceSolution, l);
              await tapIt(tester, find.text(l.run));
              await settle(tester, runtime(level));
              errors.where = 'seviye sonu paneli ${age.name}';
              expect(find.text(l.resultThreeStars), findsOneWidget);
              _expectNoKeys(tester, errors.where);
              await tester.tap(find.text(l.again));
              await settle(tester, 500);

              errors.where = 'başarısız paneli ${age.name}';
              await tapIt(tester, find.text(l.clear));
              await settle(tester, 300);
              await addAll(tester, crashProgram(level), l);
              await tapIt(tester, find.text(l.run));
              await settle(tester, runtime(level));
              expect(find.text(l.tryAgain), findsOneWidget);
              _expectNoKeys(tester, errors.where);

              errors.where = 'atlama onayı ${age.name}';
              await tapIt(tester, find.text(l.tryAgain));
              await settle(tester, 300);
              await tapIt(tester, find.bySemanticsLabel(l.jokerSkip));
              await settle(tester, 300);
              expect(find.text(l.skipConfirm), findsOneWidget);
              await tester.tap(find.text(l.cancel));
              await settle(tester, 300);
              await tester.pumpWidget(const SizedBox());
            }
          } finally {
            errors.restore();
          }
          expect(errors.list, isEmpty, reason: errors.list.join('\n'));
        });
      }
    }
  }

  // Android 16 (targetSdk 36): 600dp üstü ekranlarda dikey kilit yok
  // sayılır; tablet yatay da açılabilir.
  for (final locale in const [Locale('tr'), Locale('en')]) {
    testWidgets('Yatay tablet 1280x800: ana menü, seviye seçimi ve 48 '
        'seviye taşmasız (${locale.languageCode})', (tester) async {
      final l = lookupAppLocalizations(locale);
      final errors = _Errors()..install();
      try {
        for (final age in AgeGroup.values) {
          await qaSetUp(
            tester,
            age: age,
            locale: locale,
            size: const Size(1280, 800),
          );
          errors.where = 'ana menü ${age.name}';
          await settle(tester, 300);
          errors.where = 'seviye seçimi ${age.name}';
          await push(tester, const LevelSelectScreen());
          Navigator.of(tester.element(find.byType(LevelSelectScreen))).pop();
          await settle(tester, 500);
          for (final level in levelsFor(age)) {
            errors.where = 'oyun ${level.textKey}';
            await push(tester, GameScreen(level: level));
            final intro = find.text(l.levelIntro(level));
            if (intro.evaluate().isNotEmpty) await tester.tap(intro.first);
            final first = level.paletteCommands.first;
            for (var k = 0; k < level.maxSlots; k++) {
              await tapIt(tester, card(l, first));
            }
            await settle(tester, 300);
            Navigator.of(tester.element(find.byType(GameScreen))).pop();
            await settle(tester, 500);
          }
          await tester.pumpWidget(const SizedBox());
        }
      } finally {
        errors.restore();
      }
      expect(errors.list, isEmpty, reason: errors.list.toSet().join('\n'));
    });
  }

  group('Erişilebilirlik', () {
    Future<void> checkAll(WidgetTester tester, String where) async {
      for (final (guide, label) in [
        (androidTapTargetGuideline, 'Android 48dp'),
        (iOSTapTargetGuideline, 'iOS 44pt'),
        (labeledTapTargetGuideline, 'etiket'),
        (textContrastGuideline, 'kontrast'),
      ]) {
        await expectLater(
          tester,
          meetsGuideline(guide),
          reason: '$where · $label',
        );
      }
    }

    for (final locale in const [Locale('tr'), Locale('en')]) {
      final l = lookupAppLocalizations(locale);
      testWidgets('Ana menü (${locale.languageCode})', (tester) async {
        final handle = tester.ensureSemantics();
        await qaSetUp(tester, locale: locale);
        await settle(tester, 300);
        await checkAll(tester, 'ana menü');
        handle.dispose();
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('Seviye seçimi (${locale.languageCode})', (tester) async {
        final handle = tester.ensureSemantics();
        await qaSetUp(tester, locale: locale);
        await push(tester, const LevelSelectScreen());
        await checkAll(tester, 'seviye seçimi');
        handle.dispose();
        await tester.pumpWidget(const SizedBox());
      });

      for (final age in AgeGroup.values) {
        testWidgets('Oyun ekranı ${age.name} (${locale.languageCode})', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          await qaSetUp(tester, locale: locale, age: age);
          final level = lvl(age, 1);
          await openLevel(tester, level);
          final intro = find.text(l.levelIntro(level));
          if (intro.evaluate().isNotEmpty) await tester.tap(intro.first);
          await addAll(tester, level.referenceSolution.take(1).toList(), l);
          await settle(tester, 300);
          await checkAll(tester, 'oyun ${age.name}');
          handle.dispose();
          await tester.pumpWidget(const SizedBox());
        });
      }

      testWidgets('Ebeveyn paneli (${locale.languageCode})', (tester) async {
        final handle = tester.ensureSemantics();
        await qaSetUp(tester, locale: locale);
        await tester.tap(find.byTooltip(l.parent));
        await settle(tester, 500);
        await checkAll(tester, 'ebeveyn kapısı');
        await answerGate(tester, l);
        await checkAll(tester, 'ayarlar');
        handle.dispose();
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('Karakter seçimi (${locale.languageCode})', (tester) async {
        final handle = tester.ensureSemantics();
        await qaSetUp(tester, locale: locale);
        await push(tester, const CharacterSelectScreen());
        await checkAll(tester, 'karakter seçimi');
        handle.dispose();
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('Logo, kartlar ve jokerler anlamsal etikete sahip', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await qaSetUp(tester);
      expect(find.bySemanticsLabel(en.appTitle), findsWidgets);
      final level = lvl(AgeGroup.ages8to12, 1);
      await openLevel(tester, level);
      for (final c in level.paletteCommands) {
        expect(card(en, c), findsOneWidget, reason: c.name);
      }
      for (final j in [en.jokerSkip, en.jokerLife, en.jokerVideo]) {
        expect(find.bySemanticsLabel(RegExp(j)), findsWidgets, reason: j);
      }
      expect(find.byTooltip(en.back), findsOneWidget);
      handle.dispose();
      await tester.pumpWidget(const SizedBox());
    });
  });
}
