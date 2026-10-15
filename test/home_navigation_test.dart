import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jidiu_diary/pages/home/index.dart';
import 'package:jidiu_diary/theme/app_theme.dart';
import 'package:jidiu_diary/widgets/home_app_bar.dart';
import 'package:jidiu_diary/widgets/week_mood_card.dart';
import 'package:jidiu_diary/constants/mood_artwork.dart';
import 'package:jidiu_diary/pages/home/today.dart';
import 'package:jidiu_diary/pages/home/diary.dart';

void main() {
  testWidgets('The white card wraps only the current page content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const HomePage()),
    );
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('home-content-card'));
    final todayHeight = tester.getSize(card).height;
    expect(
      todayHeight,
      closeTo(tester.getSize(find.byType(TodayPage)).height + 16, 1),
    );
    expect(todayHeight, lessThan(600));
    await tester.tap(find.text('日记'));
    await tester.pumpAndSettle();
    final diaryHeight = tester.getSize(card).height;
    expect(
      diaryHeight,
      closeTo(tester.getSize(find.byType(DiaryPage)).height + 16, 1),
    );
    expect(diaryHeight, isNot(closeTo(todayHeight, 1)));
    expect(tester.takeException(), isNull);
  });
  testWidgets('Today artwork follows all five moods and ignores other dates', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const HomePage()),
    );
    await tester.pumpAndSettle();
    expect(find.text('选一个今天的心情'), findsOneWidget);
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    const emojis = ['😊', '😌', '😨', '😡', '😐'];
    final weekday = DateTime.now().weekday;
    for (var index = 0; index < emojis.length; index++) {
      await tester.tap(find.text(weekdays[weekday - 1]));
      await tester.pumpAndSettle();
      await tester.tap(find.text(emojis[index]));
      await tester.pumpAndSettle();
      final artwork = tester.widget<Image>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.semanticLabel == MoodArtwork.labels[index],
        ),
      );
      expect(
        ((artwork.image as ResizeImage).imageProvider as AssetImage).assetName,
        MoodArtwork.assets[index],
      );
    }
    await tester.tap(find.text(weekdays[weekday > 1 ? weekday - 2 : 1]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('今天'));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.semanticLabel == '一般',
      ),
      weekday > 1 ? findsNothing : findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.semanticLabel == '开心',
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('The toolbar stays pinned while the weekly mood scrolls away', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const HomePage()),
    );
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('home-content-card'));
    final initialTop = tester.getTopLeft(card).dy;
    final moodState = tester.state(find.byType(WeekMoodCard));
    final toolbar = find.byType(HomeAppBar);
    final toolbarTop = tester.getTopLeft(toolbar).dy;
    await tester.drag(find.text('今日心情'), const Offset(0, -650));
    await tester.pumpAndSettle();
    final pinnedTop = tester.getTopLeft(card).dy;
    expect(pinnedTop, lessThan(initialTop));
    // The measured container includes its eight-pixel internal margin.
    expect(pinnedTop, closeTo(64, 1));
    expect(tester.getTopLeft(toolbar).dy, closeTo(toolbarTop, 1));
    expect(find.byTooltip('音乐').hitTestable(), findsOneWidget);
    expect(find.byTooltip('设置').hitTestable(), findsOneWidget);
    await tester.drag(find.text('今日心情'), const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(card).dy, closeTo(pinnedTop, 1));
    await tester.tap(find.text('日记'));
    await tester.pumpAndSettle();
    expect(find.text('还没有日记'), findsOneWidget);
    expect(find.byType(HomeAppBar, skipOffstage: false), findsOneWidget);
    expect(
      tester.state(find.byType(WeekMoodCard, skipOffstage: false)),
      same(moodState),
    );
    expect(card, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Navigation icons are bundled and switch with the pages', (
    tester,
  ) async {
    for (final name in ['today', 'diary', 'profile']) {
      for (final state in ['selected', 'unselected']) {
        final asset = await rootBundle.load('lib/assets/$name-$state.png');
        expect(asset.lengthInBytes, greaterThan(0));
      }
    }

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const HomePage()),
    );
    await tester.pumpAndSettle();
    expect(
      find.image(const AssetImage('lib/assets/today-selected.png')),
      findsOneWidget,
    );
    await tester.tap(find.text('日记'));
    await tester.pumpAndSettle();
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 1);
    expect(
      find.image(const AssetImage('lib/assets/diary-selected.png')),
      findsOneWidget,
    );
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    expect(find.text('我的记录'), findsOneWidget);
    expect(find.byType(WeekMoodCard), findsNothing);
    expect(
      find.image(const AssetImage('lib/assets/profile-selected.png')),
      findsOneWidget,
    );
    await tester.tap(find.text('今天'));
    await tester.pumpAndSettle();
    expect(find.text('本周心情'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Floating navigation fits a small phone in dark mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 32, bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.darkTheme, home: const HomePage()),
    );
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byType(NavigationBar));
    expect(rect.left, greaterThan(0));
    expect(rect.right, lessThan(320));
    expect(rect.bottom, lessThanOrEqualTo(616));
    final musicRect = tester.getRect(find.byTooltip('音乐'));
    expect(musicRect.top, greaterThanOrEqualTo(32));
    expect(musicRect.width, greaterThanOrEqualTo(48));
    await tester.tap(find.byTooltip('音乐'));
    await tester.pumpAndSettle();
    expect(find.text('音乐小憩'), findsOneWidget);
    final panelRect = tester.getRect(find.text('音乐小憩'));
    expect(panelRect.top, greaterThan(musicRect.bottom));
    expect(panelRect.right, lessThan(320));
    await tester.tap(find.byTooltip('音乐'));
    await tester.pumpAndSettle();
    expect(find.text('今日心情'), findsOneWidget);
    expect(find.text('今日塔罗'), findsOneWidget);
    await tester.ensureVisible(find.text('写下今天'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('写下今天'));
    await tester.pumpAndSettle();
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 1);
    expect(find.text('还没有日记'), findsOneWidget);
    await tester.tap(find.text('今天'));
    await tester.pumpAndSettle();
    expect(find.text('今日心情'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Music opens a dismissible popup and settings still navigates', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const HomePage(),
        routes: {
          '/music': (_) => const Scaffold(body: Text('Music destination')),
          '/setting': (_) => const Scaffold(body: Text('Settings destination')),
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('音乐'));
    await tester.pumpAndSettle();
    expect(find.text('Music destination'), findsNothing);
    expect(find.text('音乐小憩'), findsOneWidget);
    expect(find.text('本周心情'), findsOneWidget);
    await tester.tap(find.text('暂无音乐'));
    await tester.pumpAndSettle();
    expect(find.text('音乐小憩'), findsOneWidget);
    await tester.tap(find.text('本周心情'));
    await tester.pumpAndSettle();
    expect(find.text('音乐小憩'), findsNothing);
    await tester.tap(find.byTooltip('音乐'));
    await tester.pumpAndSettle();
    expect(find.text('音乐小憩'), findsOneWidget);
    await tester.tap(find.byTooltip('音乐'));
    await tester.pumpAndSettle();
    expect(find.text('音乐小憩'), findsNothing);
    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
    expect(find.text('Settings destination'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.byType(HomeAppBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
