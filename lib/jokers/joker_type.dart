/// Tüm yaş gruplarında aynı üç joker; her biri seviye başına bir kez.
enum JokerType {
  /// Seviyeyi çözmeden geçer (0 yıldız, "atlandı").
  skip,

  /// +1 can; başlangıç değerini aşabilir.
  life,

  /// Kısa bir video izleyip seviyeyi geçer (Tur Atla ile aynı sonuç).
  video;

  /// Seviyeyi atlatan jokerler.
  bool get skipsLevel => this != life;
}
