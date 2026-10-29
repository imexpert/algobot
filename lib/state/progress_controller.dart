import 'package:flutter/foundation.dart';

import '../data/progress_repository.dart';
import '../models/age_group.dart';
import '../models/level.dart';

/// Tüm yaş setlerinin ilerlemesi. Açılışta [load] ile belleğe alınır;
/// değişiklikler hemen görünür, veritabanına arka planda yazılır.
///
/// Seviye kilidi saklanmaz: önceki seviye çözülmüş ya da atlanmışsa açıktır.
/// Karakter kilitleri tüm setlerin toplam yıldızıyla hesaplanır.
class ProgressController extends ChangeNotifier {
  ProgressController(this._repository, this.sets);

  final ProgressRepository _repository;
  final Map<AgeGroup, List<Level>> sets;
  final Map<LevelKey, LevelProgress> _progress = {};

  Future<void> load() async {
    try {
      _progress
        ..clear()
        ..addAll(await _repository.loadAll());
    } catch (e) {
      debugPrint('İlerleme yüklenemedi, boş başlanıyor: $e');
    }
    notifyListeners();
  }

  List<Level> levelsFor(AgeGroup age) => sets[age] ?? const [];

  LevelProgress progressFor(Level level) =>
      _progress[(level.ageGroup, level.id)] ?? const LevelProgress();

  int starsFor(Level level) => progressFor(level).bestStars;
  bool isSkipped(Level level) => progressFor(level).skipped;

  int totalFor(AgeGroup age) =>
      levelsFor(age).fold(0, (sum, l) => sum + starsFor(l));

  int maxFor(AgeGroup age) => levelsFor(age).length * 3;

  /// Karakter kilitleri için: tüm yaş setlerindeki toplam yıldız.
  int get totalStarsAll =>
      _progress.values.fold(0, (sum, p) => sum + p.bestStars);

  /// Tüm yaş setlerinde üç yıldızla çözülmüş seviye sayısı.
  int get threeStarCount =>
      _progress.values.where((p) => p.bestStars >= 3).length;

  /// İlk seviye açıktır; önceki seviye çözülmüş ya da atlanmışsa açıktır.
  bool isUnlocked(Level level) {
    final list = levelsFor(level.ageGroup);
    final index = list.indexOf(level);
    if (index <= 0) return index == 0;
    return progressFor(list[index - 1]).passed;
  }

  bool worldCompleted(AgeGroup age) {
    final list = levelsFor(age);
    return list.isNotEmpty && progressFor(list.last).completed;
  }

  Level? levelAfter(Level level) {
    final list = levelsFor(level.ageGroup);
    final index = list.indexOf(level);
    return index >= 0 && index + 1 < list.length ? list[index + 1] : null;
  }

  /// Seviye çözüldü: yıldız yalnızca artar, "atlandı" işareti kalkar.
  void record(Level level, int stars) {
    final old = progressFor(level);
    _set(
      level,
      old.copyWith(
        bestStars: stars > old.bestStars ? stars : old.bestStars,
        completed: old.completed || stars > 0,
        skipped: stars > 0 ? false : old.skipped,
      ),
    );
  }

  /// Seviye atlandı (0 yıldız). Daha önce çözülmüşse değişmez.
  void markSkipped(Level level) {
    final old = progressFor(level);
    if (old.completed) return;
    _set(level, old.copyWith(skipped: true));
  }

  Future<void> reset() async {
    _progress.clear();
    notifyListeners();
    try {
      await _repository.clearAll();
    } catch (e) {
      debugPrint('İlerleme silinemedi: $e');
    }
  }

  void _set(Level level, LevelProgress progress) {
    if (progressFor(level) == progress) return;
    _progress[(level.ageGroup, level.id)] = progress;
    notifyListeners();
    _save(level, progress);
  }

  /// Veritabanı hatası oyunu çökertmez; bellekteki durumla devam edilir.
  /// (`catchError` kullanılmaz: sqflite `Future<int>` döndürdüğü için
  /// boş işleyici ikinci, yakalanmamış bir hata üretiyordu.)
  Future<void> _save(Level level, LevelProgress progress) async {
    try {
      await _repository.save(level.ageGroup, level.id, progress);
    } catch (e) {
      debugPrint('İlerleme kaydedilemedi: $e');
    }
  }
}
