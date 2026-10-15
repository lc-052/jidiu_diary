import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jidiu_diary/pages/home/diary.dart';
import 'package:jidiu_diary/pages/home/index.dart';
import 'package:jidiu_diary/theme/app_theme.dart';
import 'package:jidiu_diary/widgets/week_mood_card.dart';

void main() {
  testWidgets(
    'The entire card moves down, swaps out of view, and returns with state preserved',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const HomePage()),
      );
      await tester.pumpAndSettle();
      final header = find.byType(WeekMoodCard);
      final headerState = tester.state(header);
      final headerRect = tester.getRect(header);
      final navigationRect = tester.getRect(find.byType(NavigationBar));
      final card = find.byKey(const ValueKey('home-content-card'));
      final originalCardTop = tester.getTopLeft(card).dy;
      final diaryState = tester.state(
        find.byType(DiaryPage, skipOffstage: false),
      );
      await tester.tap(find.text('日记'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final transition = tester.widget<Transform>(
        find.byKey(const ValueKey('home-content-transition')),
      );
      expect(transition.transform.storage[12], 0);
      expect(transition.transform.storage[13], greaterThan(0));
      expect(tester.getTopLeft(card).dy, greaterThan(originalCardTop));
      expect(find.text('今日心情'), findsOneWidget);
      expect(tester.getRect(header), headerRect);
      expect(tester.getRect(find.byType(NavigationBar)), navigationRect);
      await tester.pump(const Duration(milliseconds: 110));
      expect(find.text('今日心情'), findsOneWidget);
      expect(
        tester.getTopLeft(card).dy,
        greaterThanOrEqualTo(navigationRect.top),
      );
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('我的日记'), findsOneWidget);
      expect(
        tester.getTopLeft(card).dy,
        greaterThanOrEqualTo(navigationRect.top),
      );
      expect(tester.getRect(header), headerRect);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getTopLeft(card).dy, lessThan(navigationRect.top));
      expect(tester.getTopLeft(card).dy, greaterThan(originalCardTop));
      await tester.pumpAndSettle();
      expect(find.text('我的日记'), findsOneWidget);
      expect(tester.state(header), same(headerState));
      await tester.enterText(
        find.byKey(const ValueKey('diary-search')),
        '还未写完的搜索',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('今天'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('日记'));
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(DiaryPage)), same(diaryState));
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('diary-search')))
            .controller!
            .text,
        '还未写完的搜索',
      );
      for (final label in ['今天', '日记', '今天', '日记']) {
        await tester.tap(find.text(label));
        await tester.pump(const Duration(milliseconds: 25));
      }
      await tester.pumpAndSettle();
      expect(find.text('我的日记'), findsOneWidget);
      expect(
        tester
            .widget<Transform>(
              find.byKey(const ValueKey('home-content-transition')),
            )
            .transform
            .storage[13],
        0,
      );
      expect(tester.state(header), same(headerState));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Reduced motion changes the card immediately', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const HomePage(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('日记'));
    await tester.pump();
    expect(find.text('我的日记'), findsOneWidget);
    expect(
      tester
          .widget<Transform>(
            find.byKey(const ValueKey('home-content-transition')),
          )
          .transform
          .storage[13],
      0,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
