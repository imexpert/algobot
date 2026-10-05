import '../models/level.dart';
import 'run_result.dart';

class StarCalculator {
  const StarCalculator._();

  /// 0: başarısız, 1: hedef, 2: + tüm toplanabilirler, 3: + en kısa uzunluk.
  static int stars(Level level, RunResult result) {
    if (!result.isSuccess) return 0;
    if (result.collectedCount < level.collectibles.length) return 1;
    if (result.programLength > level.optimalLength) return 2;
    return 3;
  }
}
