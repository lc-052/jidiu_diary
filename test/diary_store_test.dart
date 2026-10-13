import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jidiu_diary/models/diary_entry.dart';
import 'package:jidiu_diary/state/diary_store.dart';

void main() {
  late DiaryStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = DiaryStore(await SharedPreferences.getInstance())..load();
  });
  DiaryEntry entry(
    String id,
    DateTime date, {
    String title = '今天',
    Mood mood = Mood.happy,
  }) => DiaryEntry(
    id: id,
    date: date,
    title: title,
    content: '认真记录生活',
    mood: mood,
    updatedAt: DateTime(2026, 10, 13),
  );
  test('create, update, delete and restore a persisted snapshot', () async {
    await store.saveEntry(entry('1', DateTime(2026, 10, 12)));
    await store.saveEntry(entry('2', DateTime(2026, 10, 13)));
    await store.saveEntry(
      entry('1', DateTime(2026, 10, 12), title: '修改后', mood: Mood.calm),
    );
    await store.setDarkMode(true);
    final restored = DiaryStore(await SharedPreferences.getInstance())..load();
    expect(restored.entries.map((e) => e.id), ['2', '1']);
    expect(restored.entries.last.title, '修改后');
    expect(restored.moodOn(DateTime(2026, 10, 12)), Mood.calm);
    expect(restored.darkMode, true);
    await restored.deleteEntry('1');
    final afterDelete = DiaryStore(await SharedPreferences.getInstance())
      ..load();
    expect(afterDelete.entries.length, 1);
    expect(afterDelete.moodCount, 2);
  });
  test(
    'daily moods replace the same date and export includes all data',
    () async {
      await store.setMood(DateTime(2026, 10, 13, 8), Mood.happy);
      await store.setMood(DateTime(2026, 10, 13, 20), Mood.tired);
      expect(store.moodCount, 1);
      expect(store.moodTotals[Mood.tired], 1);
      final export = jsonDecode(store.exportJson()) as Map;
      expect(export['moods']['2026-10-13'], 'tired');
    },
  );
  test('unreadable snapshot is preserved and writes are blocked', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(DiaryStore.storageKey, '{invalid');
    final broken = DiaryStore(preferences)..load();
    expect(broken.loadError, isNotNull);
    await expectLater(broken.setDarkMode(true), throwsStateError);
    expect(preferences.getString(DiaryStore.storageKey), '{invalid');
  });
}
