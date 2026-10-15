import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jidiu_diary/constants/mood_artwork.dart';
import 'package:jidiu_diary/music/music_controller.dart';
import 'package:jidiu_diary/theme/app_theme.dart';
import 'package:jidiu_diary/widgets/today_feature_cards.dart';

class _PlaybackMusic extends MusicController {
  void setPlaying(bool value) {
    playing = value;
    notifyListeners();
  }
}

void main() {
  testWidgets(
    'Mood characters follow playback for all moods and selected dates',
    (tester) async {
      final music = _PlaybackMusic();
      final mood = ValueNotifier<int?>(null);
      addTearDown(music.dispose);
      addTearDown(mood.dispose);
      final yesterday = DateUtils.dateOnly(DateTime.now())
          .subtract(const Duration(days: 1));
      await tester.pumpWidget(
        MusicScope(
          controller: music,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: ValueListenableBuilder<int?>(
                  valueListenable: mood,
                  builder: (context, value, child) => TodayFeatureCards(
                    todayMood: value,
                    selectedDate: yesterday,
                    onOpenDiary: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      music.setPlaying(true);
      await tester.pumpAndSettle();
      expect(find.text('当天还没有记录心情'), findsOneWidget);

      String displayedAsset(int index) {
        final artwork = tester.widget<Image>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Image &&
                widget.semanticLabel == MoodArtwork.labels[index],
          ),
        );
        return ((artwork.image as ResizeImage).imageProvider as AssetImage)
            .assetName;
      }

      for (var index = 0; index < MoodArtwork.assets.length; index++) {
        mood.value = index;
        await tester.pumpAndSettle();
        expect(displayedAsset(index), MoodArtwork.headphonesAssets[index]);
        music.setPlaying(false);
        await tester.pumpAndSettle();
        expect(displayedAsset(index), MoodArtwork.assets[index]);
        music.setPlaying(true);
        await tester.pumpAndSettle();
        expect(displayedAsset(index), MoodArtwork.headphonesAssets[index]);
        expect(find.text('当日心情'), findsOneWidget);
        expect(
          find.text('${yesterday.month}月${yesterday.day}日'),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
