import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/blob.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

import 'diary_database.dart';

class DiaryAttachment {
  const DiaryAttachment({
    required this.id,
    required this.name,
    required this.bytes,
    this.isDrawing = false,
  });
  final String id;
  final String name;
  final Uint8List bytes;
  final bool isDrawing;
  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'bytes': Blob(bytes),
    'isDrawing': isDrawing,
  };
  factory DiaryAttachment.fromMap(Map<String, Object?> map) => DiaryAttachment(
    id: map['id'] as String,
    name: map['name'] as String,
    bytes: (map['bytes'] as Blob).bytes,
    isDrawing: map['isDrawing'] == true,
  );
}

class DiaryEntry {
  DiaryEntry({
    required this.id,
    required DateTime date,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.mood,
    List<DiaryAttachment> attachments = const [],
  }) : date = DateTime(date.year, date.month, date.day),
       attachments = List.unmodifiable(attachments);
  final String id;
  final DateTime date;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? mood;
  final List<DiaryAttachment> attachments;

  String get displayTitle =>
      title.trim().isEmpty ? '${date.month}月${date.day}日的日记' : title;
  String get dateLabel => '${date.year}年${date.month}月${date.day}日';
  String get timeLabel =>
      '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  bool get hasContent =>
      title.trim().isNotEmpty ||
      body.trim().isNotEmpty ||
      attachments.isNotEmpty;

  Map<String, Object?> toMap() => {
    'date': DateTime(date.year, date.month, date.day).toIso8601String(),
    'title': title,
    'body': body,
    'mood': mood,
    'attachments': attachments.map((item) => item.toMap()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
  factory DiaryEntry.fromMap(String id, Map<String, Object?> map) => DiaryEntry(
    id: id,
    date: DateTime.parse(map['date'] as String),
    title: map['title'] as String,
    body: map['body'] as String,
    mood: map['mood'] as int?,
    attachments: (map['attachments'] as List? ?? [])
        .map(
          (item) =>
              DiaryAttachment.fromMap(Map<String, Object?>.from(item as Map)),
        )
        .toList(),
    createdAt: DateTime.parse(map['createdAt'] as String),
    updatedAt: DateTime.parse(map['updatedAt'] as String),
  );
}

class DiarySnapshot {
  DiarySnapshot({
    required List<DiaryEntry> entries,
    required List<DiaryEntry> drafts,
    required Map<DateTime, int> dailyMoods,
  }) : entries = List.unmodifiable(entries),
       drafts = List.unmodifiable(drafts),
       dailyMoods = Map.unmodifiable(dailyMoods);
  final List<DiaryEntry> entries;
  final List<DiaryEntry> drafts;
  final Map<DateTime, int> dailyMoods;
}

class DiaryImportResult {
  const DiaryImportResult(this.entries, this.drafts, this.moods, this.skipped);
  final int entries;
  final int drafts;
  final int moods;
  final int skipped;
}

class DiaryController extends ChangeNotifier {
  DiaryController({Future<Database> Function()? databaseOpener})
    : _databaseOpener = databaseOpener ?? openDiaryDatabase;
  final Future<Database> Function() _databaseOpener;
  Future<void>? _initialization;
  final _entryStore = stringMapStoreFactory.store('entries');
  final _draftStore = stringMapStoreFactory.store('drafts');
  final _dailyMoodStore = stringMapStoreFactory.store('daily_moods');
  final _writes = Lock();
  Database? _database;
  bool _disposed = false;
  bool ready = false;
  String? error;
  List<DiaryEntry> _entries = [];
  List<DiaryEntry> _drafts = [];
  final Map<DateTime, int> _dailyMoods = {};
  Map<DateTime, int> get dailyMoods => Map.unmodifiable(_dailyMoods);
  List<DiaryEntry> get entries => List.unmodifiable(_entries);
  List<DiaryEntry> get drafts => List.unmodifiable(_drafts);

  Future<DiarySnapshot> exportSnapshot() => _writes.synchronized(() async {
    if (!ready || _disposed) throw StateError('日记库尚未就绪');
    return DiarySnapshot(
      entries: _entries,
      drafts: _drafts,
      dailyMoods: _dailyMoods,
    );
  });

  Future<DiaryImportResult> restoreSnapshot(DiarySnapshot snapshot) =>
      _writes.synchronized(() async {
        if (!ready || _disposed) throw StateError('日记库尚未就绪');
        final existingEntries = {for (final value in _entries) value.id: value};
        final newEntries = snapshot.entries
            .where((value) => !existingEntries.containsKey(value.id))
            .toList();
        for (final value in newEntries) {
          existingEntries[value.id] = value;
        }
        final existingDrafts = {for (final value in _drafts) value.id};
        final newDrafts = snapshot.drafts
            .where(
              (value) =>
                  !existingDrafts.contains(value.id) &&
                  (existingEntries[value.id] == null ||
                      value.updatedAt.isAfter(
                        existingEntries[value.id]!.updatedAt,
                      )),
            )
            .toList();
        final newMoods = Map<DateTime, int>.fromEntries(
          snapshot.dailyMoods.entries.where(
            (entry) => !_dailyMoods.containsKey(entry.key),
          ),
        );
        await _database!.transaction((txn) async {
          for (final entry in newEntries) {
            await _entryStore.record(entry.id).put(txn, entry.toMap());
          }
          for (final draft in newDrafts) {
            await _draftStore.record(draft.id).put(txn, draft.toMap());
          }
          for (final mood in newMoods.entries) {
            await _dailyMoodStore
                .record(mood.key.toIso8601String().substring(0, 10))
                .put(txn, {'mood': mood.value});
          }
        });
        _entries.addAll(newEntries);
        _drafts.addAll(newDrafts);
        _dailyMoods.addAll(newMoods);
        _sort();
        _notify();
        return DiaryImportResult(
          newEntries.length,
          newDrafts.length,
          newMoods.length,
          snapshot.entries.length +
              snapshot.drafts.length +
              snapshot.dailyMoods.length -
              newEntries.length -
              newDrafts.length -
              newMoods.length,
        );
      });

  DiaryEntry? entry(String id) =>
      _entries.where((item) => item.id == id).firstOrNull;
  DiaryEntry? draft(String id) =>
      _drafts.where((item) => item.id == id).firstOrNull;
  String newId() => const Uuid().v4();
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize({Database? database}) =>
      _initialization ??= _load(database: database);

  Future<void> retryInitialization() async {
    if (ready) return;
    _initialization = null;
    error = null;
    _notify();
    await initialize();
  }

  Future<void> _load({Database? database}) async {
    try {
      _database = database ?? await _databaseOpener();
      if (_disposed) {
        await _database?.close();
        return;
      }
      _entries = (await _entryStore.find(_database!))
          .map((record) => DiaryEntry.fromMap(record.key, record.value))
          .toList();
      _drafts = (await _draftStore.find(_database!))
          .map((record) => DiaryEntry.fromMap(record.key, record.value))
          .toList();
      _sort();
      _dailyMoods.clear();
      for (final record in await _dailyMoodStore.find(_database!)) {
        _dailyMoods[DateTime.parse(record.key)] = record.value['mood'] as int;
      }
      ready = true;
      error = null;
    } catch (_) {
      error = '日记库加载失败，请重新打开应用';
    }
    _notify();
  }

  void _sort() {
    _entries.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate == 0 ? b.createdAt.compareTo(a.createdAt) : byDate;
    });
    _drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> setDailyMood(DateTime date, int mood) =>
      _writes.synchronized(() async {
        if (!ready || _disposed) throw StateError('Diary library unavailable');
        final day = DateTime(date.year, date.month, date.day);
        final now = DateTime.now();
        if (mood < 0 ||
            mood > 4 ||
            day.isAfter(DateTime(now.year, now.month, now.day))) {
          throw const FormatException('无效日期或心情');
        }
        await _dailyMoodStore
            .record(day.toIso8601String().substring(0, 10))
            .put(_database!, {'mood': mood});
        _dailyMoods[day] = mood;
        _notify();
      });

  List<DiaryEntry> search(String query) {
    final needle = query.trim().toLowerCase();
    return _entries
        .where(
          (item) =>
              needle.isEmpty ||
              '${item.displayTitle}\n${item.body}\n${item.dateLabel}'
                  .toLowerCase()
                  .contains(needle),
        )
        .toList();
  }

  Future<void> saveDraft(DiaryEntry value) => _writes.synchronized(() async {
    if (!ready || _disposed) throw StateError('Diary library unavailable');
    if (!value.hasContent) {
      await _draftStore.record(value.id).delete(_database!);
      _drafts.removeWhere((item) => item.id == value.id);
    } else {
      await _draftStore.record(value.id).put(_database!, value.toMap());
      _drafts.removeWhere((item) => item.id == value.id);
      _drafts.add(value);
    }
    _sort();
    _notify();
  });

  Future<void> publish(DiaryEntry value) => _writes.synchronized(() async {
    if (!ready || _disposed) throw StateError('Diary library unavailable');
    if (value.body.trim().isEmpty && value.attachments.isEmpty) {
      throw const FormatException('日记需要正文、图片或涂鸦');
    }
    if (value.mood != null && (value.mood! < 0 || value.mood! > 4)) {
      throw const FormatException('无效心情');
    }
    await _database!.transaction((txn) async {
      await _entryStore.record(value.id).put(txn, value.toMap());
      await _draftStore.record(value.id).delete(txn);
    });
    _entries.removeWhere((item) => item.id == value.id);
    _entries.add(value);
    _drafts.removeWhere((item) => item.id == value.id);
    _sort();
    _notify();
  });

  Future<void> discardDraft(String id) => _writes.synchronized(() async {
    await _draftStore.record(id).delete(_database!);
    _drafts.removeWhere((item) => item.id == id);
    _notify();
  });

  Future<void> delete(String id) => _writes.synchronized(() async {
    await _database!.transaction((txn) async {
      await _entryStore.record(id).delete(txn);
      await _draftStore.record(id).delete(txn);
    });
    _entries.removeWhere((item) => item.id == id);
    _drafts.removeWhere((item) => item.id == id);
    _notify();
  });

  @override
  void dispose() {
    _disposed = true;
    // Finish pending writes before closing the database.
    unawaited(
      _writes.synchronized(() async {
        await _database?.close();
      }),
    );
    super.dispose();
  }
}

class DiaryScope extends InheritedNotifier<DiaryController> {
  const DiaryScope({
    super.key,
    required DiaryController controller,
    required super.child,
  }) : super(notifier: controller);
  static DiaryController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DiaryScope>()?.notifier;
}
