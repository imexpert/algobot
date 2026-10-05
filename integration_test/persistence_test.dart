// Emülatörde kalıcılık kontrolü: iki ayrı süreçte çalıştırılır.
//   flutter test integration_test/persistence_test.dart --dart-define=PHASE=1
//   flutter test integration_test/persistence_test.dart --dart-define=PHASE=2
// 1. aşama bir can kaybeder ve şeride kart ekler; 2. aşama uygulama yeniden
// açıldığında canın ve programın korunduğunu doğrular.
import 'package:algobot/data/db/app_database.dart';
import 'package:algobot/data/db/level_session_dao.dart';
import 'package:algobot/data/levels.dart';
import 'package:algobot/l10n/l10n.dart';
import 'package:algobot/main.dart' as app;
import 'package:algobot/models/age_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const phase = int.fromEnvironment('PHASE', defaultValue: 1);
const age = 'ages8to12';

Future<void> _wait(WidgetTester tester, [int ms = 1500]) async {
  for (var t = 0; t < ms; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<LevelSessionRow?> _session() async {
  final db = await AppDatabase.open();
  final rows = await LevelSessionDao(db.db).all();
  return rows.where((r) => r.ageGroup == age && r.levelId == 1).firstOrNull;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Kalıcılık, aşama $phase', (tester) async {
    if (phase == 1) {
      // Temiz başlangıç: 8–12, Seviye 1 oturumu yok.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('age_group', age);
      final db = await AppDatabase.open();
      await LevelSessionDao(db.db).delete(age, 1);
    }

    app.main();
    await _wait(tester, 3000);
    final l = AppLocalizations.of(tester.element(find.byType(Scaffold).first));

    await tester.tap(find.text(l.play));
    await _wait(tester);
    await tester.tap(
      find.text(l.levelTitle(levelsFor(AgeGroup.ages8to12).first)),
    );
    await _wait(tester);

    if (phase == 1) {
      expect(find.bySemanticsLabel(l.livesLabel(3)), findsOneWidget);
      // Tek "İleri": pile gider, hedefe ulaşamaz → 1 can düşer.
      final forward = find.bySemanticsLabel(l.paletteCardLabel(l.cmdForward));
      await tester.tap(forward);
      await _wait(tester, 500);
      await tester.tap(find.text(l.run));
      await _wait(tester, 2500);
      expect(find.bySemanticsLabel(l.livesLabel(2)), findsOneWidget);
      await tester.tap(find.text(l.tryAgain));
      await _wait(tester, 500);
      // Programa bir kart daha: şeritte 2 kart, 300 ms sonra kaydedilir.
      await tester.tap(forward);
      await _wait(tester, 1000);
      expect(find.text(l.slotCounter(2, 4)), findsOneWidget);

      final row = await _session();
      expect(row, isNotNull);
      expect(row!.lives, 2);
      expect(row.program, 'forward,forward');
      debugPrint('AŞAMA 1: can=${row.lives} program=${row.program}');
    } else {
      // Yeni süreç: arayüz ve veritabanı kaldığı yerden.
      expect(find.bySemanticsLabel(l.livesLabel(2)), findsOneWidget);
      expect(find.text(l.slotCounter(2, 4)), findsOneWidget);
      final row = await _session();
      expect(row!.lives, 2);
      expect(row.program, 'forward,forward');
      debugPrint('AŞAMA 2: can=${row.lives} program=${row.program}');
    }
  });
}
