/// Robotun baktığı yön. Koordinat sistemi: x sağa, y aşağı artar.
enum Direction {
  north(0, -1),
  east(1, 0),
  south(0, 1),
  west(-1, 0);

  const Direction(this.dx, this.dy);

  final int dx;
  final int dy;

  /// Saat yönünde 90° dönüş.
  Direction get turnRight => Direction.values[(index + 1) % 4];

  /// Saat yönünün tersine 90° dönüş.
  Direction get turnLeft => Direction.values[(index + 3) % 4];
}
