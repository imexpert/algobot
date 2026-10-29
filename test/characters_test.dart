import 'dart:ui';

import 'package:algobot/characters/base_disc_painter.dart';
import 'package:algobot/characters/character_painter.dart';
import 'package:algobot/characters/character_registry.dart';
import 'package:algobot/characters/collectibles/collectible_painter.dart';
import 'package:algobot/models/direction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const all = CharacterRegistry.all;

  test('Kimlikler benzersiz, 8 karakter, sıra tablodaki gibi', () {
    expect(all.map((c) => c.id).toSet(), hasLength(all.length));
    expect(all.map((c) => c.id), [
      'bip', 'pati', 'vizviz', 'buzi', 'tosbi', 'hop', 'zorp', 'kivilcim', //
    ]);
  });

  test('Kilit eşikleri artan sırada ve en az bir karakter açık', () {
    for (var i = 1; i < all.length; i++) {
      expect(all[i].unlockStars, greaterThanOrEqualTo(all[i - 1].unlockStars));
    }
    expect(CharacterRegistry.unlocked(0), isNotEmpty);
    expect(all.first.unlockStars, 0);
  });

  test('Kilit hesabı toplam yıldıza göre', () {
    List<String> ids(int s) =>
        CharacterRegistry.unlocked(s).map((c) => c.id).toList();
    expect(ids(0), ['bip', 'pati', 'vizviz']);
    expect(ids(4), ['bip', 'pati', 'vizviz']);
    expect(ids(5), contains('buzi'));
    expect(ids(14), isNot(contains('hop')));
    expect(ids(15), contains('hop'));
    expect(ids(24), hasLength(8));
    expect(CharacterRegistry.newlyUnlocked(9, 11).map((c) => c.id), ['tosbi']);
    expect(CharacterRegistry.newlyUnlocked(11, 11), isEmpty);
  });

  test('Bilinmeyen kimlik varsayılana düşer', () {
    expect(CharacterRegistry.byId('yok').id, 'bip');
  });

  for (final def in all) {
    test('${def.id}: 4 yön × 5 durum hatasız çizilir', () {
      for (final dir in Direction.values) {
        for (final state in CharacterState.values) {
          for (final t in [0.0, 0.25, 0.5, 1.0, 2.7]) {
            final recorder = PictureRecorder();
            final canvas = Canvas(recorder);
            def.painter.paint(canvas, const Size(80, 80), dir, state, t);
            recorder.endRecording().dispose();
          }
        }
      }
    });
  }

  test('Toplanabilirler ve taban diski hatasız çizilir', () {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    for (final kind in CollectibleKind.values) {
      paintCollectible(canvas, kind, const Offset(40, 40), 40, bob: 1.2);
      paintCollectible(canvas, kind, const Offset(40, 40), 40, scale: 0);
    }
    paintBaseDisc(canvas, const Offset(40, 40), 80);
    for (var q = 0.0; q <= 4; q += 0.5) {
      paintDirectionArrow(canvas, const Offset(40, 40), 80, q, nudge: 2);
      paintTurnArc(canvas, const Offset(40, 40), 80, q < 2 ? 1 : -1, 0.5);
    }
    recorder.endRecording().dispose();
  });
}
