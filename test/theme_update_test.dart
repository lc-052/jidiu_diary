import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jidiu_diary/constants/app_colors.dart';
import 'package:jidiu_diary/diary/diary_controller.dart';
import 'package:jidiu_diary/pages/home/index.dart';
import 'package:jidiu_diary/pages/diary/diary_editor.dart';
import 'package:jidiu_diary/theme/app_theme.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  testWidgets(
    'Warm theme reaches navigation and open editor controls after rebuilds and mode changes',
    (tester) async {
      final mode = ValueNotifier(ThemeMode.light);
      final diary = DiaryController();
      await tester.runAsync(() async {
        await diary.initialize(
          database: await newDatabaseFactoryMemory().openDatabase(
            'theme_update',
          ),
        );
      });
      addTearDown(mode.dispose);
      addTearDown(diary.dispose);
      await tester.pumpWidget(
        DiaryScope(
          controller: diary,
          child: ValueListenableBuilder(
            valueListenable: mode,
            builder: (context, value, _) => MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: value,
              home: const HomePage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final navigationIcon = tester.widget<Image>(
        find.image(const AssetImage('lib/assets/today-selected.png')),
      );
      expect(navigationIcon.color, AppLightColors.primary);
      await tester.ensureVisible(find.text('写下今天'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('写下今天'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('diary-body')),
        '切换主题后保留内容',
      );
      for (final dark in [false, true, false]) {
        mode.value = dark ? ThemeMode.dark : ThemeMode.light;
        final reassembly = tester.binding.reassembleApplication();
        await tester.pump();
        await reassembly;
        await tester.pumpAndSettle();
        final primary = dark ? AppDarkColors.primary : AppLightColors.primary;
        final imageLabel = tester.element(find.text('插入图片'));
        expect(DefaultTextStyle.of(imageLabel).style.color, primary);
        final calendarIcon = tester.element(
          find.byIcon(Icons.calendar_today_outlined),
        );
        expect(IconTheme.of(calendarIcon).color, primary);
        final saveButton = find.widgetWithText(FilledButton, '保存');
        final material = tester.widget<Material>(
          find
              .descendant(of: saveButton, matching: find.byType(Material))
              .first,
        );
        expect(material.color, primary);
        expect(find.byType(DiaryEditor), findsOneWidget);
        expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey('diary-body')))
              .controller!
              .text,
          '切换主题后保留内容',
        );
      }
      await tester.tap(find.byTooltip('返回并保留草稿'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(diary.drafts.single.body, '切换主题后保留内容');
      expect(tester.takeException(), isNull);
    },
  );
}
