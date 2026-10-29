import 'package:flutter/widgets.dart';

import '../jokers/joker_type.dart';
import '../models/age_group.dart';
import '../models/command.dart';
import '../state/game_controller.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';
export 'level_texts.dart';
export 'tutorial_texts.dart';

/// Desteklenen diller: telefon Türkçe ise Türkçe, diğer her dilde İngilizce.
const supportedAppLocales = [Locale('en'), Locale('tr')];

Locale resolveAppLocale(Locale? device) =>
    device?.languageCode == 'tr' ? const Locale('tr') : const Locale('en');

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Enum → yerelleştirilmiş metin yardımcıları.
extension L10nHelpers on AppLocalizations {
  String commandShort(Command c) => switch (c) {
    Command.forward => cmdForward,
    Command.turnRight => cmdRight,
    Command.turnLeft => cmdLeft,
    Command.moveUp => cmdUp,
    Command.moveDown => cmdDown,
    Command.moveLeft => cmdMoveLeft,
    Command.moveRight => cmdMoveRight,
  };

  /// Palette basılı tutunca görünen açıklama.
  String commandHelp(Command c) => switch (c) {
    Command.forward => cardHelpForward,
    Command.turnRight => cardHelpTurnRight,
    Command.turnLeft => cardHelpTurnLeft,
    Command.moveUp => cardHelpUp,
    Command.moveDown => cardHelpDown,
    Command.moveLeft => cardHelpMoveLeft,
    Command.moveRight => cardHelpMoveRight,
  };

  String commandLong(Command c) => switch (c) {
    Command.turnRight => cmdTurnRight,
    Command.turnLeft => cmdTurnLeft,
    _ => commandShort(c),
  };

  String resultTitle(int stars) => switch (stars) {
    3 => resultThreeStars,
    2 => resultTwoStars,
    _ => resultOneStar,
  };

  String ageRangeOf(AgeGroup age) => ageRange(age.name);

  String worldName(int world) => switch (world) {
    1 => world1Name,
    _ => world2Name,
  };
  String ageShortOf(AgeGroup age) => ageShort(age.name);

  String jokerLabel(JokerType type) => switch (type) {
    JokerType.skip => jokerSkip,
    JokerType.life => jokerLife,
    JokerType.video => jokerVideo,
  };

  /// "07:32" biçiminde geri sayım.
  String countdown(Duration d) {
    final s = d.inSeconds.clamp(0, 99 * 60 + 59);
    return '${(s ~/ 60).toString().padLeft(2, '0')}:'
        '${(s % 60).toString().padLeft(2, '0')}';
  }

  String gameMessage(GameMessage m) => switch (m) {
    GameMessage.emptyProgram => emptyProgram,
    GameMessage.stripFull => stripFull,
    GameMessage.lastLife => lastLife,
    GameMessage.videoFailed => videoFailed,
    GameMessage.noCardToRepeat => noCardToRepeat,
    GameMessage.maxRepeat => maxRepeat,
  };
}
