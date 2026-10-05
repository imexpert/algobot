import 'dart:math';

import '../models/direction.dart';

/// Simülatörün ve çözücünün ortak durumu.
/// `collectedMask`: `level.collectibles` sırasına göre toplananların bitleri.
class SimState {
  const SimState({
    required this.position,
    required this.direction,
    this.collectedMask = 0,
    this.hasKey = false,
  });

  final Point<int> position;
  final Direction direction;
  final int collectedMask;
  final bool hasKey;

  SimState copyWith({
    Point<int>? position,
    Direction? direction,
    int? collectedMask,
    bool? hasKey,
  }) => SimState(
    position: position ?? this.position,
    direction: direction ?? this.direction,
    collectedMask: collectedMask ?? this.collectedMask,
    hasKey: hasKey ?? this.hasKey,
  );

  @override
  bool operator ==(Object other) =>
      other is SimState &&
      other.position == position &&
      other.direction == direction &&
      other.collectedMask == collectedMask &&
      other.hasKey == hasKey;

  @override
  int get hashCode => Object.hash(position, direction, collectedMask, hasKey);
}
