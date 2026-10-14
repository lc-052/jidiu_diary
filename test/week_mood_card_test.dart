import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jidiu_diary/theme/app_theme.dart';
import 'package:jidiu_diary/widgets/week_mood_card.dart';

void main() {
  testWidgets('Each date retains its own mood when switching dates', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: SingleChildScrollView(child: WeekMoodCard()),
        ),
      ),
    );

    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - now.weekday + 1);
    final tuesday = DateTime(monday.year, monday.month, monday.day + 1);
    expect(find.text('😊'), findsNothing);
    await tester.tap(find.text('周一'));
    await tester.pumpAndSettle();
    expect(find.text('选择心情 · ${monday.month}月${monday.day}日'), findsOneWidget);
    await tester.tap(find.text('😊'));
    await tester.pumpAndSettle();
    expect(find.text('😊'), findsOneWidget);
    expect(find.text('选择心情 · ${monday.month}月${monday.day}日'), findsNothing);
    expect(find.text('😐'), findsNothing);

    await tester.tap(find.text('周二'));
    await tester.pumpAndSettle();
    expect(
      find.text('选择心情 · ${tuesday.month}月${tuesday.day}日'),
      findsOneWidget,
    );
    await tester.tap(find.text('😌'));
    await tester.pumpAndSettle();
    expect(find.text('😌'), findsOneWidget);

    await tester.tap(find.text('😊'));
    await tester.pumpAndSettle();
    expect(find.text('选择心情 · ${monday.month}月${monday.day}日'), findsOneWidget);
    expect(find.text('😊'), findsNWidgets(2));
    await tester.tap(find.text('😐'));
    await tester.pumpAndSettle();
    expect(find.text('😊'), findsNothing);
    expect(find.text('😐'), findsOneWidget);
    expect(find.text('😌'), findsOneWidget);
    expect(find.text('选择心情 · ${monday.month}月${monday.day}日'), findsNothing);
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
          home: const Scaffold(
            body: SingleChildScrollView(child: WeekMoodCard()),
          ),
        ),
      );
      expect(find.text('周日'), findsOneWidget);
      expect(find.text('😐'), findsNothing);
      await tester.tap(find.text('周日'));
      await tester.pumpAndSettle();
      expect(find.text('😐'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
