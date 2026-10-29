import 'dart:async';

import 'package:flutter/foundation.dart';

import '../engine/run_result.dart';
import '../engine/solver.dart';
import '../models/age_config.dart';
import '../models/command.dart';
import '../models/program.dart';
import '../state/game_controller.dart';
import 'tutorial_step.dart';

/// Eğitimin bu anda gösterdiği kısa yönlendirme (adım metninin yerine).
enum TutorialHint {
  /// "Bu sefer {kart} kartına dokun."
  wrongCard,

  /// "Az kaldı! Tekrar dene."
  tryAgain,

  /// "Hedefe ulaştın ama bir şeyi unuttun!"
  forgot,

  /// "Yanlış kartı silmek için ona dokun."
  removeWrong,
}

/// Eğitimin durumu: aktif adım, beklenen eylem ve ilerleme.
///
/// Oyun ekranının [GameController]'ına bağlanır ([attach]): oyuncunun
/// eylemlerini süzer (beklenmeyen kart eklenmez) ve çalıştırma sonuçlarına
/// göre ilerler. Tahta değişen adımlarda ekran yeni bir [GameController]
/// kurar ve yeniden bağlar.
class TutorialController extends ChangeNotifier {
  TutorialController({
    required this.steps,
    this.onFinished,
    this.retryDelay = const Duration(milliseconds: 1400),
    this.advanceDelay = const Duration(milliseconds: 800),
  }) : assert(steps.isNotEmpty);

  final List<TutorialStep> steps;

  /// Son adımda "Başla" (ya da "Anladım") seçilince.
  final VoidCallback? onFinished;

  /// Başarısız çalıştırmadan sonra karakterin başa dönme gecikmesi.
  final Duration retryDelay;

  /// Başarıdan sonra bir sonraki adıma geçme gecikmesi (kutlama görünsün).
  final Duration advanceDelay;

  int _index = 0;
  int get index => _index;
  TutorialStep get step => steps[_index];
  bool get isLast => _index == steps.length - 1;

  /// İlerleme çubuğu (0..1).
  double get progress => steps.length <= 1 ? 1 : _index / (steps.length - 1);

  /// Bu adıma kadar en son yüklenen tahta.
  String? get boardId {
    for (var i = _index; i >= 0; i--) {
      final id = steps[i].boardId;
      if (id != null) return id;
    }
    return null;
  }

  TutorialHint? _hint;
  TutorialHint? get hint => _hint;

  /// [TutorialHint.wrongCard] için doğru kart.
  Command? _hintCommand;
  Command? get hintCommand => _hintCommand;

  int _fails = 0;
  int get fails => _fails;

  /// Adım geçişi bekleniyor (başarı kutlaması sürerken).
  bool _advancing = false;

  GameController? _game;
  Timer? _timer;
  bool _disposed = false;

  /// Yeni (ya da aynı) oyun denetleyicisine bağlanır.
  void attach(GameController game) {
    _game = game
      ..actionGuard = _guard
      ..onAction = _onAction
      ..onRunFinished = _onRunFinished;
    _prepareGame();
  }

  void detach(GameController game) {
    if (!identical(_game, game)) return;
    game
      ..actionGuard = null
      ..onAction = null
      ..onRunFinished = null;
    _game = null;
  }

  // ------------------------------------------------------------------
  // Adım geçişleri
  // ------------------------------------------------------------------

  /// Balona dokunma ("Devam ›").
  void next() {
    if (step.waitFor.kind == WaitKind.next) _advance();
  }

  /// "Başla" / "Anladım".
  void finish() {
    if (step.waitFor.kind == WaitKind.finish) onFinished?.call();
  }

  void _advance() {
    if (isLast || _disposed) return;
    _timer?.cancel();
    _advancing = false;
    _index++;
    _hint = null;
    _hintCommand = null;
    _fails = 0;
    _prepareGame();
    _notify();
  }

  /// Kart ekleme/silme bekleyen adımda tahta düzenlenebilir olmalı.
  void _prepareGame() {
    final game = _game;
    if (game == null) return;
    final kind = step.waitFor.kind;
    final edits =
        kind == WaitKind.tapCard ||
        kind == WaitKind.removeCard ||
        kind == WaitKind.runSucceeded;
    if (edits && game.phase != GamePhase.editing && !game.isRunning) {
      game.retry();
    }
  }

  // ------------------------------------------------------------------
  // Eylem süzgeci
  // ------------------------------------------------------------------

  List<Command> get _programMoves => [
    for (final c in _game?.program ?? const <ProgramCard>[])
      if (c.instruction case Move(:final command)) command,
  ];

  bool _guard(GameAction action) {
    if (_advancing) return false;
    final wait = step.waitFor;
    switch (wait.kind) {
      case WaitKind.next || WaitKind.finish:
        return false;
      case WaitKind.tapCard:
        if (action.kind != GameActionKind.addCard) return false;
        if (action.command == wait.command) return true;
        _showHint(TutorialHint.wrongCard, wait.command);
        return false;
      case WaitKind.removeCard:
        return action.kind == GameActionKind.removeCard;
      case WaitKind.runSucceeded:
        if (action.kind == GameActionKind.run) return true;
        final seq = wait.sequence;
        if (seq != null) {
          if (action.kind == GameActionKind.removeCard ||
              action.kind == GameActionKind.clear) {
            return true;
          }
          if (action.kind != GameActionKind.addCard) return false;
          final moves = _programMoves;
          final expected = moves.length < seq.length ? seq[moves.length] : null;
          if (expected != null && action.command == expected) return true;
          if (expected != null) _showHint(TutorialHint.wrongCard, expected);
          return false;
        }
        if (!wait.freePlay) return false;
        return action.kind != GameActionKind.addRepeat;
    }
  }

  void _onAction(GameAction action) {
    final wait = step.waitFor;
    if (_hint == TutorialHint.wrongCard) {
      _hint = null;
      _hintCommand = null;
    }
    switch (action.kind) {
      case GameActionKind.addCard
          when wait.kind == WaitKind.tapCard && action.command == wait.command:
        _advance();
        return;
      case GameActionKind.removeCard when wait.kind == WaitKind.removeCard:
        _advance();
        return;
      case GameActionKind.run:
        _hint = null;
      default:
        break;
    }
    _notify();
  }

  void _onRunFinished(RunResult result) {
    final wait = step.waitFor;
    if (wait.kind != WaitKind.runSucceeded) return;
    final level = _game?.level;
    final allCollected =
        level == null || result.collectedCount >= level.collectibles.length;
    if (result.isSuccess && (!wait.requireAll || allCollected)) {
      _advancing = true;
      _timer?.cancel();
      _timer = Timer(advanceDelay, _advance);
      _notify();
      return;
    }
    _fails++;
    _hint = result.isSuccess ? TutorialHint.forgot : TutorialHint.tryAgain;
    _notify();
    // Can düşmez; karakter başa döner, program korunur.
    _timer?.cancel();
    _timer = Timer(retryDelay, () {
      if (_disposed) return;
      _game?.retry();
    });
  }

  void _showHint(TutorialHint hint, Command? command) {
    _hint = hint;
    _hintCommand = command;
    _notify();
  }

  // ------------------------------------------------------------------
  // El animasyonunun hedefi
  // ------------------------------------------------------------------

  /// Elin işaret ettiği hedef (null: el yok).
  TutorialTarget? get handTarget {
    final game = _game;
    if (game == null || game.isRunning || _advancing) return null;
    if (game.phase != GamePhase.editing) return null;
    final wait = step.waitFor;
    // Yanlış karta basılınca doğru kart.
    if (_hint == TutorialHint.wrongCard && _hintCommand != null) {
      return TutorialTarget.card(_hintCommand!);
    }
    final seq = wait.sequence;
    if (seq != null) return _nextInSequence(seq);
    final hintAfter = step.hintAfterFails;
    if (hintAfter != null && _fails >= hintAfter) return _nextCorrect();
    if (!step.showHand) return null;
    if (wait.kind == WaitKind.tapCard) {
      return TutorialTarget.card(wait.command!);
    }
    return step.highlight.isEmpty ? null : step.highlight.first;
  }

  TutorialTarget _nextInSequence(List<Command> seq) {
    final moves = _programMoves;
    if (!_isPrefix(moves, seq)) return TutorialTarget.strip;
    return moves.length < seq.length
        ? TutorialTarget.card(seq[moves.length])
        : TutorialTarget.run;
  }

  /// 2 başarısız denemeden sonra: doğru sıradaki kart, yanlış kart varsa
  /// şerit, program tamamsa Çalıştır.
  TutorialTarget? _nextCorrect() {
    final game = _game!;
    final solution = Solver.solve(
      game.level,
      commands: game.level.paletteCommands,
      requireAll: step.waitFor.requireAll,
    );
    if (solution == null) return null;
    return _nextInSequence(solution.solution);
  }

  static bool _isPrefix(List<Command> a, List<Command> b) {
    if (a.length > b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Yanlış kart şeritteyse silmeyi hatırlatır (2 denemeden sonra).
  bool get suggestsRemove =>
      (step.hintAfterFails != null && _fails >= step.hintAfterFails!) &&
      handTarget?.kind == TargetKind.programStrip;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    final game = _game;
    if (game != null) detach(game);
    super.dispose();
  }
}
