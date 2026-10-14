import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jidiu_diary/pages/home/index.dart';
import 'package:jidiu_diary/theme/app_theme.dart';
import 'package:jidiu_diary/widgets/home_app_bar.dart';

void main() {
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
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 2);
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
