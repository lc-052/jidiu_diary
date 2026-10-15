import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jidiu_diary/backup/diary_backup.dart';
import 'package:jidiu_diary/diary/diary_controller.dart';
import 'package:jidiu_diary/pages/home/mine.dart';
import 'package:jidiu_diary/pages/setting_page.dart';
import 'package:jidiu_diary/tarot/daily_tarot_controller.dart';
import 'package:jidiu_diary/tarot/tarot_deck.dart';
import 'package:jidiu_diary/theme/app_theme.dart';
import 'package:jidiu_diary/theme/theme_controller.dart';
import 'package:jidiu_diary/widgets/data_backup_card.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

DiaryEntry _entry(
  String id, {
  String body = '今天很好',
  List<DiaryAttachment> attachments = const [],
}) => DiaryEntry(
  id: id,
  date: DateTime(2026, 10, 14),
  title: '寄丢日记',
  body: body,
  mood: 3,
  createdAt: DateTime(2026, 10, 14, 12),
  updatedAt: DateTime(2026, 10, 14, 13),
  attachments: attachments,
);

class _BackupPicker extends FilePicker {
  Uint8List? selected;
  Uint8List? saved;
  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    saved = bytes;
    return 'backup.json';
  }

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async => selected == null
      ? null
      : FilePickerResult([
          PlatformFile(
            name: 'backup.json',
            size: selected!.length,
            bytes: selected,
          ),
        ]);
}

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  test('Backup round trip preserves media, drafts, independent moods and tarot, and repeated imports merge safely', () async {
    final source = DiaryController();
    final factory = newDatabaseFactoryMemory();
    await source.initialize(database: await factory.openDatabase('source'));
    final photo = DiaryAttachment(
      id: 'photo',
      name: '照片.gif',
      bytes: Uint8List.fromList([1, 2, 3]),
    );
    final doodle = DiaryAttachment(
      id: 'doodle',
      name: '涂鸦.png',
      bytes: Uint8List.fromList([4, 5]),
      isDrawing: true,
    );
    await source.publish(_entry('note', attachments: [photo, doodle]));
    await source.saveDraft(_entry('draft', body: '还没写完', attachments: [photo]));
    await source.setDailyMood(DateTime(2026, 10, 14), 1);
    await SharedPreferencesAsync().setString(
      'tarot_daily_2026-10-14',
      jsonEncode({'date': '2026-10-14', 'card': 'The Fool'}),
    );
    final backup = DiaryBackup.decode(
      (await DiaryBackup.capture(source)).encode(),
    );
    expect(backup.mediaCount, 3);
    expect(backup.tarot.single.card.id, 'The Fool');
    await SharedPreferencesAsync().remove('tarot_daily_2026-10-14');
    final target = DiaryController();
    await target.initialize(database: await factory.openDatabase('target'));
    final first = await backup.restore(target);
    expect(first.added, 4);
    expect(target.entry('note')!.mood, 3);
    expect(target.dailyMoods[DateTime(2026, 10, 14)], 1);
    expect(target.entry('note')!.attachments.first.bytes, [1, 2, 3]);
    expect(target.entry('note')!.attachments.last.isDrawing, isTrue);
    expect(target.draft('draft')!.attachments.single.name, '照片.gif');
    expect(
      (await DailyTarotController.exportRecords()).single.card.id,
      'The Fool',
    );
    await target.publish(_entry('note', body: '本地修改优先'));
    await target.setDailyMood(DateTime(2026, 10, 14), 4);
    final again = await backup.restore(target);
    expect(again.added, 0);
    expect(again.skipped, 4);
    expect(target.entry('note')!.body, '本地修改优先');
    expect(target.dailyMoods[DateTime(2026, 10, 14)], 4);
    target.dispose();
    await Future<void>.delayed(Duration.zero);
    final reopened = DiaryController();
    await reopened.initialize(database: await factory.openDatabase('target'));
    expect(reopened.entry('note')!.body, '本地修改优先');
    expect(reopened.draft('draft')!.attachments.single.bytes, [1, 2, 3]);
    source.dispose();
    reopened.dispose();
  });

  test(
    'Invalid or unsupported backups are rejected before any records change',
    () async {
      final backup = DiaryBackup(
        diary: DiarySnapshot(
          entries: [_entry('a')],
          drafts: [],
          dailyMoods: {},
        ),
        tarot: [],
        createdAt: DateTime.now(),
      );
      Map<String, dynamic> raw() =>
          jsonDecode(utf8.decode(backup.encode())) as Map<String, dynamic>;
      Uint8List encode(Map<String, dynamic> map) =>
          Uint8List.fromList(utf8.encode(jsonEncode(map)));
      expect(
        () => DiaryBackup.decode(encode(raw()..['version'] = 99)),
        throwsFormatException,
      );
      final badMood = raw();
      (badMood['entries'] as List).first['mood'] = 8;
      expect(() => DiaryBackup.decode(encode(badMood)), throwsFormatException);
      final badDate = raw()
        ..['dailyMoods'] = [
          {'date': '2026-02-31', 'mood': 0},
        ];
      expect(() => DiaryBackup.decode(encode(badDate)), throwsFormatException);
      final duplicate = raw();
      (duplicate['entries'] as List).add((duplicate['entries'] as List).first);
      expect(
        () => DiaryBackup.decode(encode(duplicate)),
        throwsFormatException,
      );
      final badMedia = raw();
      (badMedia['entries'] as List).first['attachments'] = [
        {'id': 'a', 'name': 'a.png', 'isDrawing': false, 'data': '!!!'},
      ];
      expect(() => DiaryBackup.decode(encode(badMedia)), throwsFormatException);
    },
  );

  test('Failed diary restore rolls back newly imported tarot and preserves existing preferences', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setString('theme_mode', 'dark');
    final backup = DiaryBackup(
      diary: DiarySnapshot(entries: [_entry('a')], drafts: [], dailyMoods: {}),
      tarot: [TarotDraw('2026-10-14', TarotDeck.cards.first)],
      createdAt: DateTime.now(),
    );
    final unavailable = DiaryController();
    await expectLater(backup.restore(unavailable), throwsStateError);
    expect(await prefs.getString('tarot_daily_2026-10-14'), isNull);
    expect(await prefs.getString('theme_mode'), 'dark');
    unavailable.dispose();
  });

  test('Restored tarot refreshes already open controllers without replacing their current-day result', () async {
    final diary = DiaryController();
    await diary.initialize(
      database: await newDatabaseFactoryMemory().openDatabase('tarot_refresh'),
    );
    final controller = DailyTarotController(
      clock: () => DateTime(2026, 10, 15),
    );
    await controller.load();
    expect(controller.today, isNull);
    final backup = DiaryBackup(
      diary: DiarySnapshot(entries: [], drafts: [], dailyMoods: {}),
      tarot: [TarotDraw('2026-10-15', TarotDeck.cards.first)],
      createdAt: DateTime.now(),
    );
    final refreshed = Completer<void>();
    controller.addListener(() {
      if (controller.today != null && !refreshed.isCompleted) {
        refreshed.complete();
      }
    });
    await backup.restore(diary);
    await refreshed.future.timeout(const Duration(seconds: 2));
    expect(controller.today!.card.id, 'The Fool');
    final changed = DiaryBackup(
      diary: backup.diary,
      tarot: [TarotDraw('2026-10-15', TarotDeck.cards.last)],
      createdAt: DateTime.now(),
    );
    expect((await changed.restore(diary)).skipped, 1);
    expect((await controller.draw())!.card.id, 'The Fool');
    controller.dispose();
    diary.dispose();
  });

  testWidgets(
    'Backup card exports bytes, previews imports, supports cancellation and merges on confirmation',
    (tester) async {
      final picker = _BackupPicker();
      FilePicker.platform = picker;
      final diary = DiaryController();
      await tester.runAsync(() async {
        await diary.initialize(
          database: await newDatabaseFactoryMemory().openDatabase('backup_ui'),
        );
        await diary.publish(_entry('local'));
      });
      addTearDown(diary.dispose);
      final incoming = DiaryBackup(
        diary: DiarySnapshot(
          entries: [_entry('incoming')],
          drafts: [],
          dailyMoods: {},
        ),
        tarot: [],
        createdAt: DateTime(2026, 10, 14),
      );
      picker.selected = incoming.encode();
      await tester.pumpWidget(
        DiaryScope(
          controller: diary,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: SingleChildScrollView(child: DataBackupCard()),
            ),
          ),
        ),
      );
      await tester.tap(find.text('导出数据'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
      });
      await tester.pumpAndSettle();
      expect(
        DiaryBackup.decode(picker.saved!).diary.entries.single.id,
        'local',
      );
      await tester.tap(find.text('导入数据'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('导入这份备份？'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(diary.entries.length, 1);
      await tester.tap(find.text('导入数据'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('确认导入'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
      });
      await tester.pumpAndSettle();
      expect(diary.entries.length, 2);
      expect(find.textContaining('导入完成'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Settings and Mine both expose the backup card on a narrow dark screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final theme = ThemeController();
      addTearDown(theme.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: SettingPage(themeController: theme),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('数据备份'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('导出数据'), findsOneWidget);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: MinePage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('数据备份'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('导入数据'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
