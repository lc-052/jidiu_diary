import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jidiu_diary/music/music_controller.dart';
import 'package:jidiu_diary/pages/home/index.dart';
import 'package:jidiu_diary/theme/app_theme.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  testWidgets(
    'The default BGM appears in the popup and remains after dismissal',
    (tester) async {
      final music = MusicController();
      await tester.runAsync(() async {
        await music.initialize(
          database: await newDatabaseFactoryMemory().openDatabase(
            'default_popup',
          ),
        );
      });
      addTearDown(music.dispose);
      await tester.pumpWidget(
        MusicScope(
          controller: music,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomePage(),
          ),
        ),
      );
      await tester.tap(find.byTooltip('音乐'));
      await tester.pumpAndSettle();
      expect(find.text(music.current!.name), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Image && widget.image is MemoryImage,
        ),
        findsOneWidget,
      );
      final play = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.play_arrow_rounded),
      );
      expect(play.onPressed, isNotNull);
      await tester.tap(find.text('本周心情'));
      await tester.pumpAndSettle();
      expect(find.text('音乐小憩'), findsNothing);
      expect(music.current, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );
}
