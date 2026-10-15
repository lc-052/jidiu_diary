import 'dart:convert';
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

import 'tarot_deck.dart';

class TarotDraw {
  const TarotDraw(this.date, this.card);
  final String date;
  final TarotCard card;
}

class DailyTarotController extends ChangeNotifier {
  DailyTarotController({
    Future<String?> Function(String)? read,
    Future<void> Function(String, String)? write,
    DateTime Function()? clock,
    Random? random,
  }) : _read = read ?? ((key) async => SharedPreferencesAsync().getString(key)),
       _write =
           write ??
           ((key, value) async =>
               SharedPreferencesAsync().setString(key, value)),
       _clock = clock ?? DateTime.now,
       _random = random ?? Random.secure() {
    _instances.add(this);
  }
  final Future<String?> Function(String) _read;
  final Future<void> Function(String, String) _write;
  final DateTime Function() _clock;
  final Random _random;
  static final _lock = Lock();
  static final _instances = <DailyTarotController>{};

  static Future<List<TarotDraw>> exportRecords() =>
      _lock.synchronized(() async {
        final values = await SharedPreferencesAsync().getAll();
        final records = <TarotDraw>[];
        for (final entry in values.entries) {
          if (!entry.key.startsWith('tarot_daily_') || entry.value is! String) {
            continue;
          }
          final day = entry.key.substring('tarot_daily_'.length);
          final record = _decodeRecord(entry.value as String, day);
          if (record != null) records.add(record);
        }
        records.sort((a, b) => b.date.compareTo(a.date));
        return records;
      });

  // Keep tarot writes and the diary transaction together; undo newly added keys on failure.
  static Future<(T, int)> restoreRecords<T>(
    List<TarotDraw> records,
    Future<T> Function() restoreDiary,
  ) => _lock.synchronized(() async {
    final prefs = SharedPreferencesAsync();
    final added = <String>[];
    late T result;
    try {
      for (final record in records) {
        final key = 'tarot_daily_${record.date}';
        if (await prefs.getString(key) != null) continue;
        added.add(key);
        await prefs.setString(
          key,
          jsonEncode({'date': record.date, 'card': record.card.id}),
        );
      }
      result = await restoreDiary();
    } catch (_) {
      var rollbackFailed = false;
      for (final key in added.reversed) {
        try {
          await prefs.remove(key);
        } catch (_) {
          rollbackFailed = true;
        }
      }
      if (rollbackFailed) throw StateError('导入未完成，部分塔罗记录可能已恢复，请重试');
      rethrow;
    }
    if (added.isNotEmpty) {
      for (final controller in _instances.toList()) {
        final days = controller._draws.keys.toList();
        controller._draws.clear();
        controller._notify();
        for (final day in days) {
          unawaited(controller.load(forDate: DateTime.parse(day)));
        }
      }
    }
    return (result, added.length);
  });
  final Map<String, TarotDraw?> _draws = {};
  bool _disposed = false;
  bool busy = false;
  String? error;
  static String dateKey(DateTime day) => day.toIso8601String().substring(0, 10);
  String get date => dateKey(_clock());
  TarotDraw? get today => _draws[date];
  TarotDraw? resultForDate(DateTime day) => _draws[dateKey(day)];
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<TarotDraw?> _stored(String day) async {
    final raw = await _read('tarot_daily_$day');
    if (raw == null) return null;
    return _decodeRecord(raw, day);
  }

  static TarotDraw? _decodeRecord(String raw, String day) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final id = map['card'];
      final card = id is String ? TarotDeck.byId(id) : null;
      return map['date'] == day && card != null ? TarotDraw(day, card) : null;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> load({DateTime? forDate}) => _lock.synchronized(() async {
    if (_disposed) return;
    busy = true;
    error = null;
    _notify();
    try {
      final day = forDate == null ? date : dateKey(forDate);
      _draws[day] = await _stored(day);
    } catch (_) {
      error = '塔罗记录读取失败，请重试';
    } finally {
      busy = false;
      _notify();
    }
  });

  Future<TarotDraw?> draw() => _lock.synchronized(() async {
    if (_disposed) return null;
    busy = true;
    error = null;
    _notify();
    try {
      final day = date;
      var result = await _stored(day);
      if (result == null) {
        result = TarotDraw(
          day,
          TarotDeck.cards[_random.nextInt(TarotDeck.cards.length)],
        );
        await _write(
          'tarot_daily_$day',
          jsonEncode({'date': day, 'card': result.card.id}),
        );
      }
      _draws[day] = result;
      return result;
    } catch (_) {
      error = '抽牌未能保存，请重试';
      return null;
    } finally {
      busy = false;
      _notify();
    }
  });

  @override
  void dispose() {
    _disposed = true;
    _instances.remove(this);
    super.dispose();
  }
}
