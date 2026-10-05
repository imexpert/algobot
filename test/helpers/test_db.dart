import 'package:algobot/core/clock.dart';
import 'package:algobot/data/db/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Testlerde elle ilerletilen saat.
class FakeClock extends Clock {
  FakeClock([DateTime? start]) : _now = start ?? DateTime(2026, 1, 1, 12);
  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration d) => _now = _now.add(d);
  void set(DateTime t) => _now = t;
}

var _counter = 0;

/// Her çağrıda ayrı, bellek içi bir veritabanı. `noIsolate`: widget
/// testlerinin sahte zamanında da tamamlanır.
Future<AppDatabase> openTestDatabase({bool noIsolate = false}) {
  sqfliteFfiInit();
  return AppDatabase.open(
    factory: noIsolate ? databaseFactoryFfiNoIsolate : databaseFactoryFfi,
    // Aynı süreçte her test kendi veritabanını alsın.
    path: 'file:test_db_${_counter++}?mode=memory&cache=shared',
  );
}
