import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jidiu_diary/diary/diary_controller.dart';
import 'package:jidiu_diary/pages/home/index.dart';
import 'package:jidiu_diary/pages/diary/diary_editor.dart';
import 'package:jidiu_diary/pages/home/diary.dart';
import 'package:jidiu_diary/theme/app_theme.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  testWidgets(
    'The home mood uses the independent daily mood without a filter chip',
    (tester) async {
      final now = DateTime.now();
      final date = DateTime(
        now.year,
        now.month,
        now.day - (now.weekday > 1 ? 1 : 0),
      );
      final diary = DiaryController();
      await tester.runAsync(() async {
        await diary.initialize(
          database: await newDatabaseFactoryMemory().openDatabase('day_mood'),
        );
        await diary.publish(
          DiaryEntry(
            id: 'selected',
            date: date,
            title: '当天记录',
            body: '平静的一天',
            mood: 3,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await diary.setDailyMood(date, 1);
      });
      addTearDown(diary.dispose);
      await tester.pumpWidget(
        DiaryScope(
          controller: diary,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      await tester.tap(find.text(weekdays[date.weekday - 1]));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      expect(find.text(now.weekday > 1 ? '当日塔罗' : '今日塔罗'), findsOneWidget);
      if (now.weekday > 1) {
        await tester.tap(find.text('日记'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<DiaryPage>(find.byType(DiaryPage)).filterDate,
          date,
        );
        await tester.drag(find.byType(NestedScrollView), const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(find.text('当天记录'), findsOneWidget);
        expect(find.byType(InputChip), findsNothing);
      }
      await tester.tap(find.text('今天'));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Image && widget.semanticLabel == '平静',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'A historical date shows every entry for that day and supports backdating',
    (tester) async {
      final diary = DiaryController();
      final date = DateTime(2026, 10, 12);
      await tester.runAsync(() async {
        await diary.initialize(
          database: await newDatabaseFactoryMemory().openDatabase('filtered'),
        );
        for (var index = 0; index < 3; index++) {
          await diary.publish(
            DiaryEntry(
              id: '$index',
              date: index < 2 ? date : DateTime(2026, 10, 13),
              title: '记录$index',
              body: '正文$index',
              createdAt: DateTime(2026, 10, 14, index),
              updatedAt: DateTime(2026, 10, 14),
            ),
          );
        }
      });
      addTearDown(diary.dispose);
      DateTime? filter = date;
      await tester.pumpWidget(
        DiaryScope(
          controller: diary,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => DiaryPage(filterDate: filter),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('记录0'), findsOneWidget);
      expect(find.text('记录1'), findsOneWidget);
      expect(find.text('记录2'), findsNothing);
      expect(find.text('2 篇日记'), findsOneWidget);
      final dayCard = find.byKey(const ValueKey('diary-day-2026-10-12'));
      expect(dayCard, findsOneWidget);
      expect(
        find.descendant(of: dayCard, matching: find.text('记录0')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dayCard, matching: find.text('记录1')),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.text('记录0')).dy,
        lessThan(tester.getTopLeft(find.text('记录1')).dy),
      );
      await tester.tap(find.text('写日记'));
      await tester.pumpAndSettle();
      expect(find.text('2026年10月12日'), findsOneWidget);
      await tester.tap(find.byTooltip('返回并保留草稿'));
      await tester.pumpAndSettle();
      expect(find.byType(InputChip), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'An uninitialized library inside the app builder becomes writable',
    (tester) async {
      final factory = newDatabaseFactoryMemory();
      final diary = DiaryController(
        databaseOpener: () => factory.openDatabase('startup'),
      );
      addTearDown(diary.dispose);
      expect(diary.ready, isFalse);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) =>
              DiaryScope(controller: diary, child: child!),
          home: const HomePage(),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      await tester.tap(find.text('日记'));
      await tester.pumpAndSettle();
      expect(diary.ready, isTrue);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '写日记'),
      );
      expect(button.onPressed, isNotNull);
      await tester.ensureVisible(find.text('写日记'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('写日记'));
      await tester.pumpAndSettle();
      expect(find.byType(DiaryEditor), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('diary-body')),
        '初始化后能正常写日记。',
      );
      await tester.tap(find.text('保存'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(diary.entries.single.body, '初始化后能正常写日记。');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Write, view, edit, search and confirm deletion through the real UI',
    (tester) async {
      final diary = DiaryController();
      await tester.runAsync(() async {
        await diary.initialize(
          database: await newDatabaseFactoryMemory().openDatabase('flow'),
        );
      });
      addTearDown(diary.dispose);
      await tester.pumpWidget(
        DiaryScope(
          controller: diary,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('写下今天'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('写下今天'));
      await tester.pumpAndSettle();
      expect(find.byType(DiaryEditor), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('diary-title')), '一件小事');
      await tester.enterText(
        find.byKey(const ValueKey('diary-body')),
        '今天看到了晚霞。',
      );
      await tester.tap(find.text('保存'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(diary.entries.length, 1);
      expect(find.byType(DiaryEditor), findsNothing);
      await tester.ensureVisible(find.byTooltip('日记操作'));
      await tester.pumpAndSettle();
      expect(find.text('今天看到了晚霞。'), findsOneWidget);
      await tester.tap(find.byTooltip('日记操作'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('编辑日记'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('diary-body')),
        '今天看到了晚霞，还吃了蛋糕。',
      );
      await tester.tap(find.text('保存'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(diary.entries.length, 1);
      expect(find.byType(DiaryEditor), findsNothing);
      expect(find.text('今天看到了晚霞，还吃了蛋糕。'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('diary-search')), '蛋糕');
      await tester.pumpAndSettle();
      expect(find.text('找到 1 篇日记'), findsOneWidget);
      await tester.ensureVisible(find.text('一件小事'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('日记操作'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除日记'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(diary.entries.length, 1);
      await tester.tap(find.byTooltip('日记操作'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除日记'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(diary.entries, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Leaving the editor preserves a draft and restores it on a small dark screen',
    (tester) async {
      final diary = DiaryController();
      await tester.runAsync(() async {
        await diary.initialize(
          database: await newDatabaseFactoryMemory().openDatabase('draft_ui'),
        );
      });
      addTearDown(diary.dispose);
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        DiaryScope(
          controller: diary,
          child: MaterialApp(theme: AppTheme.darkTheme, home: const HomePage()),
        ),
      );
      await tester.tap(find.text('日记'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('写日记'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('写日记'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('diary-body')),
        '留到明天继续写。',
      );
      await tester.pump(const Duration(milliseconds: 700));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(diary.drafts.single.body, '留到明天继续写。');
      expect(diary.entries, isEmpty);
      await tester.tap(find.byTooltip('返回并保留草稿'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(diary.drafts.length, 1);
      expect(diary.entries, isEmpty);
      expect(find.text('草稿箱 · 1'), findsOneWidget);
      await tester.ensureVisible(find.text(diary.drafts.single.displayTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(diary.drafts.single.displayTitle));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('diary-body')))
            .controller!
            .text,
        '留到明天继续写。',
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('返回并保留草稿'));
      await tester.pumpAndSettle();
    },
  );
}
