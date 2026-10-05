import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/age_group.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs)
    : _soundOn = _prefs.getBool(_soundKey) ?? true,
      _ageGroup = _parseAge(_prefs.getString(_ageKey)),
      _characterId = _prefs.getString(_characterKey) ?? defaultCharacterId {
    // Kaldırılan özelliklerin eski kayıtları sessizce silinir.
    _prefs
      ..remove('voice_on')
      ..remove('hint_joker_warning_seen');
  }

  static const _soundKey = 'sound_on';
  static const _ageKey = 'age_group';
  static const _characterKey = 'character_id';
  static const defaultCharacterId = 'bip';

  final SharedPreferences _prefs;
  bool _soundOn;
  AgeGroup? _ageGroup;
  String _characterId;

  static AgeGroup? _parseAge(String? name) =>
      AgeGroup.values.where((a) => a.name == name).firstOrNull;

  bool get soundOn => _soundOn;

  /// Hiç seçilmemişse null (ilk açılış akışı gösterilir).
  AgeGroup? get ageGroupOrNull => _ageGroup;
  AgeGroup get ageGroup => _ageGroup ?? AgeGroup.ages8to12;

  String get characterId => _characterId;

  Future<void> setSoundOn(bool value) async {
    if (value == _soundOn) return;
    _soundOn = value;
    notifyListeners();
    await _prefs.setBool(_soundKey, value);
  }

  Future<void> toggleSound() => setSoundOn(!_soundOn);

  Future<void> setAgeGroup(AgeGroup age) async {
    if (age == _ageGroup) return;
    _ageGroup = age;
    notifyListeners();
    await _prefs.setString(_ageKey, age.name);
  }

  Future<void> setCharacter(String id) async {
    if (id == _characterId) return;
    _characterId = id;
    notifyListeners();
    await _prefs.setString(_characterKey, id);
  }
}
