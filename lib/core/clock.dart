/// Zaman kaynağı. Uygulamada sistem saati, testlerde sahte saat.
abstract class Clock {
  const Clock();
  DateTime now();
}

class SystemClock extends Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
