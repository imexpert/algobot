import 'dart:convert';
import 'dart:io';

import 'package:algobot/characters/character_registry.dart';
import 'package:algobot/data/levels.dart';
import 'package:algobot/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _keys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final tr = lookupAppLocalizations(const Locale('tr'));

  test('app_tr.arb ve app_en.arb aynı anahtar kümesine sahip', () {
    final enKeys = _keys(_arb('en'));
    final trKeys = _keys(_arb('tr'));
    expect(trKeys.difference(enKeys), isEmpty, reason: 'Fazla TR anahtarı');
    expect(enKeys.difference(trKeys), isEmpty, reason: 'Eksik TR çevirisi');
    for (final k in enKeys) {
      expect((_arb('tr')[k] as String).trim(), isNotEmpty, reason: k);
    }
  });

  test('Kaldırılan joker anahtarları iki ARB\'de de yok', () {
    const removed = [
      'jokerFlashlight',
      'jokerMagnifier',
      'jokerHeart',
      'jokerBudget',
      'hintWarning',
      'hintNoJoker',
      'magnifierWrong',
      'magnifierKeepGoing',
      'magnifierWorks',
      'attemptsLabel',
      'outOfTriesTitle',
      'useHeart',
      'stepMode',
      'nextStep',
      'commands',
    ];
    for (final locale in ['en', 'tr']) {
      final keys = _keys(_arb(locale));
      for (final k in removed) {
        expect(keys.contains(k), isFalse, reason: '\$locale: \$k');
      }
    }
  });

  test('Eski uygulama adı hiçbir çeviride kalmamış', () {
    for (final locale in ['en', 'tr']) {
      final arb = _arb(locale);
      for (final k in _keys(arb)) {
        final v = arb[k] as String;
        expect(v, isNot(contains('Kod Robotu')), reason: '$locale: $k');
        expect(v, isNot(contains('Code Robot')), reason: '$locale: $k');
      }
    }
  });

  test('Telefon Türkçe ise Türkçe, diğer tüm dillerde İngilizce', () {
    expect(resolveAppLocale(const Locale('tr')).languageCode, 'tr');
    expect(resolveAppLocale(const Locale('tr', 'TR')).languageCode, 'tr');
    for (final code in ['en', 'de', 'ar', 'fr', 'ja']) {
      expect(resolveAppLocale(Locale(code)).languageCode, 'en', reason: code);
    }
    expect(resolveAppLocale(null).languageCode, 'en');
  });

  test('Tüm seviyelerin başlık ve ipucu anahtarları iki ARB\'de de var', () {
    final enArb = _arb('en'), trArb = _arb('tr');
    for (final set in allLevelSets.values) {
      for (final level in set) {
        for (final suffix in ['Title', 'Intro']) {
          final key = '${level.textKey}$suffix';
          expect(enArb.containsKey(key), isTrue, reason: key);
          expect(trArb.containsKey(key), isTrue, reason: key);
        }
        // Arama tablosu da anahtarı çözüyor.
        for (final l in [en, tr]) {
          expect(l.levelTitle(level), isNot(level.textKey));
          expect(l.levelIntro(level), isNotEmpty);
        }
      }
    }
  });

  test('Karakter adları ve toplanabilir adları iki dilde de tanımlı', () {
    for (final c in CharacterRegistry.all) {
      for (final l in [en, tr]) {
        expect(l.characterName(c.id), isNot('?'), reason: c.id);
        expect(l.collectedCount(c.id, 1, 2), isNot(startsWith('?')));
        expect(l.hintCollect(c.id), isNot(contains('?')));
      }
    }
    expect(en.characterName('pati'), 'Whiskers');
    expect(tr.characterName('kivilcim'), 'Kıvılcım');
    expect(en.newFriend(en.characterName('buzi')), 'New friend: Pingo!');
  });

  test('Çoğul ifadeler ve temel terimler', () {
    expect(en.livesLabel(1), '1 life left');
    expect(en.livesLabel(3), '3 lives left');
    expect(tr.livesLabel(2), '2 can kaldı');
    expect(en.nextLife('07:32'), 'Next life: 07:32');
    expect(tr.jokerSkip, 'Atla');
    expect(en.jokerVideo, 'Video');
    expect(tr.about, contains('Veri toplanmaz.'));
    expect(tr.about, isNot(contains('Reklam yok')));
    expect(en.about, contains('No data collected.'));
    expect(en.starsLabel(1), '1 star out of 3');
    expect(en.starsLabel(2), '2 stars out of 3');
    expect(tr.collectedCount('pati', 1, 2), 'Balıklar: 1 / 2');
    expect(en.collectedCount('bip', 1, 2), 'Batteries: 1 / 2');
    expect(en.parentQuestion(27, 15), 'What is 27 + 15?');
    expect(tr.parentQuestion(27, 15), '27 + 15 kaç?');
    expect(en.appTitle, 'AlgoBot');
    expect(tr.appTitle, 'AlgoBot');
    expect(en.unlockAt(10), 'Unlocks at 10 stars');
    expect(en.ageRange('ages5to7'), 'Ages 5–7');
  });
}
