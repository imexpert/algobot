import 'character_painter.dart';
import 'collectibles/collectible_painter.dart';

/// Bir karakterin tanımı. Ad ve toplanabilir adları ARB dosyalarında,
/// karakter kimliğine göre `select` ile tutulur (`characterName` vb.).
class CharacterDef {
  const CharacterDef({
    required this.id,
    required this.unlockStars,
    required this.painter,
    required this.collectible,
  });

  final String id;

  /// Tüm yaş setlerindeki toplam yıldız bu değere ulaşınca açılır.
  final int unlockStars;
  final CharacterPainter painter;
  final CollectibleKind collectible;

  bool isUnlocked(int totalStars) => totalStars >= unlockStars;
}
