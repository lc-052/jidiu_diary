import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jidiu_diary/theme/app_theme.dart';
import 'package:jidiu_diary/widgets/week_mood_card.dart';

void main() {
  testWidgets(
    'The month button opens the daily-mood calendar and switches weeks',
    (tester) async {
      DateTime? selectedDate;
      DateTime? changedDate;
      int? changedMood;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: WeekMoodCard(
                currentDate: DateTime(2026, 10, 14),
                dailyMoods: {DateTime(2026, 10, 7): 1},
                onDateSelected: (date) => selectedDate = date,
                onDailyMoodChanged: (date, mood) {
                  changedDate = date;
                  changedMood = mood;
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('week-calendar-button')));
      await tester.pumpAndSettle();
      expect(find.text('心情日历'), findsOneWidget);
      expect(find.text('😌'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('calendar-day-2026-10-06')));
      await tester.ensureVisible(find.text('确定'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(selectedDate, DateTime(2026, 10, 6));
      expect(find.text('5'), findsOneWidget);
      expect(find.text('12'), findsNothing);
      await tester.tap(find.text('周二'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('😡'));
      await tester.pumpAndSettle();
      expect(changedDate, DateTime(2026, 10, 6));
      expect(changedMood, 3);
      expect(find.text('😡'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Future dates cannot be selected; past dates request diaries', (
    tester,
  ) async {
    DateTime? selectedPast;
    int? selectedMood;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: WeekMoodCard(
              currentDate: DateTime(2026, 10, 14),
              onPastDateSelected: (date) => selectedPast = date,
              onTodayMoodChanged: (mood) => selectedMood = mood,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('周四'));
    await tester.pumpAndSettle();
    expect(find.text('😐'), findsNothing);
    expect(selectedPast, isNull);
    expect(find.text('选择心情 · 10月15日'), findsNothing);
    await tester.tap(find.text('周一'));
    await tester.pumpAndSettle();
    expect(selectedPast, DateTime(2026, 10, 12));
    expect(find.text('😐'), findsOneWidget);
    await tester.tap(find.text('周三'));
    await tester.pumpAndSettle();
    expect(find.text('选择心情 · 10月14日'), findsOneWidget);
    await tester.tap(find.text('😊'));
    await tester.pumpAndSettle();
    expect(selectedMood, 0);
    expect(find.text('选择心情 · 10月14日'), findsNothing);
    await tester.tap(find.text('😊'));
    await tester.pumpAndSettle();
    expect(find.text('选择心情 · 10月14日'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets('Fits a small phone in ${dark ? 'dark' : 'light'} mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: WeekMoodCard(currentDate: DateTime(2026, 10, 14)),
            ),
          ),
        ),
      );
      await tester.tap(find.text('周三'));
      await tester.pumpAndSettle();
      expect(find.text('😐'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
