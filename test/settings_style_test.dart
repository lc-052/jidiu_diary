import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jidiu_diary/pages/setting_page.dart';
import 'package:jidiu_diary/theme/app_theme.dart';
import 'package:jidiu_diary/theme/theme_controller.dart';
import 'package:jidiu_diary/widgets/app_background.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );
  for (final dark in [false, true]) {
    testWidgets(
      'Settings shares the home background on a small ${dark ? 'dark' : 'light'} screen',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = ThemeController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            home: SettingPage(themeController: controller),
          ),
        );
        expect(find.byType(AppBackground), findsOneWidget);
        expect(
          tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
          Colors.transparent,
        );
        expect(find.text('外观设置'), findsOneWidget);
        expect(find.text('跟随系统'), findsOneWidget);
        expect(find.text('浅色模式'), findsOneWidget);
        expect(find.text('深色模式'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
