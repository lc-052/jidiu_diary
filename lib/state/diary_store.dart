import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/diary_entry.dart';

/// All persisted data lives in one versioned snapshot. Notify only after saving.
class DiaryStore extends ChangeNotifier {
  DiaryStore(this._preferences);
  final SharedPreferences _preferences;
  static const storageKey = 'jidiu.snapshot.v1';
  List<DiaryEntry> _entries = [];
  Map<String, Mood> _moods = {};
  bool _darkMode = false;
  bool _busy = false;
  String? loadError;

  List<DiaryEntry> get entries => List.unmodifiable(_entries);
  bool get darkMode => _darkMode;
  bool get busy => _busy;
  Mood? moodOn(DateTime date) => _moods[dateKey(date)];
  int get moodCount => _moods.length;
  Map<Mood, int> get moodTotals => {
    for (final mood in Mood.values)
      mood: _moods.values.where((value) => value == mood).length,
  };

  void load() {
    final raw = _preferences.getString(storageKey);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['version'] != 1) {
        throw const FormatException('Unsupported version');
      }
      final entries = (data['entries'] as List)
          .map(
            (item) =>
                DiaryEntry.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      final moods = (data['moods'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, Mood.values.byName(value as String)),
      );
      _entries = entries;
      _sortEntries();
      _moods = moods;
      _darkMode = data['darkMode'] as bool;
    } catch (_) {
      // Keep the original snapshot intact; prohibit overwriting unreadable data.
      loadError = '本地数据读取失败，原始数据已保留。请先备份应用数据后再排查。';
    }
  }

  void _sortEntries() => _entries.sort((a, b) {
    final dateOrder = b.date.compareTo(a.date);
    return dateOrder == 0 ? b.updatedAt.compareTo(a.updatedAt) : dateOrder;
  });

  Future<void> _commit({
    List<DiaryEntry>? entries,
    Map<String, Mood>? moods,
    bool? darkMode,
  }) async {
    if (loadError != null) throw StateError(loadError!);
    if (_busy) throw StateError('正在保存，请稍后再试');
    _busy = true;
    notifyListeners();
    final nextEntries = entries ?? _entries;
    final nextMoods = moods ?? _moods;
    final nextDarkMode = darkMode ?? _darkMode;
    try {
      final saved = await _preferences.setString(
        storageKey,
        jsonEncode({
          'version': 1,
          'entries': nextEntries.map((entry) => entry.toJson()).toList(),
          'moods': nextMoods.map((key, value) => MapEntry(key, value.name)),
          'darkMode': nextDarkMode,
        }),
      );
      if (!saved) throw StateError('本地保存失败');
      _entries = nextEntries;
      _sortEntries();
      _moods = nextMoods;
      _darkMode = nextDarkMode;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> saveEntry(DiaryEntry entry) => _commit(
    entries: [..._entries.where((item) => item.id != entry.id), entry],
    moods: {..._moods, dateKey(entry.date): entry.mood},
  );

  // A daily mood is an independent check-in, retained when a diary is deleted.
  Future<void> deleteEntry(String id) =>
      _commit(entries: _entries.where((entry) => entry.id != id).toList());
  Future<void> setMood(DateTime date, Mood mood) =>
      _commit(moods: {..._moods, dateKey(date): mood});
  Future<void> setDarkMode(bool enabled) => _commit(darkMode: enabled);

  String exportJson() => const JsonEncoder.withIndent('  ').convert({
    'version': 1,
    'entries': _entries.map((entry) => entry.toJson()).toList(),
    'moods': _moods.map((key, value) => MapEntry(key, value.name)),
    'darkMode': _darkMode,
  });
}
