import 'character_def.dart';
import 'collectibles/collectible_painter.dart';
import 'painters/bip_painter.dart';
import 'painters/buzi_painter.dart';
import 'painters/hop_painter.dart';
import 'painters/kivilcim_painter.dart';
import 'painters/pati_painter.dart';
import 'painters/tosbi_painter.dart';
import 'painters/vizviz_painter.dart';
import 'painters/zorp_painter.dart';

/// Tüm karakterler, kilit sırasına göre. Yeni karakter için bir painter
/// dosyası, buraya bir kayıt ve ARB'deki `select` listelerine bir satır.
abstract final class CharacterRegistry {
  static const List<CharacterDef> all = [
    CharacterDef(
      id: 'bip',
      unlockStars: 0,
      painter: BipPainter(),
      collectible: CollectibleKind.battery,
    ),
    CharacterDef(
      id: 'pati',
      unlockStars: 0,
      painter: PatiPainter(),
      collectible: CollectibleKind.fish,
    ),
    CharacterDef(
      id: 'vizviz',
      unlockStars: 0,
      painter: VizvizPainter(),
      collectible: CollectibleKind.honey,
    ),
    CharacterDef(
      id: 'buzi',
      unlockStars: 5,
      painter: BuziPainter(),
      collectible: CollectibleKind.crystal,
    ),
    CharacterDef(
      id: 'tosbi',
      unlockStars: 10,
      painter: TosbiPainter(),
      collectible: CollectibleKind.strawberry,
    ),
    CharacterDef(
      id: 'hop',
      unlockStars: 15,
      painter: HopPainter(),
      collectible: CollectibleKind.carrot,
    ),
    CharacterDef(
      id: 'zorp',
      unlockStars: 20,
      painter: ZorpPainter(),
      collectible: CollectibleKind.star,
    ),
    CharacterDef(
      id: 'kivilcim',
      unlockStars: 24,
      painter: KivilcimPainter(),
      collectible: CollectibleKind.coin,
    ),
  ];

  static CharacterDef byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => all.first);

  static List<CharacterDef> unlocked(int totalStars) =>
      all.where((c) => c.isUnlocked(totalStars)).toList();

  /// `before` → `after` yıldız artışıyla yeni açılan karakterler.
  static List<CharacterDef> newlyUnlocked(int before, int after) =>
      all.where((c) => !c.isUnlocked(before) && c.isUnlocked(after)).toList();
}
