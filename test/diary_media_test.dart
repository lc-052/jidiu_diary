import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jidiu_diary/diary/diary_controller.dart';
import 'package:jidiu_diary/pages/diary/diary_doodle.dart';
import 'package:jidiu_diary/pages/diary/diary_editor.dart';
import 'package:jidiu_diary/pages/home/diary.dart';
import 'package:jidiu_diary/theme/app_theme.dart';
import 'package:sembast/sembast_memory.dart';

class _ImagePicker extends FilePicker {
  List<PlatformFile> files = [];
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
  }) async => FilePickerResult(files);
}

void main() {
  test('Image-only entries and doodle drafts persist without changing the published original', () async {
    final factory = newDatabaseFactoryMemory();
    final diary = DiaryController();
    await diary.initialize(database: await factory.openDatabase('media'));
    final now = DateTime.now();
    final photo = DiaryAttachment(
      id: 'photo',
      name: '照片.png',
      bytes: Uint8List.fromList([1, 2, 3]),
    );
    final drawing = DiaryAttachment(
      id: 'drawing',
      name: '涂鸦.png',
      bytes: Uint8List.fromList([4, 5]),
      isDrawing: true,
    );
    DiaryEntry value(List<DiaryAttachment> attachments) => DiaryEntry(
      id: 'entry',
      date: now,
      title: '',
      body: '',
      createdAt: now,
      updatedAt: now,
      attachments: attachments,
    );
    await diary.publish(value([photo]));
    await diary.saveDraft(value([drawing]));
    expect(diary.entry('entry')!.attachments.single.id, 'photo');
    diary.dispose();
    await Future<void>.delayed(Duration.zero);
    final reopened = DiaryController();
    await reopened.initialize(database: await factory.openDatabase('media'));
    expect(reopened.entry('entry')!.attachments.single.bytes, [1, 2, 3]);
    expect(reopened.draft('entry')!.attachments.single.isDrawing, isTrue);
    await reopened.discardDraft('entry');
    expect(reopened.entry('entry')!.attachments.single.id, 'photo');
    await reopened.publish(value([photo, drawing]));
    expect(reopened.drafts, isEmpty);
    expect(reopened.entry('entry')!.attachments.length, 2);
    final oldMap = value([]).toMap()..remove('attachments');
    expect(DiaryEntry.fromMap('old', oldMap).attachments, isEmpty);
    await reopened.delete('entry');
    expect(reopened.entries, isEmpty);
    reopened.dispose();
  });

  testWidgets(
    'Images import, recover in drafts, preview and publish without body text',
    (tester) async {
      final picker = _ImagePicker();
      FilePicker.platform = picker;
      final data = await rootBundle.load('lib/assets/today-selected.png');
      picker.files = [
        PlatformFile(
          name: 'photo.png',
          size: data.lengthInBytes,
          bytes: data.buffer.asUint8List(),
        ),
        PlatformFile(
          name: 'broken.png',
          size: 3,
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
      ];
      final diary = DiaryController();
      await tester.runAsync(() async {
        await diary.initialize(
          database: await newDatabaseFactoryMemory().openDatabase('images_ui'),
        );
      });
      addTearDown(diary.dispose);
      await tester.pumpWidget(
        DiaryScope(
          controller: diary,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DiaryEditor(
                        controller: diary,
                        initial: diary.drafts.firstOrNull,
                      ),
                    ),
                  ),
                  child: const Text('开始写日记'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('开始写日记'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('插入图片'));
      await tester.tap(find.text('插入图片'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();
      expect(find.textContaining('1 张图片未能导入'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      expect(diary.drafts.single.attachments.single.name, 'photo.png');
      await tester.tap(find.byTooltip('返回并保留草稿'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('开始写日记'));
      await tester.pumpAndSettle();
      final thumb = find.byKey(
        ValueKey('diary-image-${diary.drafts.single.attachments.single.id}'),
      );
      await tester.ensureVisible(thumb);
      await tester.pumpAndSettle();
      await tester.tap(thumb);
      await tester.pumpAndSettle();
      expect(find.text('图片 1 / 1'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(diary.entries.single.attachments.single.name, 'photo.png');
      expect(diary.entries.single.body, isEmpty);
      await tester.pumpWidget(
        DiaryScope(
          controller: diary,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: DiaryPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          ValueKey('diary-image-${diary.entries.single.attachments.single.id}'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Doodle supports undo, redo, eraser and inserts a PNG on a narrow dark screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Uint8List? drawing;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  drawing = await Navigator.push<Uint8List>(
                    context,
                    MaterialPageRoute(builder: (_) => const DiaryDoodle()),
                  );
                },
                child: const Text('打开涂鸦'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开涂鸦'));
      await tester.pumpAndSettle();
      final canvas = find.byKey(const ValueKey('doodle-canvas'));
      await tester.ensureVisible(canvas);
      await tester.pumpAndSettle();
      await tester.drag(canvas, const Offset(50, 25));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('撤销'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '插入日记'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip('重做'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('橡皮擦'));
      await tester.pumpAndSettle();
      expect(find.text('切换画笔'), findsOneWidget);
      await tester.tap(find.text('插入日记'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();
      expect(drawing, isNotNull);
      expect(drawing!.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      expect(tester.takeException(), isNull);
    },
  );
}
