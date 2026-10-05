import 'age_group.dart';
import 'direction.dart';

enum Command {
  // Göreli komutlar (8–12, 13+).
  forward,
  turnRight,
  turnLeft,
  // Mutlak yön komutları (5–7): önce o yöne döner, sonra bir kare ilerler.
  moveUp,
  moveDown,
  moveLeft,
  moveRight;

  CommandFamily get family => switch (this) {
    forward || turnRight || turnLeft => CommandFamily.relative,
    _ => CommandFamily.absolute,
  };

  /// Mutlak komutun hedef yönü; göreli komutlarda null.
  Direction? get absoluteDirection => switch (this) {
    moveUp => Direction.north,
    moveDown => Direction.south,
    moveLeft => Direction.west,
    moveRight => Direction.east,
    _ => null,
  };

  bool get isTurn => this == turnRight || this == turnLeft;
  bool get moves => !isTurn;
}
