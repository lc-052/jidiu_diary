import 'dart:convert';
import 'dart:typed_data';

import '../diary/diary_controller.dart';
import '../tarot/daily_tarot_controller.dart';
import '../tarot/tarot_deck.dart';

class DiaryBackup {
  const DiaryBackup({
    required this.diary,
    required this.tarot,
    required this.createdAt,
  });
  final DiarySnapshot diary;
  final List<TarotDraw> tarot;
  final DateTime createdAt;
  int get mediaCount => [
    ...diary.entries,
    ...diary.drafts,
  ].fold(0, (sum, entry) => sum + entry.attachments.length);

  static Future<DiaryBackup> capture(DiaryController controller) async =>
      DiaryBackup(
        diary: await controller.exportSnapshot(),
        tarot: await DailyTarotController.exportRecords(),
        createdAt: DateTime.now(),
      );

  Uint8List encode() {
    Map<String, Object?> entry(DiaryEntry value) => {
      'id': value.id,
      'date': DailyTarotController.dateKey(value.date),
      'title': value.title,
      'body': value.body,
      'mood': value.mood,
      'createdAt': value.createdAt.toIso8601String(),
      'updatedAt': value.updatedAt.toIso8601String(),
      'attachments': [
        for (final item in value.attachments)
          {
            'id': item.id,
            'name': item.name,
            'data': base64Encode(item.bytes),
            'isDrawing': item.isDrawing,
          },
      ],
    };
    return Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'format': 'jidiu-diary-backup',
          'version': 1,
          'createdAt': createdAt.toIso8601String(),
          'entries': diary.entries.map(entry).toList(),
          'drafts': diary.drafts.map(entry).toList(),
          'dailyMoods': [
            for (final value in diary.dailyMoods.entries)
              {
                'date': DailyTarotController.dateKey(value.key),
                'mood': value.value,
              },
          ],
          'tarot': [
            for (final value in tarot)
              {'date': value.date, 'card': value.card.id},
          ],
        }),
      ),
    );
  }

  factory DiaryBackup.decode(Uint8List bytes) {
    try {
      Object? decoded;
      try {
        var text = utf8.decode(bytes);
        if (text.startsWith('\uFEFF')) text = text.substring(1);
        decoded = jsonDecode(text);
      } on FormatException {
        throw const FormatException('备份文件格式不正确或已损坏，请重新选择');
      }
      final data = _map(decoded);
      if (data['format'] != 'jidiu-diary-backup') {
        throw const FormatException('请选择寄丢日记导出的备份文件');
      }
      if (data['version'] != 1) {
        throw const FormatException('暂不支持这个备份版本，请更新应用后重试');
      }
      final entries = _entries(data['entries'], false);
      final drafts = _entries(data['drafts'], true);
      final moods = <DateTime, int>{};
      for (final raw in _list(data['dailyMoods'])) {
        final item = _map(raw);
        final day = _day(item['date']);
        final mood = _mood(item['mood']);
        if (mood == null || moods.containsKey(day)) {
          throw const FormatException('每日心情记录无效或重复');
        }
        moods[day] = mood;
      }
      final tarot = <TarotDraw>[];
      final tarotDays = <DateTime>{};
      for (final raw in _list(data['tarot'])) {
        final item = _map(raw);
        final day = _day(item['date']);
        final card = TarotDeck.byId(_string(item['card']));
        if (card == null || !tarotDays.add(day)) {
          throw const FormatException('塔罗记录无效或重复');
        }
        tarot.add(TarotDraw(DailyTarotController.dateKey(day), card));
      }
      return DiaryBackup(
        diary: DiarySnapshot(
          entries: entries,
          drafts: drafts,
          dailyMoods: moods,
        ),
        tarot: List.unmodifiable(tarot),
        createdAt: _time(data['createdAt']),
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('备份内容不完整或已损坏，请重新选择文件');
    }
  }

  Future<BackupImportResult> restore(DiaryController controller) async {
    final (result, tarotAdded) = await DailyTarotController.restoreRecords(
      tarot,
      () => controller.restoreSnapshot(diary),
    );
    return BackupImportResult(result, tarotAdded, tarot.length - tarotAdded);
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is! Map) throw const FormatException('备份内容格式不正确');
    return Map<String, dynamic>.from(value);
  }

  static List<dynamic> _list(Object? value) {
    if (value is! List) throw const FormatException('备份缺少记录列表');
    return value;
  }

  static String _string(Object? value) {
    if (value is! String) throw const FormatException('备份内容格式不正确');
    return value;
  }

  static DateTime _time(Object? value) {
    final time = DateTime.tryParse(_string(value));
    if (time == null) throw const FormatException('备份时间不正确');
    return time;
  }

  static Uint8List _mediaBytes(Object? value) {
    final text = _string(value);
    try {
      return base64Decode(text);
    } on FormatException {
      throw const FormatException('图片或涂鸦数据已损坏');
    }
  }

  static DateTime _day(Object? value) {
    final text = _string(value);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
      throw const FormatException('备份日期不正确');
    }
    final date = DateTime.tryParse(text);
    if (date == null || DailyTarotController.dateKey(date) != text) {
      throw const FormatException('备份日期不正确');
    }
    return date;
  }

  static int? _mood(Object? value) {
    if (value == null) return null;
    if (value is! int || value < 0 || value > 4) {
      throw const FormatException('备份心情不正确');
    }
    return value;
  }

  static List<DiaryEntry> _entries(Object? data, bool draft) {
    final ids = <String>{};
    return [
      for (final raw in _list(data))
        (() {
          final item = _map(raw);
          final id = _string(item['id']);
          if (id.trim().isEmpty || !ids.add(id)) {
            throw const FormatException('日记记录无效或重复');
          }
          final mediaIds = <String>{};
          final attachments = <DiaryAttachment>[];
          for (final rawAttachment in _list(item['attachments'])) {
            final media = _map(rawAttachment);
            final mediaId = _string(media['id']);
            final bytes = _mediaBytes(media['data']);
            if (mediaId.isEmpty ||
                !mediaIds.add(mediaId) ||
                bytes.isEmpty ||
                media['isDrawing'] is! bool) {
              throw const FormatException('图片或涂鸦数据不完整');
            }
            attachments.add(
              DiaryAttachment(
                id: mediaId,
                name: _string(media['name']),
                bytes: bytes,
                isDrawing: media['isDrawing'] as bool,
              ),
            );
          }
          final entry = DiaryEntry(
            id: id,
            date: _day(item['date']),
            title: _string(item['title']),
            body: _string(item['body']),
            mood: _mood(item['mood']),
            createdAt: _time(item['createdAt']),
            updatedAt: _time(item['updatedAt']),
            attachments: attachments,
          );
          if (!entry.hasContent ||
              (!draft && entry.body.trim().isEmpty && attachments.isEmpty)) {
            throw const FormatException('备份里含有空日记');
          }
          return entry;
        })(),
    ];
  }
}

class BackupImportResult {
  const BackupImportResult(this.diary, this.tarot, this.skippedTarot);
  final DiaryImportResult diary;
  final int tarot;
  final int skippedTarot;
  int get added => diary.entries + diary.drafts + diary.moods + tarot;
  int get skipped => diary.skipped + skippedTarot;
}
