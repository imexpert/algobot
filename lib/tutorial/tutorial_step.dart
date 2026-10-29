import 'package:flutter/foundation.dart';

import '../models/cell.dart';
import '../models/command.dart';
import '../models/intro_glyph.dart';

/// Eğitimde vurgulanabilecek ekran bölgeleri.
enum TargetKind {
  /// Tüm tahta.
  board,

  /// Oynanan karakterin karesi.
  character,

  /// Hedef karesi.
  goal,

  /// Büyük yön oku (karakterin karesi).
  arrow,

  /// Karakterin önündeki kare.
  frontCell,

  /// Toplanmamış toplanabilirler.
  collectible,

  /// Palette bir kart ([TutorialTarget.command]).
  paletteCard,

  /// Program şeridi.
  programStrip,

  /// Çalıştır düğmesi.
  runButton,

  /// Can göstergesi.
  hearts,

  /// Joker çubuğu.
  jokerBar,

  /// Bir mekaniğin kareleri ([TutorialTarget.cell]); kapı için anahtar da.
  mechanic,
}

@immutable
class TutorialTarget {
  const TutorialTarget(this.kind, {this.command, this.cell});

  const TutorialTarget.card(Command this.command)
    : kind = TargetKind.paletteCard,
      cell = null;

  const TutorialTarget.mechanic(CellType this.cell)
    : kind = TargetKind.mechanic,
      command = null;

  static const board = TutorialTarget(TargetKind.board);
  static const character = TutorialTarget(TargetKind.character);
  static const goal = TutorialTarget(TargetKind.goal);
  static const arrow = TutorialTarget(TargetKind.arrow);
  static const frontCell = TutorialTarget(TargetKind.frontCell);
  static const collectible = TutorialTarget(TargetKind.collectible);
  static const strip = TutorialTarget(TargetKind.programStrip);
  static const run = TutorialTarget(TargetKind.runButton);
  static const hearts = TutorialTarget(TargetKind.hearts);
  static const jokerBar = TutorialTarget(TargetKind.jokerBar);

  final TargetKind kind;
  final Command? command;
  final CellType? cell;
}

/// Adımın tamamlanması için beklenen eylem.
enum WaitKind {
  /// Balona dokunmak ("Devam ›").
  next,

  /// Belirli bir kartı şeride eklemek ([TutorialAction.command]).
  tapCard,

  /// Programı başarıyla çalıştırmak.
  runSucceeded,

  /// Şeritten bir kart silmek.
  removeCard,

  /// Son adım: "Başla" düğmesi.
  finish,
}

@immutable
class TutorialAction {
  const TutorialAction._(
    this.kind, {
    this.command,
    this.requireAll = false,
    this.freePlay = false,
    this.sequence,
  });

  const TutorialAction.next() : this._(WaitKind.next);
  const TutorialAction.tapCard(Command command)
    : this._(WaitKind.tapCard, command: command);
  const TutorialAction.removeCard() : this._(WaitKind.removeCard);
  const TutorialAction.finish() : this._(WaitKind.finish);

  /// [freePlay]: oyuncu kart ekleyip silebilir (yalnızca Çalıştır değil).
  /// [requireAll]: tüm toplanabilirler toplanmalı.
  /// [sequence]: yalnızca bu sıradaki kartlar eklenebilir (yanlışlar
  /// eklenmez; 5–7 rehberli adım).
  const TutorialAction.runSucceeded({
    bool requireAll = false,
    bool freePlay = false,
    List<Command>? sequence,
  }) : this._(
         WaitKind.runSucceeded,
         requireAll: requireAll,
         freePlay: freePlay,
         sequence: sequence,
       );

  final WaitKind kind;
  final Command? command;
  final bool requireAll;
  final bool freePlay;
  final List<Command>? sequence;
}

/// Eğitimin bir adımı. Yeni adım eklemek kod değil veri değişikliğidir:
/// senaryoya bir [TutorialStep] ve ARB dosyalarına metni eklenir.
@immutable
class TutorialStep {
  const TutorialStep({
    required this.id,
    required this.textKey,
    this.highlight = const [],
    this.waitFor = const TutorialAction.next(),
    this.boardId,
    this.showHand = false,
    this.glyphs = const [],
    this.showLives = false,
    this.showJokers = false,
    this.celebrate = false,
    this.stars = false,
    this.ghost = false,
    this.hintAfterFails,
  });

  final String id;

  /// ARB anahtarı (bkz. `tutorial_texts.dart`).
  final String textKey;

  /// Aydınlatılan bölgeler; boşsa ekran kararmaz.
  final List<TutorialTarget> highlight;
  final TutorialAction waitFor;

  /// Bu adımda tahtaya yüklenecek eğitim tahtası (null: öncekiyle aynı).
  final String? boardId;

  /// Hedefi işaret eden el animasyonu.
  final bool showHand;

  /// Balonda metnin yanında simgeler (5–7).
  final List<IntroGlyph> glyphs;

  /// Can göstergesi / joker çubuğu yalnızca bu adımda görünür.
  final bool showLives;
  final bool showJokers;

  /// Kutlama (büyük yıldız) animasyonu.
  final bool celebrate;

  /// Balonda 1-2-3 yıldız görseli.
  final bool stars;

  /// Mekanik tanıtımında hayalet karakter canlandırması.
  final bool ghost;

  /// Bu kadar başarısız denemeden sonra el doğru sıradaki kartı gösterir.
  final int? hintAfterFails;
}
