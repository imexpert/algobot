// Eğitimi bir oyuncu gibi adım adım geçen test yardımcıları.
import 'package:algobot/engine/solver.dart';
import 'package:algobot/l10n/l10n.dart';
import 'package:algobot/models/age_config.dart';
import 'package:algobot/models/command.dart';
import 'package:algobot/models/program.dart';
import 'package:algobot/state/game_controller.dart';
import 'package:algobot/tutorial/tutorial_controller.dart';
import 'package:algobot/tutorial/tutorial_step.dart';
import 'package:algobot/ui/tutorial/coach_bubble.dart';
import 'package:algobot/ui/tutorial/tutorial_screen.dart';
import 'package:algobot/ui/widgets/command_card.dart';
import 'package:algobot/ui/widgets/program_strip.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpMs(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

TutorialOverlay overlayOf(WidgetTester tester) =>
    tester.widget<TutorialOverlay>(find.byType(TutorialOverlay).first);

TutorialController tutorialOf(WidgetTester tester) =>
    overlayOf(tester).tutorial;

GameController gameOf(WidgetTester tester) => overlayOf(tester).game;

Finder paletteCard(AppLocalizations l, Command c) =>
    find.bySemanticsLabel(l.paletteCardLabel(l.commandShort(c)));

Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f, warnIfMissed: false);
}

List<Command> programMoves(GameController game) => [
  for (final c in game.program)
    if (c.instruction case Move(:final command)) command,
];

/// Adımın beklediği programı kurar (gerekirse temizler) ve çalıştırır.
Future<void> solveAndRun(WidgetTester tester, AppLocalizations l) async {
  final t = tutorialOf(tester);
  final game = gameOf(tester);
  final wait = t.step.waitFor;
  final want =
      wait.sequence ??
      Solver.solve(
        game.level,
        commands: game.level.paletteCommands,
        requireAll: wait.requireAll,
      )!.solution;
  if (!_same(programMoves(game), want)) {
    if (game.program.isNotEmpty) {
      await tapVisible(tester, find.text(l.clear));
      await pumpMs(tester, 300);
    }
    for (final c in want) {
      await tapVisible(tester, paletteCard(l, c));
      await pumpMs(tester, 150);
    }
  }
  await tapVisible(tester, find.text(l.run));
  final before = t.index;
  for (var ms = 0; ms < 20000 && t.index == before; ms += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await pumpMs(tester, 300);
}

bool _same(List<Command> a, List<Command> b) =>
    a.length == b.length &&
    [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((x) => x);

/// Etkin adımı beklenen eylemle tamamlar.
Future<void> completeStep(WidgetTester tester, AppLocalizations l) async {
  final t = tutorialOf(tester);
  final wait = t.step.waitFor;
  switch (wait.kind) {
    case WaitKind.next:
      await tester.tap(find.byType(CoachBubble).first);
    case WaitKind.tapCard:
      await tapVisible(tester, paletteCard(l, wait.command!));
    case WaitKind.removeCard:
      final card = find.descendant(
        of: find.byType(ProgramStrip),
        matching: find.byType(CommandCard),
      );
      await tapVisible(tester, card.first);
      await pumpMs(tester, 400);
    case WaitKind.runSucceeded:
      await solveAndRun(tester, l);
    case WaitKind.finish:
      final label = find.text(l.tutStart).evaluate().isNotEmpty
          ? find.text(l.tutStart)
          : find.text(l.tutGotIt);
      await tapVisible(tester, label.last);
  }
  await pumpMs(tester, 700);
}

/// Eğitimi sonuna kadar geçer. [onStep]: her adım başında çağrılır
/// (taşma, balon konumu vb. kontroller için).
Future<int> completeTutorial(
  WidgetTester tester,
  AppLocalizations l, {
  Future<void> Function(TutorialStep step)? onStep,
}) async {
  var steps = 0;
  while (find.byType(TutorialOverlay).evaluate().isNotEmpty && steps < 60) {
    final t = tutorialOf(tester);
    await onStep?.call(t.step);
    final last = t.isLast;
    final index = t.index;
    await completeStep(tester, l);
    steps++;
    if (last) break;
    expect(
      find.byType(TutorialOverlay).evaluate().isEmpty ||
          tutorialOf(tester).index != index,
      isTrue,
      reason: 'Adım ilerlemedi: ${t.step.id}',
    );
  }
  await pumpMs(tester, 800);
  return steps;
}
