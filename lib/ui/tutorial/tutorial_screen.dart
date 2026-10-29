import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio/sound_service.dart';
import '../../characters/character_registry.dart';
import '../../core/colors.dart';
import '../../data/session_repository.dart';
import '../../l10n/l10n.dart';
import '../../models/age_config.dart';
import '../../models/age_group.dart';
import '../../models/cell.dart';
import '../../rewards/rewarded_video_service.dart';
import '../../state/game_controller.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../../tutorial/ghost_demo.dart';
import '../../tutorial/mechanic_intro.dart';
import '../../tutorial/tutorial_boards.dart';
import '../../tutorial/tutorial_controller.dart';
import '../../tutorial/tutorial_scripts.dart';
import '../../tutorial/tutorial_step.dart';
import '../screens/level_select_screen.dart';
import '../widgets/board_view.dart';
import '../widgets/game_layout.dart';
import '../widgets/lives_indicator.dart';
import 'coach_bubble.dart';
import 'pointing_hand.dart';
import 'spotlight_overlay.dart';

/// "Oyna": yaş grubunun eğitimi hiç görülmediyse önce eğitim açılır,
/// bitince seviye seçimine geçilir.
Future<void> openPlay(BuildContext context) async {
  final settings = context.read<SettingsController>();
  final age = settings.ageGroup;
  final nav = Navigator.of(context);
  if (settings.tutorialDone(age.settings.commandFamily)) {
    await nav.push(
      MaterialPageRoute<void>(builder: (_) => const LevelSelectScreen()),
    );
    return;
  }
  await nav.push(
    MaterialPageRoute<void>(
      builder: (context) => TutorialScreen(
        age: age,
        onDone: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const LevelSelectScreen()),
        ),
      ),
    ),
  );
}

/// Eğitimi açar; bitince ya da atlanınca geri döner ("Nasıl oynanır?", "?").
Future<void> openTutorial(BuildContext context, AgeGroup age) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            TutorialScreen(age: age, onDone: () => Navigator.of(context).pop()),
      ),
    );

/// Etkileşimli eğitim: oyun ekranının bileşenlerini "eğitim modunda"
/// kullanır. Can düşmez, joker yok, yıldız ve ilerleme kaydedilmez.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key, required this.age, required this.onDone});

  /// Oyuncunun yaş grubu: komut ailesi (eğitim türü) ve palet buna göre.
  final AgeGroup age;

  /// Eğitim tamamlanınca ya da atlanınca.
  final VoidCallback onDone;

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen>
    with TickerProviderStateMixin {
  late final CommandFamily _family = widget.age.settings.commandFamily;
  late final TutorialController _tutorial = TutorialController(
    steps: tutorialFor(_family),
    onFinished: () => _finish(TutorialStatus.completed),
  )..addListener(_onTutorialChanged);

  final _livesKey = GlobalKey();
  GameKeys _keys = GameKeys();
  GameController? _game;
  String? _boardId;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _loadBoard();
  }

  void _onTutorialChanged() {
    if (_tutorial.boardId != _boardId) {
      setState(_loadBoard);
    }
  }

  /// Tahta değişen adımda yeni bir eğitim modu oyun denetleyicisi kurulur.
  void _loadBoard() {
    final id = _tutorial.boardId!;
    final old = _game;
    if (old != null) {
      _tutorial.detach(old);
      // Bir sonraki kareden sonra bırak (eski çizim hâlâ bağlı olabilir).
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
    _boardId = id;
    _keys = GameKeys();
    final game = GameController(
      level: tutorialLevel(id, widget.age),
      character: CharacterRegistry.byId(
        context.read<SettingsController>().characterId,
      ),
      vsync: this,
      sound: context.read<SoundService>(),
      progress: context.read<ProgressController>(),
      sessions: context.read<SessionRepository>(),
      tutorialMode: true,
    );
    _tutorial.attach(game);
    _game = game;
  }

  Future<void> _finish(TutorialStatus status) async {
    if (_done) return;
    _done = true;
    final settings = context.read<SettingsController>();
    // Önceden tamamlanmış eğitim tekrar izlenip atlanırsa "tamamlandı" kalır.
    if (status == TutorialStatus.completed || !settings.tutorialDone(_family)) {
      await settings.setTutorialStatus(_family, status);
    }
    if (mounted) widget.onDone();
  }

  Future<void> _confirmSkip() async {
    final l = context.l10n;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        content: Text(
          l.tutSkipConfirm,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l.cancel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l.tutSkip,
              style: const TextStyle(
                color: AppColors.primaryButton,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (yes == true && mounted) await _finish(TutorialStatus.skipped);
  }

  @override
  void dispose() {
    _tutorial.removeListener(_onTutorialChanged);
    _tutorial.dispose();
    _game?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = _game!;
    final l = context.l10n;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmSkip();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: GameLayout.isWide(MediaQuery.sizeOf(context))
                    ? 1200
                    : 600,
              ),
              child: ListenableBuilder(
                listenable: Listenable.merge([game, _tutorial]),
                builder: (context, _) {
                  final step = _tutorial.step;
                  return Stack(
                    children: [
                      Column(
                        children: [
                          SizedBox(
                            height: 56,
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    l.tutTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                // Canlar yalnızca tanıtıldıkları adımda.
                                if (step.showLives)
                                  KeyedSubtree(
                                    key: _livesKey,
                                    child: LivesIndicator(
                                      left: game.livesMax,
                                      max: game.livesMax,
                                      lostCount: 0,
                                      alignment: Alignment.centerRight,
                                    ),
                                  ),
                                // "Atla" düğmesinin yeri (düğme katmanın üstünde).
                                const SizedBox(width: 96),
                              ],
                            ),
                          ),
                          Expanded(
                            child: GameLayout(
                              game: game,
                              keys: _keys,
                              showJokers: step.showJokers,
                              showFailurePanel: false,
                              showIntro: false,
                              videoAvailable: context
                                  .read<RewardedVideoService>()
                                  .isAvailable,
                            ),
                          ),
                        ],
                      ),
                      Positioned.fill(
                        child: TutorialOverlay(
                          tutorial: _tutorial,
                          game: game,
                          keys: _keys,
                          livesKey: _livesKey,
                          large: _family == CommandFamily.absolute,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 8,
                        child: TextButton.icon(
                          onPressed: _confirmSkip,
                          icon: const Icon(
                            Icons.skip_next,
                            color: AppColors.textPrimary,
                          ),
                          label: Text(
                            l.tutSkip,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            backgroundColor: AppColors.panel,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Eğitim katmanı: karartma ve açıklıklar, ilerleme çubuğu, Bip'in balonu,
/// işaret eden el ve kutlama. Eğitim ekranı ve 13+ mekanik tanıtımları
/// (oyun ekranının üstünde) aynı katmanı kullanır.
class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({
    super.key,
    required this.tutorial,
    required this.game,
    required this.keys,
    this.livesKey,
    this.large = false,
    this.finishLabel,
  });

  final TutorialController tutorial;
  final GameController game;
  final GameKeys keys;
  final GlobalKey? livesKey;

  /// 5–7: büyük metin.
  final bool large;

  /// Son adımın düğmesi (varsayılan "Başla").
  final String? finishLabel;

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _ghostPlayedFor = -1;

  /// Balonun son ölçülen yüksekliği (yerleşim için; ilk karede tahmin).
  final _bubbleKey = GlobalKey();
  double _bubbleHeight = 150;

  void _measureBubble() {
    final box = _bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final h = box.size.height;
    if ((h - _bubbleHeight).abs() > 1 && mounted) {
      setState(() => _bubbleHeight = h);
    }
  }

  /// Balonun üst kenarı (katmanın yerel koordinatlarında): aydınlatılan
  /// hedeflerle hiç çakışmayan (yoksa en az çakışan) konum; eşitlikte
  /// tercih edilen yere (hedef üstteyse alt, alttaysa üst) en yakını.
  /// Balon hiçbir konumda sığmadıysa bu adımda simgesiz (kısa) gösterilir.
  int _compactFor = -1;

  (double, double) _bubbleTop(List<Rect> holes, Offset? anchor, Size area) {
    const top = 60.0, bottom = 16.0, step = 4.0;
    final h = _bubbleHeight;
    final maxY = max(top, area.height - bottom - h);
    final preferTop = anchor != null && anchor.dy > area.height / 2;
    final preferred = preferTop ? top : maxY;
    var best = preferred;
    var bestCost = double.infinity;
    for (var y = top; y <= maxY + 0.1; y += step) {
      final r = Rect.fromLTWH(0, y, area.width, h);
      var cost = 0.0;
      for (final hole in holes) {
        final i = r.intersect(hole.inflate(8));
        if (i.width > 0 && i.height > 0) cost += i.width * i.height;
      }
      final better =
          cost < bestCost - 1 ||
          ((cost - bestCost).abs() <= 1 &&
              (y - preferred).abs() < (best - preferred).abs());
      if (better) {
        best = y;
        bestCost = cost;
      }
    }
    return (best, bestCost);
  }

  TutorialController get _t => widget.tutorial;
  GameController get _game => widget.game;

  @override
  void initState() {
    super.initState();
    _t.addListener(_maybeGhost);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeGhost();
      // İlk karede hedeflerin konumu henüz yok; yerleşimden sonra yenile.
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(TutorialOverlay old) {
    super.didUpdateWidget(old);
    if (!identical(old.tutorial, widget.tutorial)) {
      old.tutorial.removeListener(_maybeGhost);
      widget.tutorial.addListener(_maybeGhost);
    }
    // Tahta ya da adım değişince konumlar bir sonraki karede belli olur.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t.removeListener(_maybeGhost);
    super.dispose();
  }

  /// Mekanik tanıtımı: hayalet adımında canlandırma bir kez oynar.
  void _maybeGhost() {
    if (!_t.step.ghost || _ghostPlayedFor == _t.index) return;
    _ghostPlayedFor = _t.index;
    final mechanic = mechanicIntroFor(_game.level);
    if (mechanic == null) return;
    _game.playGhost(GhostDemo.forMechanic(_game.level, mechanic));
  }

  Rect? _rectOf(GlobalKey? key) {
    final box = key?.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Rect? _cell(Point<int> p) {
    final level = _game.level;
    return boardCellRect(widget.keys.board, level.width, level.height, p);
  }

  /// Bir hedefin genel ekran koordinatlarındaki dikdörtgenleri.
  List<Rect> _rects(TutorialTarget target) {
    final level = _game.level;
    final keys = widget.keys;
    Point<int> charCell() {
      final c = _game.characterCell;
      return Point(c.dx.round(), c.dy.round());
    }

    return switch (target.kind) {
      TargetKind.board => [?_rectOf(keys.board)],
      TargetKind.character || TargetKind.arrow => [?_cell(charCell())],
      TargetKind.goal => [?_cell(level.goal)],
      TargetKind.frontCell => [
        if (_game.frontCell case (final p, _) when level.isInside(p)) ?_cell(p),
      ],
      TargetKind.collectible => [
        for (final p in _game.remainingCollectibles) ?_cell(p),
      ],
      TargetKind.paletteCard => [?_rectOf(keys.palette[target.command])],
      TargetKind.programStrip => [?_rectOf(keys.strip)],
      TargetKind.runButton => [?_rectOf(keys.run)],
      TargetKind.hearts => [?_rectOf(widget.livesKey)],
      TargetKind.jokerBar => [?_rectOf(keys.jokerBar)],
      TargetKind.mechanic => [
        for (var y = 0; y < level.height; y++)
          for (var x = 0; x < level.width; x++)
            if (_isMechanic(level.cellAt(Point(x, y)), target.cell!))
              ?_cell(Point(x, y)),
        if (target.cell == CellType.door)
          for (final k in _game.remainingKeys) ?_cell(k),
      ],
    };
  }

  static bool _isMechanic(CellType cell, CellType target) =>
      target == CellType.portalA || target == CellType.portalB
      ? cell == CellType.portalA || cell == CellType.portalB
      : cell == target;

  /// Aydınlatılan açıklıklar. Serbest çözüm adımlarında kontroller (palet,
  /// şerit, Çalıştır) de açık kalır.
  List<Rect> _holes() {
    final step = _t.step;
    final rects = [for (final t in step.highlight) ..._rects(t)];
    final wait = step.waitFor;
    if (wait.kind == WaitKind.runSucceeded &&
        (wait.freePlay || wait.sequence != null)) {
      for (final k in widget.keys.palette.values) {
        final r = _rectOf(k);
        if (r != null) rects.add(r);
      }
      rects.addAll([?_rectOf(widget.keys.strip), ?_rectOf(widget.keys.run)]);
    }
    return rects;
  }

  Offset? _handPoint() {
    final target = _t.handTarget;
    if (target == null) return null;
    final rects = _rects(target);
    return rects.isEmpty ? null : rects.first.center;
  }

  String _text(BuildContext context) {
    final l = context.l10n;
    final hint = _t.hint;
    if (hint != null) {
      return switch (hint) {
        TutorialHint.wrongCard => l.tutWrongCard(
          l.commandShort(_t.hintCommand!),
        ),
        TutorialHint.tryAgain => l.tutTryAgain,
        TutorialHint.forgot => l.tutForgot,
        TutorialHint.removeWrong => l.tutRemoveWrong,
      };
    }
    if (_t.suggestsRemove) return l.tutRemoveWrong;
    return l.tutorialText(
      _t.step.textKey,
      characterId: _game.character.id,
      video: context.read<RewardedVideoService>().isAvailable,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_t, _game]),
      builder: (context, _) {
        final step = _t.step;
        final running = _game.isRunning;
        final holes = _holes();
        final dim = step.highlight.isNotEmpty && !running;
        // Balon hedefi kapatmasın: hedeflerle çakışmayan dikey konum.
        final screen = MediaQuery.sizeOf(context);
        final me = context.findRenderObject() as RenderBox?;
        final area = me != null && me.hasSize ? me.size : screen;
        Rect local(Rect r) => me == null || !me.hasSize
            ? r
            : Rect.fromPoints(
                me.globalToLocal(r.topLeft),
                me.globalToLocal(r.bottomRight),
              );
        final hand = _handPoint();
        final localHoles = [
          for (final r in holes) local(r),
          if (hand != null) local(Rect.fromCircle(center: hand, radius: 28)),
        ];
        final focus = localHoles.isEmpty
            ? null
            : localHoles.reduce((a, b) => a.expandToInclude(b)).center;
        final (bubbleTop, overlap) = _bubbleTop(localHoles, focus, area);
        final compact = _compactFor == _t.index;
        if (overlap > 0 && !compact && step.glyphs.isNotEmpty) {
          final index = _t.index;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _compactFor = index);
          });
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => _measureBubble());
        final wait = step.waitFor;
        final l = context.l10n;
        return Stack(
          children: [
            Positioned.fill(
              child: SpotlightOverlay(
                holes: _holes,
                dim: dim,
                // Balona ya da "Başla"ya dokunarak ilerlenen adımlarda
                // oyun alanı dokunmaya kapalı.
                block:
                    wait.kind == WaitKind.next || wait.kind == WaitKind.finish,
              ),
            ),
            // İnce ilerleme çubuğu (adım sayısı yazıyla değil, çubukla).
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Semantics(
                label: l.tutProgressLabel,
                value: '${(_t.progress * 100).round()}%',
                child: LinearProgressIndicator(
                  value: _t.progress,
                  minHeight: 4,
                  color: AppColors.activeHighlight,
                  backgroundColor: AppColors.panel,
                ),
              ),
            ),
            if (step.celebrate && !running)
              Positioned.fill(child: _Celebration(key: ValueKey(_t.index))),
            if (hand != null && !running)
              Positioned.fill(child: PointingHand(target: _handPoint)),
            if (!running || _t.hint != null)
              Positioned(
                left: 12,
                right: 12,
                top: bubbleTop,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: screen.height * 0.4),
                  child: SingleChildScrollView(
                    key: _bubbleKey,
                    child: CoachBubble(
                      key: ValueKey('bubble${_t.index}'),
                      text: _text(context),
                      glyphs: compact ? const [] : step.glyphs,
                      collectible: _game.character.collectible,
                      large: widget.large,
                      stars: step.stars,
                      onNext: wait.kind == WaitKind.next ? _t.next : null,
                      actionLabel: wait.kind == WaitKind.finish
                          ? (widget.finishLabel ?? l.tutStart)
                          : null,
                      onAction: wait.kind == WaitKind.finish ? _t.finish : null,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Büyük yıldızın büyüyüp parladığı kısa kutlama.
class _Celebration extends StatefulWidget {
  const _Celebration({super.key});

  @override
  State<_Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<_Celebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final t = _anim.value;
          final scale = Curves.elasticOut.transform(t);
          return Align(
            alignment: const Alignment(0, -0.45),
            child: Opacity(
              opacity: t < 0.15 ? t / 0.15 : 1,
              child: Transform.rotate(
                angle: (1 - t) * pi / 3,
                child: Transform.scale(
                  scale: scale,
                  child: const Icon(
                    Icons.star_rounded,
                    size: 120,
                    color: AppColors.starEarned,
                    shadows: [Shadow(color: Color(0x88000000), blurRadius: 12)],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
