import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jidiu_diary/widgets/mood_calendar.dart';
import 'package:jidiu_diary/theme/app_theme.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'Mood calendar shows day emojis and disables future days in ${dark ? 'dark' : 'light'} mode',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            home: Scaffold(
              body: MoodCalendar(
                initialDate: DateTime(2026, 10, 14),
                currentDate: DateTime(2026, 10, 14),
                moods: {DateTime(2026, 10, 12): 0, DateTime(2026, 10, 13): 3},
              ),
            ),
          ),
        );
        expect(find.text('😊'), findsOneWidget);
        expect(find.text('😡'), findsOneWidget);
        expect(find.text('一'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('calendar-day-2026-10-15')));
        await tester.pumpAndSettle();
        expect(find.text('已选：2026年10月14日'), findsOneWidget);
        final next = tester.widget<IconButton>(
          find.byWidgetPredicate(
            (widget) => widget is IconButton && widget.tooltip == '下个月',
          ),
        );
        expect(next.onPressed, isNull);
        await tester.tap(find.byKey(const ValueKey('calendar-day-2026-10-12')));
        await tester.pumpAndSettle();
        expect(find.text('已选：2026年10月12日'), findsOneWidget);
        await tester.tap(find.byTooltip('上个月'));
        await tester.pumpAndSettle();
        expect(find.text('2026年9月'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('Calendar confirmation returns the selected date to the editor', (
    tester,
  ) async {
    DateTime? chosen;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              child: const Text('打开日历'),
              onPressed: () async {
                chosen = await showMoodCalendar(
                  context,
                  initialDate: DateTime(2026, 10, 1),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开日历'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('calendar-day-2026-10-02')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('确定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(chosen, DateTime(2026, 10, 2));
    expect(find.text('心情日历'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
