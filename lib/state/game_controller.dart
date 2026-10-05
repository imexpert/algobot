import 'dart:async';
import 'dart:math';

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../audio/sound_service.dart';
import '../characters/character_def.dart';
import '../characters/character_painter.dart';
import '../engine/run_result.dart';
import '../engine/simulator.dart';
import '../engine/star_calculator.dart';
import '../data/session_repository.dart';
import '../jokers/joker_type.dart';
import '../models/age_config.dart';
import '../models/age_group.dart';
import '../models/command.dart';
import '../models/direction.dart';
import '../models/level.dart';
import 'progress_controller.dart';

enum GamePhase { editing, running, crashed, stoppedShort, success }

/// Arayüzün yerelleştirerek gösterdiği kısa mesajlar.
enum GameMessage { emptyProgram, stripFull, lastLife, videoFailed }

/// Şeritteki bir kart. `id` animasyonlar ve sürükleme için kararlı anahtardır.
@immutable
class ProgramCard {
  const ProgramCard(this.id, this.command);
  final int id;
  final Command command;
}

enum _SegKind { turn, walk, slide, teleport, bump }

/// Bir adım animasyonunun zaman dilimi (ms, adım başından itibaren).
class _Seg {
  _Seg(this.kind, this.start, this.end, this.from, this.to);
  final _SegKind kind;
  final double start;
  final double end;
  final Point<int> from;
  final Point<int> to;
  double get duration => end - start;
}

/// Tahtada uçarak kaybolan nesne.
class FlyingItem {
  const FlyingItem(this.cell, this.progress, {this.isKey = false});
  final Point<int> cell;
  final double progress;
  final bool isKey;
}

/// Seviye oturumunun durumu: program şeridi, oynatma ve ipuçları.
/// Oyun mantığı [Simulator]'dadır; burada yalnızca sonuç adımları oynatılır.
class GameController extends ChangeNotifier {
  GameController({
    required this.level,
    required this.character,
    required TickerProvider vsync,
    required this._sound,
    required this._progress,
    required this._sessions,
  }) : _anim = AnimationController(vsync: vsync) {
    // Yarım kalmış program kaldığı yerden.
    for (final c in _sessions.sessionFor(level).program) {
      _program.add(ProgramCard(_nextCardId++, c));
    }
    _tutorialDone = _program.isNotEmpty;
    _resetPose();
  }

  final Level level;
  final CharacterDef character;
  final SoundService _sound;
  final ProgressController _progress;
  final AnimationController _anim;

  /// Canlar, jokerler ve program burada kalıcı olarak tutulur.
  final SessionRepository _sessions;
  final Stopwatch _clock = Stopwatch()..start();

  AgeSettings get ageSettings => level.ageGroup.settings;

  /// Adım animasyonu. Tahta bunu ve [now]'ı kullanarak her karede çizilir.
  Listenable get animation => _anim;

  /// Oturum saati (saniye); bekleme animasyonları için.
  double get now => _clock.elapsedMicroseconds / 1e6;

  bool _disposed = false;
  int _token = 0;

  // --- Program şeridi ---
  final List<ProgramCard> _program = [];
  int _nextCardId = 0;

  List<ProgramCard> get program => List.unmodifiable(_program);
  bool get isFull => _program.length >= level.maxSlots;

  // --- Oynatma durumu ---
  GamePhase _phase = GamePhase.editing;
  GamePhase get phase => _phase;
  bool get isLocked => _phase != GamePhase.editing;
  bool get isRunning => _phase == GamePhase.running;

  bool _fast = false;
  bool get fast => _fast;
  double get _speed => _fast ? 2 : 1;

  RunResult? _result;

  int? _currentIndex;
  int? get currentIndex => _currentIndex;

  int _lastStars = 0;
  int get lastStars => _lastStars;
  RunResult? get lastResult => _result;

  /// Başarıyla bitince ekranın sonuç panelini açması için çağrılır.
  VoidCallback? onSuccess;

  // --- Karakter pozu (işlenmiş adımlar) ---
  late Point<int> _pos;
  late int _quarterTurns; // kuzey = 0, saat yönünde; sürekli sayılır
  late Direction _dir;
  final Set<Point<int>> _collected = {};
  bool _hasKey = false;
  double? _doorsOpenAt;
  final Set<Point<int>> _trail = {};
  CharacterState _restState = CharacterState.idle;
  double _stateSince = 0;

  // --- Oynayan adım ---
  RunStep? _animStep;
  List<_Seg> _segs = const [];
  double _total = 1;
  int _turnDelta = 0;

  double get _elapsed => _anim.value * _total;

  _Seg? get _currentSeg {
    if (_segs.isEmpty) return null;
    final e = _elapsed;
    for (final s in _segs) {
      if (e <= s.end) return s;
    }
    return _segs.last;
  }

  double _segProgress(_Seg s) =>
      s.duration <= 0 ? 1 : ((_elapsed - s.start) / s.duration).clamp(0.0, 1.0);

  Set<Point<int>> get trail => _trail;

  /// Karakterin hücre birimindeki konumu (animasyon dahil).
  Offset get characterCell {
    final seg = _currentSeg;
    if (_animStep == null || seg == null) return _offset(_pos);
    final u = _segProgress(seg);
    return switch (seg.kind) {
      _SegKind.turn => _offset(seg.from),
      _SegKind.walk => Offset.lerp(
        _offset(seg.from),
        _offset(seg.to),
        Curves.easeInOut.transform(u),
      )!,
      _SegKind.slide => Offset.lerp(_offset(seg.from), _offset(seg.to), u)!,
      _SegKind.teleport => _offset(u < 0.5 ? seg.from : seg.to),
      _SegKind.bump => _offset(seg.from) + _bumpOffset(u),
    };
  }

  Offset _bumpOffset(double u) {
    final d = _animStep!.toDirection;
    final k = sin(pi * u) * 0.25;
    return Offset(d.dx * k, d.dy * k);
  }

  static Offset _offset(Point<int> p) => Offset(p.x.toDouble(), p.y.toDouble());

  /// Işınlanırken küçülüp büyüme.
  double get characterScale {
    final seg = _currentSeg;
    if (_animStep == null || seg?.kind != _SegKind.teleport) return 1;
    return (1 - 2 * _segProgress(seg!)).abs().clamp(0.15, 1.0);
  }

  /// Taban diskindeki okun yönü (çeyrek tur, kesirli olabilir).
  double get discQuarterTurns {
    final seg = _currentSeg;
    if (_animStep == null || seg == null) return _quarterTurns.toDouble();
    if (seg.kind == _SegKind.turn) {
      return _quarterTurns +
          _turnDelta * Curves.easeInOut.transform(_segProgress(seg));
    }
    return (_quarterTurns + _turnDelta).toDouble();
  }

  /// Karakterin önden görünüşte baktığı yön.
  Direction get facing {
    final seg = _currentSeg;
    if (_animStep == null || seg == null) return _dir;
    if (seg.kind == _SegKind.turn && _segProgress(seg) < 0.5) {
      return _animStep!.fromDirection;
    }
    return _animStep!.toDirection;
  }

  CharacterState get characterState {
    final seg = _currentSeg;
    if (_animStep == null || seg == null) return _restState;
    return seg.kind == _SegKind.turn
        ? CharacterState.turning
        : CharacterState.moving;
  }

  /// [CharacterPainter] için `t` değeri.
  double get characterTime {
    final seg = _currentSeg;
    if (_animStep != null && seg != null) return _segProgress(seg);
    return _restState == CharacterState.idle ? now : now - _stateSince;
  }

  /// Toplanmamış ve uçmakta olmayan toplanabilirler.
  Iterable<Point<int>> get remainingCollectibles =>
      level.collectibles.where((p) => !_collected.contains(p) && !_inFlight(p));

  Iterable<Point<int>> get remainingKeys =>
      level.keys.where((p) => !_hasKey && !_inFlight(p));

  bool _inFlight(Point<int> p) {
    final step = _animStep;
    if (step == null) return false;
    return step.collected.contains(p) || step.keyCollected == p;
  }

  /// Bu adımda toplanan nesneler: varış segmentinin ikinci yarısında
  /// küçülerek karaktere doğru uçar, sonra kaybolur.
  List<FlyingItem> get flyingItems {
    final step = _animStep;
    if (step == null || _segs.isEmpty) return const [];
    final items = <FlyingItem>[];
    void add(Point<int> p, bool isKey) {
      final seg = _segs.lastWhere((s) => s.to == p, orElse: () => _segs.last);
      final half = seg.start + seg.duration / 2;
      final u = ((_elapsed - half) / max(1, seg.duration / 2)).clamp(0.0, 1.0);
      items.add(FlyingItem(p, u, isKey: isKey));
    }

    for (final p in step.collected) {
      add(p, false);
    }
    final key = step.keyCollected;
    if (key != null) add(key, true);
    return items;
  }

  /// Kapıların açılma ilerlemesi (0 kapalı, 1 tamamen açık).
  double get doorsOpen {
    final at = _doorsOpenAt;
    if (at == null) return 0;
    return ((now - at) / 0.4).clamp(0.0, 1.0);
  }

  // --- Canlar (kalıcı, seviye bazında) ---
  int get livesMax => AgeSettings.maxLives;
  int get lives => _sessions.sessionFor(level).lives;
  bool get outOfLives => lives <= 0;

  /// Bir sonraki canın gelmesine kalan süre.
  Duration? get nextLifeIn => _sessions.nextLifeIn(level);

  /// Her can kaybında artar (kırılan kalp animasyonu için).
  int _lifeLostCount = 0;
  int get lifeLostCount => _lifeLostCount;

  /// Canlar bitince çağrılır (başarısızlık animasyonundan sonra).
  VoidCallback? onOutOfLives;

  /// Atlama animasyonu bitince çağrılır.
  VoidCallback? onSkipped;

  bool _skipping = false;
  bool get skipping => _skipping;

  // --- Kalıcı program kaydı (300 ms gecikmeli) ---
  Timer? _saveTimer;

  bool _introVisible = true;
  bool get introVisible => _introVisible;

  bool _tutorialDone = false;

  /// Parmak eğitimi: 5–7'de Seviye 1–2, 8–12'de Seviye 1.
  bool get showTutorial =>
      !_tutorialDone &&
      _phase == GamePhase.editing &&
      switch (level.ageGroup) {
        AgeGroup.ages5to7 => level.id <= 2,
        AgeGroup.ages8to12 => level.id == 1,
        AgeGroup.ages13plus => false,
      };

  // --- Geçici mesaj ve şerit uyarısı ---
  GameMessage? _message;
  GameMessage? get message => _message;
  Timer? _messageTimer;

  bool _stripWarning = false;
  bool get stripWarning => _stripWarning;
  Timer? _warningTimer;

  // ====================================================================
  // Program düzenleme
  // ====================================================================

  bool addCommand(Command command, {int? at}) {
    if (isLocked) return false;
    if (isFull) {
      _warnFull();
      return false;
    }
    final index = (at ?? _program.length).clamp(0, _program.length);
    _program.insert(index, ProgramCard(_nextCardId++, command));
    _tutorialDone = true;
    _programChanged();
    _sound.play(Sound.cardAdd);
    HapticFeedback.selectionClick();
    _notify();
    return true;
  }

  void removeCard(int id) {
    if (isLocked) return;
    final before = _program.length;
    _program.removeWhere((c) => c.id == id);
    if (_program.length == before) return;
    _programChanged();
    _sound.play(Sound.cardRemove);
    _notify();
  }

  void moveCard(int id, int toIndex) {
    if (isLocked) return;
    final from = _program.indexWhere((c) => c.id == id);
    if (from < 0) return;
    final card = _program.removeAt(from);
    final target = (toIndex > from ? toIndex - 1 : toIndex).clamp(
      0,
      _program.length,
    );
    _program.insert(target, card);
    if (target != from) {
      _programChanged();
      _sound.play(Sound.tap);
    }
    _notify();
  }

  void clear() {
    if (isLocked || _program.isEmpty) return;
    _program.clear();
    _programChanged();
    _sound.play(Sound.cardRemove);
    _notify();
  }

  void setFast(bool value) {
    _fast = value;
    _notify();
  }

  void dismissIntro() {
    if (!_introVisible) return;
    _introVisible = false;
    _notify();
  }

  // ====================================================================
  // Jokerler
  // ====================================================================

  bool isJokerUsed(JokerType type) =>
      _sessions.sessionFor(level).usedJokers.contains(type);

  /// Joker şu an kullanılabilir mi (çalışırken ve atlarken pasif; her
  /// joker seviye başına bir kez).
  bool canUseJoker(JokerType type) =>
      !isRunning && !_skipping && !isJokerUsed(type);

  /// Can jokeri: +1 can (başlangıç değerini aşabilir).
  bool useLifeJoker() {
    if (!canUseJoker(JokerType.life)) return false;
    _sessions.useLifeJoker(level);
    _sound.play(Sound.star);
    _notify();
    return true;
  }

  /// Seviyeyi atlar (Tur Atla ya da tamamlanan video). Onay arayüzde alınır.
  /// Seviye "atlandı" olur (0 yıldız), sonraki seviye açılır; oturum silinir
  /// ki geri dönüldüğünde tam haklarla başlansın. Karakter hedefe ışınlanır.
  Future<void> skipLevel(JokerType via) async {
    if (!via.skipsLevel || !canUseJoker(via)) return;
    _cancelPlayback();
    _flushProgram();
    _progress.markSkipped(level);
    _sessions.reset(level);
    _skipping = true;
    _phase = GamePhase.editing;
    _introVisible = false;
    _currentIndex = null;

    // Işınlanma: mevcut konumdan hedefe.
    _segs = [_Seg(_SegKind.teleport, 0, 600, _pos, level.goal)];
    _total = 600;
    _turnDelta = 0;
    _animStep = RunStep(
      index: 0,
      command: Command.forward,
      fromPosition: _pos,
      toPosition: level.goal,
      fromDirection: _dir,
      toDirection: _dir,
    );
    _sound.play(Sound.star);
    _notify();
    final token = _token;
    _anim.duration = const Duration(milliseconds: 600);
    try {
      await _anim.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    }
    if (token != _token || _disposed) return;
    _pos = level.goal;
    _animStep = null;
    _segs = const [];
    _setRest(CharacterState.win);
    _notify();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (token != _token || _disposed) return;
    onSkipped?.call();
  }

  /// Video tamamlanmadı: joker harcanmaz; yüklenemediyse kısa mesaj.
  void videoNotCompleted({required bool failed}) {
    if (failed) _showMessage(GameMessage.videoFailed, seconds: 3);
  }

  // ====================================================================
  // Çalıştırma
  // ====================================================================

  Future<void> run() async {
    if (isLocked) return;
    if (!_begin()) return;
    final token = _token;
    final steps = _result!.steps;
    for (var i = 0; i < steps.length; i++) {
      if (i > 0 && !await _pause(token)) return;
      if (!await _play(steps[i], token)) return;
    }
    _finish();
  }

  /// Çalışmayı durdurur, karakteri başa alır; program korunur.
  void stop() {
    _cancelPlayback();
    _toEditing();
  }

  /// Tekrar dene. (Başarıdan sonra oturum zaten sıfırlanmıştır: tam can.)
  void retry() {
    _cancelPlayback();
    _toEditing();
  }

  bool _begin() {
    if (_program.isEmpty) {
      _showMessage(GameMessage.emptyProgram);
      return false;
    }
    _cancelPlayback();
    _resetPose();
    _result = Simulator.run(level, _program.map((c) => c.command).toList());
    _phase = GamePhase.running;
    _introVisible = false;
    _clearMessage();
    _notify();
    return true;
  }

  /// Adımın animasyon segmentlerini kurar. Süreler yaşa göre, hızlı modda
  /// yarıya iner. Karakter görünüşü süreleri değiştirmez.
  void _buildSegments(RunStep step) {
    final move = ageSettings.moveMs / _speed;
    final turn = AgeSettings.turnMs / _speed;
    final segs = <_Seg>[];
    var t = 0.0;
    final from = step.fromPosition;

    _turnDelta = switch (step.command) {
      Command.turnRight => 1,
      Command.turnLeft => -1,
      _ => switch ((step.toDirection.index - step.fromDirection.index) % 4) {
        1 => 1,
        3 => -1,
        2 => 2,
        _ => 0,
      },
    };

    if (step.command.isTurn) {
      segs.add(_Seg(_SegKind.turn, 0, turn, from, from));
    } else {
      // Mutlak komut: önce döner; ek süre yok, hareket süresinin içinden.
      var first = move;
      if (_turnDelta != 0) {
        final turnPart = move * 0.35;
        segs.add(_Seg(_SegKind.turn, 0, turnPart, from, from));
        t = turnPart;
        first = move - turnPart;
      }
      if (step.crashed) {
        segs.add(_Seg(_SegKind.bump, t, t + first, from, from));
      } else {
        var prev = from;
        for (final (i, m) in step.motions.indexed) {
          final (kind, d) = switch (m.kind) {
            MotionKind.walk => (_SegKind.walk, i == 0 ? first : move),
            MotionKind.slide => (
              _SegKind.slide,
              AgeSettings.slideMsPerCell / _speed,
            ),
            MotionKind.teleport => (
              _SegKind.teleport,
              AgeSettings.teleportMs / _speed,
            ),
          };
          segs.add(_Seg(kind, t, t + d, prev, m.to));
          t += d;
          prev = m.to;
        }
      }
    }
    _segs = segs;
    _total = segs.isEmpty ? 1 : max(1, segs.last.end);
  }

  Future<bool> _play(RunStep step, int token) async {
    _currentIndex = step.index;
    _buildSegments(step);
    _anim.value = 0;
    _animStep = step;
    final stepStart = now;

    // Toplama sesi ve kapı açılışı, nesneye varış anına zamanlanır.
    final key = step.keyCollected;
    for (final p in [...step.collected, ?key]) {
      final seg = _segs.lastWhere((s) => s.to == p, orElse: () => _segs.last);
      _after(seg.end, token, () => _sound.play(Sound.battery));
      if (p == key) _doorsOpenAt = stepStart + seg.end / 1000;
    }
    if (step.crashed) {
      final bump = _segs.last;
      _after(bump.start + bump.duration / 2, token, () {
        _sound.play(Sound.crash);
        HapticFeedback.mediumImpact();
      });
    } else {
      _sound.play(step.command.isTurn ? Sound.turn : Sound.step);
      for (final s in _segs.where((s) => s.kind == _SegKind.teleport)) {
        _after(s.start, token, () => _sound.play(Sound.star));
      }
    }
    _notify();

    _anim.duration = Duration(milliseconds: _total.round());
    try {
      await _anim.forward(from: 0).orCancel;
    } on TickerCanceled {
      return false;
    }
    if (token != _token || _disposed) return false;

    // Adımı kalıcı hale getir.
    var prev = step.fromPosition;
    for (final m in step.motions) {
      if (m.kind != MotionKind.teleport) _trail.add(prev);
      prev = m.to;
    }
    _pos = step.toPosition;
    _dir = step.toDirection;
    _quarterTurns += _turnDelta;
    _collected.addAll(step.collected);
    if (key != null) _hasKey = true;
    if (step.crashed) _setRest(CharacterState.crash);
    _animStep = null;
    _segs = const [];
    _anim.value = 0;
    _notify();
    return true;
  }

  void _after(double ms, int token, VoidCallback action) {
    Future<void>.delayed(Duration(milliseconds: ms.round()), () {
      if (token == _token && !_disposed) action();
    });
  }

  Future<bool> _pause(int token) async {
    await Future<void>.delayed(
      Duration(milliseconds: (AgeSettings.pauseMs / _speed).round()),
    );
    return token == _token && !_disposed;
  }

  void _finish() {
    final result = _result!;
    switch (result.outcome) {
      case RunOutcome.success:
        _phase = GamePhase.success;
        _lastStars = StarCalculator.stars(level, result);
        _progress.record(level, _lastStars);
        // Çözüldü: canlar ve jokerler yenilenir (oturum silinir).
        _saveTimer?.cancel();
        _sessions.reset(level);
        _setRest(CharacterState.win);
        _sound.play(Sound.win);
        HapticFeedback.lightImpact();
      case RunOutcome.crashed:
        _phase = GamePhase.crashed;
        _loseLife();
      case RunOutcome.stoppedShort:
        _phase = GamePhase.stoppedShort;
        _loseLife();
    }
    _notify();
    if (_phase == GamePhase.success) {
      onSuccess?.call();
    } else if (outOfLives) {
      // Çarpma animasyonu görünsün, sonra panel.
      _after(900, _token, () => onOutOfLives?.call());
    }
  }

  /// Başarısız bitiş: 1 can düşer (Durdur ve Temizle düşürmez).
  void _loseLife() {
    if (lives <= 0) return;
    _flushProgram();
    _sessions.loseLife(level);
    _lifeLostCount++;
    HapticFeedback.mediumImpact();
    if (lives == 1) _showMessage(GameMessage.lastLife, seconds: 3);
  }

  void _programChanged() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 300), _flushProgram);
  }

  void _flushProgram() {
    if (_saveTimer == null) return;
    _saveTimer?.cancel();
    _saveTimer = null;
    _sessions.saveProgram(level, _program.map((c) => c.command).toList());
  }

  void _setRest(CharacterState state) {
    _restState = state;
    _stateSince = now;
  }

  void _cancelPlayback() {
    _token++;
    if (_anim.isAnimating) _anim.stop();
    _anim.value = 0;
    _animStep = null;
    _segs = const [];
  }

  void _toEditing() {
    _phase = GamePhase.editing;
    _currentIndex = null;
    _resetPose();
    _notify();
  }

  void _resetPose() {
    _pos = level.start;
    _dir = level.startDirection;
    _quarterTurns = level.startDirection.index;
    _collected.clear();
    _hasKey = false;
    _doorsOpenAt = null;
    _trail.clear();
    _animStep = null;
    _segs = const [];
    _setRest(CharacterState.idle);
  }

  void _warnFull() {
    _stripWarning = true;
    _showMessage(GameMessage.stripFull);
    HapticFeedback.selectionClick();
    _warningTimer?.cancel();
    _warningTimer = Timer(const Duration(milliseconds: 450), () {
      _stripWarning = false;
      _notify();
    });
  }

  void _showMessage(GameMessage message, {int seconds = 2}) {
    _message = message;
    _messageTimer?.cancel();
    _messageTimer = Timer(Duration(seconds: seconds), _clearMessage);
    _notify();
  }

  void _clearMessage() {
    if (_message == null) return;
    _message = null;
    _messageTimer?.cancel();
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _token++;
    _messageTimer?.cancel();
    _warningTimer?.cancel();
    // Bekleyen program kaydı kaybolmasın.
    if (!_skipping && _phase != GamePhase.success) _flushProgram();
    _saveTimer?.cancel();
    _anim.dispose();
    super.dispose();
  }
}
