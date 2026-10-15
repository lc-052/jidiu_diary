import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jidiu_diary/diary/diary_controller.dart';
import 'package:jidiu_diary/pages/home/index.dart';
import 'package:jidiu_diary/pages/home/mine.dart';
import 'package:jidiu_diary/theme/app_theme.dart';
import 'package:jidiu_diary/widgets/week_mood_card.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  testWidgets(
    'Mine statistics cover all dates and stay unchanged when the calendar changes month',
    (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final previous = DateTime(now.year, now.month, 0);
      final diary = DiaryController();
      await tester.runAsync(() async {
        await diary.initialize(
          database: await newDatabaseFactoryMemory().openDatabase('mine'),
        );
        await diary.publish(
          DiaryEntry(
            id: 'note',
            date: today,
            title: '日记心情不同',
            body: '记录',
            mood: 3,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await diary.setDailyMood(today, 0);
        await diary.setDailyMood(previous, 1);
        await diary.publish(
          DiaryEntry(
            id: 'previous-note',
            date: previous,
            title: '以前的日记',
            body: '记录',
            createdAt: now,
            updatedAt: now,
          ),
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
      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();
      expect(find.byType(WeekMoodCard), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == '开心 1天',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == '平静 1天',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == '生气 1篇',
        ),
        findsOneWidget,
      );
      expect(find.text('累计心情 / 天'), findsOneWidget);
      expect(find.text('累计日记 / 篇'), findsOneWidget);
      expect(find.text('2'), findsNWidgets(2));
      expect(find.text('每篇日记独立统计 · 未选心情 1 篇'), findsOneWidget);
      expect(find.byTooltip('上个月'), findsNothing);
      final calendar = find.byKey(const ValueKey('mine-mood-calendar-card'));
      final scrollable = find
          .descendant(
            of: find.byType(MinePage),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(calendar, 250, scrollable: scrollable);
      await tester.ensureVisible(calendar);
      await tester.pumpAndSettle();
      final currentCell = find.byKey(
        ValueKey(
          'mine-calendar-day-${today.toIso8601String().substring(0, 10)}',
        ),
      );
      expect(
        find.descendant(of: currentCell, matching: find.text('😊')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: calendar, matching: find.text('😡')),
        findsNothing,
      );
      expect(find.text('日记心情不同'), findsNothing);
      await tester.tap(find.byTooltip('日历上个月'));
      await tester.pumpAndSettle();
      final pastCell = find.byKey(
        ValueKey(
          'mine-calendar-day-${previous.toIso8601String().substring(0, 10)}',
        ),
      );
      expect(
        find.descendant(of: pastCell, matching: find.text('😌')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('mine-statistics-card')),
        -250,
        scrollable: scrollable,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('mine-statistics-card')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == '平静 1天',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == '开心 1天',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == '生气 1篇',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('今天'));
      await tester.pumpAndSettle();
      expect(find.byType(WeekMoodCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Empty calendar fits a narrow dark screen', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(body: SafeArea(child: MinePage())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('mine-month-grid')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('mine-month-grid')));
    await tester.pumpAndSettle();
    expect(find.text('心情日历'), findsOneWidget);
    expect(find.byKey(const ValueKey('mine-month-grid')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
