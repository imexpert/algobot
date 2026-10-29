import '../models/age_group.dart';
import '../models/command.dart';
import '../models/direction.dart';
import '../models/level.dart';

/// Eğitime özel küçük tahta tanımı (oyun seviyelerinden bağımsız).
class TutorialBoard {
  const TutorialBoard({
    required this.map,
    required this.commands,
    required this.optimal,
    this.start = Direction.east,
  });

  /// ASCII harita (bkz. [Level]).
  final List<String> map;
  final Direction start;

  /// 5–7 paletinde görünen kartlar (8–12 ve 13+ tam kümeyi görür).
  final List<Command> commands;

  /// En kısa çözüm uzunluğu (testler çözücüyle doğrular).
  final int optimal;
}

const _relative = [Command.forward, Command.turnRight, Command.turnLeft];

/// Dönüşlerin eğitimi (T1–T4) ve okların eğitimi (A1–A3) tahtaları.
const tutorialBoards = <String, TutorialBoard>{
  // Tanışma: iki kez İleri.
  'T1': TutorialBoard(map: ['R.G'], commands: _relative, optimal: 2),
  // Dönüş: İleri, Sağa, İleri.
  'T2': TutorialBoard(map: ['R.', '#G'], commands: _relative, optimal: 3),
  // Kendi başına.
  'T3': TutorialBoard(
    map: ['R.#', '#.#', '#.G'],
    commands: _relative,
    optimal: 6,
  ),
  // Toplama.
  'T4': TutorialBoard(map: ['.B.', 'R.G'], commands: _relative, optimal: 7),
  'A1': TutorialBoard(map: ['R.G'], commands: [Command.moveRight], optimal: 2),
  'A2': TutorialBoard(
    map: ['R.', '#G'],
    commands: [Command.moveRight, Command.moveDown],
    optimal: 2,
  ),
  'A3': TutorialBoard(
    map: ['.B.', 'R.G'],
    commands: [Command.moveRight, Command.moveUp, Command.moveDown],
    optimal: 4,
  ),
};

/// Eğitim tahtasını oyun seviyesine çevirir. [age]: oyuncunun yaş grubu
/// (palet, kart boyu ve hız buna göre).
Level tutorialLevel(String id, AgeGroup age) {
  final b = tutorialBoards[id]!;
  return Level(
    id: 0,
    ageGroup: age,
    textKey: 'tutorial$id',
    map: b.map,
    startDirection: b.start,
    availableCommands: b.commands,
    maxSlots: 8,
    optimalLength: b.optimal,
  );
}
