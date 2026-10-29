import 'age_group.dart';
import 'command.dart';
import 'level.dart';

/// Yaşa göre tüm sayısal ayarlar tek yerde. Joker ayarları
/// `lib/jokers/joker_config.dart` içindedir.
/// Komut paletinde hangi kartların gösterileceği.
enum PaletteMode {
  /// Seviyenin `availableCommands` listesi (5–7: adım adım tanıtım).
  perLevel,

  /// Yaş grubunun tüm komutları, her seviyede aynı sırayla.
  fullSet,
}

/// Dünya 2 döngü kartının biçimi.
enum LoopStyle {
  /// 5–7: tek kartı çarpanla tekrarlama (→ ×3).
  multiplier,

  /// 8–12 ve 13+: birden çok kartı saran Tekrarla [ … ] bloğu.
  block,
}

/// Yaşa göre oyun ve arayüz ayarları.
class AgeSettings {
  const AgeSettings({
    required this.commandFamily,
    required this.cardSize,
    required this.maxCell,
    required this.paletteMode,
    required this.commandSet,
    required this.loopStyle,
    required this.moveMs,
  });

  final CommandFamily commandFamily;
  final double cardSize;
  final double maxCell;

  final PaletteMode paletteMode;

  /// Yaş grubunun tam komut kümesi, palet sırasıyla.
  final List<Command> commandSet;

  final LoopStyle loopStyle;
  final int moveMs;

  /// Seviye başına başlangıç canı; tüm yaş gruplarında aynı. Can jokeri
  /// bu değeri aşabilir (ör. 4), zamanla dolum ise burada durur.
  static const maxLives = 3;

  /// Can başlangıç değerinin altındayken bu sürede 1 can geri gelir.
  static const lifeRefill = Duration(minutes: 10);

  static const turnMs = 250;
  static const slideMsPerCell = 150;
  static const teleportMs = 200;
  static const pauseMs = 100;
}

extension AgeGroupSettings on AgeGroup {
  AgeSettings get settings => switch (this) {
    AgeGroup.ages5to7 => const AgeSettings(
      commandFamily: CommandFamily.absolute,
      cardSize: 64,
      maxCell: 88,
      paletteMode: PaletteMode.perLevel,
      loopStyle: LoopStyle.multiplier,
      commandSet: [
        Command.moveUp,
        Command.moveDown,
        Command.moveLeft,
        Command.moveRight,
      ],
      moveMs: 500,
    ),
    AgeGroup.ages8to12 => const AgeSettings(
      commandFamily: CommandFamily.relative,
      cardSize: 56,
      maxCell: 72,
      paletteMode: PaletteMode.fullSet,
      loopStyle: LoopStyle.block,
      commandSet: [Command.forward, Command.turnRight, Command.turnLeft],
      moveMs: 400,
    ),
    AgeGroup.ages13plus => const AgeSettings(
      commandFamily: CommandFamily.relative,
      cardSize: 48,
      maxCell: 56,
      paletteMode: PaletteMode.fullSet,
      loopStyle: LoopStyle.block,
      commandSet: [Command.forward, Command.turnRight, Command.turnLeft],
      moveMs: 350,
    ),
  };
}

extension LevelPalette on Level {
  /// Oyuncunun bu seviyede kullanabildiği kartlar (paletteki sırayla).
  /// Çözücü de en kısa çözümü bu kümeyle arar.
  List<Command> get paletteCommands {
    final settings = ageGroup.settings;
    return switch (settings.paletteMode) {
      PaletteMode.perLevel => availableCommands,
      PaletteMode.fullSet => settings.commandSet,
    };
  }
}
