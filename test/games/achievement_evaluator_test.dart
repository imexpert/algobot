import 'package:algobot/data/levels.dart';
import 'package:algobot/data/progress_repository.dart';
import 'package:algobot/games/achievement_definitions.dart';
import 'package:algobot/games/achievement_evaluator.dart';
import 'package:algobot/models/age_group.dart';
import 'package:algobot/models/cell.dart';
import 'package:algobot/models/level.dart';
import 'package:flutter_test/flutter_test.dart';

/// Elle doldurulan ilerleme: `solve(level, stars)` ya da `skip(level)`.
class _Progress {
  final _map = <LevelKey, LevelProgress>{};

  void solve(Level l, int stars) => _map[(l.ageGroup, l.id)] = LevelProgress(
    bestStars: stars,
    completed: true,
  );

  void skip(Level l) =>
      _map[(l.ageGroup, l.id)] = const LevelProgress(skipped: true);

  /// Bozuk/eski kayıt: yıldız var ama çözülmedi işaretli değil.
  void raw(Level l, LevelProgress p) => _map[(l.ageGroup, l.id)] = p;

  Map<String, AchievementProgress> eval({
    bool tutorial = false,
    bool lastLife = false,
  }) => AchievementEvaluator.evaluate(
    AchievementFacts(
      sets: allLevelSets,
      progressOf: (l) => _map[(l.ageGroup, l.id)] ?? const LevelProgress(),
      tutorialCompleted: tutorial,
      solvedOnLastLife: lastLife,
    ),
  );
}

List<Level> _set(AgeGroup age) => levelsFor(age);

void main() {
  late _Progress p;
  setUp(() => p = _Progress());

  test('boş ilerlemede hiçbir başarım açık değil', () {
    final r = p.eval();
    expect(r.keys, Achievements.all.map((a) => a.key));
    // İlk üç karakter baştan açık: friends_4 ilerlemesi 3/4.
    expect(r[Achievements.friends4]!.progress, 3);
    expect(r[Achievements.friends8]!.progress, 3);
    for (final a in r.values) {
      expect(a.unlocked, isFalse, reason: a.key);
    }
  });

  test('eğitim ve son can olayları', () {
    expect(p.eval(tutorial: true)[Achievements.tutorialDone]!.unlocked, true);
    expect(p.eval(lastLife: true)[Achievements.lastLife]!.unlocked, true);
    expect(p.eval()[Achievements.tutorialDone]!.unlocked, false);
  });

  test('ilk seviye ve ilk üç yıldız', () {
    final l = _set(AgeGroup.ages8to12).first;
    p.solve(l, 2);
    var r = p.eval();
    expect(r[Achievements.firstLevel]!.unlocked, true);
    expect(r[Achievements.firstPerfect]!.unlocked, false);
    p.solve(l, 3);
    r = p.eval();
    expect(r[Achievements.firstPerfect]!.unlocked, true);
  });

  test('atlanan seviyeler sayılmaz', () {
    for (final l in _set(AgeGroup.ages5to7)) {
      p.skip(l);
    }
    final r = p.eval();
    expect(r[Achievements.firstLevel]!.unlocked, false);
    expect(r[Achievements.world5to7]!.unlocked, false);
    expect(r[Achievements.stars12]!.progress, 0);
  });

  test('çözülmemiş işaretli kayıttaki yıldızlar sayılmaz', () {
    final l = _set(AgeGroup.ages5to7).first;
    p.raw(l, const LevelProgress(bestStars: 3));
    expect(p.eval()[Achievements.stars12]!.progress, 0);
  });

  test('set başarımı: setin 16 seviyesinin hepsi gerçekten çözülmeli', () {
    final levels = _set(AgeGroup.ages5to7);
    expect(levels, hasLength(16));
    for (final l in levels.take(15)) {
      p.solve(l, 1);
    }
    p.skip(levels.last);
    expect(p.eval()[Achievements.world5to7]!.unlocked, false);
    p.solve(levels.last, 1);
    final r = p.eval();
    expect(r[Achievements.world5to7]!.unlocked, true);
    expect(r[Achievements.world8to12]!.unlocked, false);
    expect(r[Achievements.world13plus]!.unlocked, false);
  });

  test('diğer set başarımları kendi setlerine bağlı', () {
    for (final l in _set(AgeGroup.ages8to12)) {
      p.solve(l, 1);
    }
    for (final l in _set(AgeGroup.ages13plus)) {
      p.solve(l, 1);
    }
    final r = p.eval();
    expect(r[Achievements.world8to12]!.unlocked, true);
    expect(r[Achievements.world13plus]!.unlocked, true);
    expect(r[Achievements.world5to7]!.unlocked, false);
  });

  test('yıldız başarımları artan ilerleme verir', () {
    final levels = _set(AgeGroup.ages8to12);
    for (final l in levels.take(3)) {
      p.solve(l, 3); // 9 yıldız
    }
    var r = p.eval();
    expect(
      r[Achievements.stars12],
      const AchievementProgress('stars_12', 9, 12),
    );
    expect(r[Achievements.stars36]!.progress, 9);
    expect(r[Achievements.stars144]!.progress, 9);
    p.solve(levels[3], 3); // 12
    r = p.eval();
    expect(r[Achievements.stars12]!.unlocked, true);
    expect(r[Achievements.stars36]!.unlocked, false);
  });

  test('ilerleme hedefi aşmaz; tüm yıldızlar Galaksi', () {
    for (final list in allLevelSets.values) {
      for (final l in list) {
        p.solve(l, 3);
      }
    }
    final r = p.eval(tutorial: true, lastLife: true);
    expect(r[Achievements.stars12]!.progress, 12);
    expect(r[Achievements.stars144]!.progress, 144);
    // Tüm ilerlemeden toplu hesaplama: hepsi açık.
    for (final a in r.values) {
      expect(a.unlocked, isTrue, reason: a.key);
    }
  });

  test('karakter başarımları açık karakter sayısını izler', () {
    final levels = _set(AgeGroup.ages8to12);
    p.solve(levels[0], 3);
    p.solve(levels[1], 2); // 5 yıldız → Buzi açılır (4 karakter)
    var r = p.eval();
    expect(r[Achievements.friends4]!.unlocked, true);
    expect(r[Achievements.friends8]!.progress, 4);
    for (final l in levels.take(8)) {
      p.solve(l, 3); // 24 yıldız → 8 karakter
    }
    r = p.eval();
    expect(r[Achievements.friends8]!.unlocked, true);
  });

  test('Sıfır Hata: herhangi bir dünyanın 8 seviyesi 3 yıldız', () {
    final world2 = _set(
      AgeGroup.ages13plus,
    ).where((l) => l.world == 2).toList();
    expect(world2, hasLength(8));
    for (final l in world2.take(7)) {
      p.solve(l, 3);
    }
    p.solve(world2.last, 2);
    expect(p.eval()[Achievements.perfectWorld]!.unlocked, false);
    p.solve(world2.last, 3);
    expect(p.eval()[Achievements.perfectWorld]!.unlocked, true);
  });

  test('13+ mekanik tanıtım seviyeleri', () {
    final levels = _set(AgeGroup.ages13plus);
    Level intro(CellType c) => levels.firstWhere((l) => l.hasCell(c));
    p.solve(intro(CellType.ice), 1);
    var r = p.eval();
    expect(r[Achievements.iceMaster]!.unlocked, true);
    expect(r[Achievements.keyMaster]!.unlocked, false);
    p.solve(intro(CellType.door), 1);
    p.skip(intro(CellType.portalA));
    r = p.eval();
    expect(r[Achievements.keyMaster]!.unlocked, true);
    expect(r[Achievements.portalMaster]!.unlocked, false);
    p.solve(intro(CellType.portalA), 1);
    expect(p.eval()[Achievements.portalMaster]!.unlocked, true);
  });

  test('tanımlar: benzersiz anahtar, 5\'in katı puan, toplam ≤ 1000', () {
    final keys = Achievements.all.map((a) => a.key).toSet();
    expect(keys, hasLength(Achievements.all.length));
    expect(Achievements.all, hasLength(17));
    for (final a in Achievements.all) {
      expect(a.points % 5, 0, reason: a.key);
      expect(a.points, greaterThan(0));
    }
    expect(Achievements.totalPoints, 760);
    expect(Achievements.totalPoints, lessThanOrEqualTo(1000));
  });
}
