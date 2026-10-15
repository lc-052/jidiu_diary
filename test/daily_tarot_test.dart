import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jidiu_diary/tarot/daily_tarot_controller.dart';
import 'package:jidiu_diary/tarot/tarot_deck.dart';
import 'package:jidiu_diary/theme/app_theme.dart';
import 'package:jidiu_diary/widgets/today_tarot_card.dart';

class _ChosenCardRandom implements Random {
  _ChosenCardRandom(this.index);
  final int index;
  int calls = 0;
  @override
  int nextInt(int max) {
    expect(max, TarotDeck.cards.length);
    calls++;
    return index;
  }

  @override
  bool nextBool() => throw UnimplementedError();
  @override
  double nextDouble() => throw UnimplementedError();
}

void main() {
  testWidgets(
    'Selected historical dates show their own records or an empty state without permitting a draw',
    (tester) async {
      final yesterday = DateTime(2026, 10, 14);
      final emptyDay = DateTime(2026, 10, 13);
      final selection = ValueNotifier<DateTime?>(null);
      final storage = <String, String>{
        'tarot_daily_2026-10-14': jsonEncode({
          'date': '2026-10-14',
          'card': TarotDeck.cards.first.id,
        }),
      };
      final controller = DailyTarotController(
        read: (key) async => storage[key],
        write: (key, value) async {
          storage[key] = value;
        },
        clock: () => DateTime(2026, 10, 15),
        random: _ChosenCardRandom(77),
      );
      addTearDown(controller.dispose);
      addTearDown(selection.dispose);
      await controller.draw();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 180,
                child: ValueListenableBuilder(
                  valueListenable: selection,
                  builder: (context, date, _) => TodayTarotCard(
                    controller: controller,
                    selectedDate: date,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(TarotDeck.cards.last.name), findsOneWidget);
      selection.value = yesterday;
      await tester.pumpAndSettle();
      expect(find.text('当日塔罗'), findsOneWidget);
      expect(find.text(TarotDeck.cards.first.name), findsOneWidget);
      expect(find.text(TarotDeck.cards.last.name), findsNothing);
      await tester.tap(find.byKey(const ValueKey('today-tarot-button')));
      await tester.pumpAndSettle();
      expect(find.text('2026年10月14日'), findsOneWidget);
      expect(find.text(TarotDeck.cards.first.guidance), findsOneWidget);
      expect(find.byKey(const ValueKey('draw-daily-tarot')), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      selection.value = emptyDay;
      await tester.pumpAndSettle();
      expect(find.text('当天未抽牌'), findsOneWidget);
      expect(find.text(TarotDeck.cards.last.name), findsNothing);
      await tester.tap(find.byKey(const ValueKey('today-tarot-button')));
      await tester.pumpAndSettle();
      expect(find.text('2026年10月13日'), findsOneWidget);
      expect(find.text('当天未抽牌'), findsOneWidget);
      expect(find.byKey(const ValueKey('draw-daily-tarot')), findsNothing);
      expect(storage.length, 2);
      await tester.pageBack();
      await tester.pumpAndSettle();
      selection.value = yesterday;
      await tester.pump();
      selection.value = null;
      await tester.pumpAndSettle();
      expect(find.text('今日塔罗'), findsOneWidget);
      expect(find.text(TarotDeck.cards.last.name), findsOneWidget);
      expect(controller.today!.card.id, TarotDeck.cards.last.id);
      expect(tester.takeException(), isNull);
    },
  );
  test('Different users draw independently on the same date and retain only their own result', () async {
    final firstStore = <String, String>{};
    final secondStore = <String, String>{};
    final firstRandom = _ChosenCardRandom(0);
    final secondRandom = _ChosenCardRandom(77);
    DailyTarotController user(Map<String, String> store, Random random) =>
        DailyTarotController(
          read: (key) async => store[key],
          write: (key, value) async {
            store[key] = value;
          },
          clock: () => DateTime(2026, 10, 15),
          random: random,
        );
    final first = user(firstStore, firstRandom);
    final second = user(secondStore, secondRandom);
    final results = await Future.wait([first.draw(), second.draw()]);
    expect(results.first!.date, results.last!.date);
    expect(results.first!.card.id, TarotDeck.cards.first.id);
    expect(results.last!.card.id, TarotDeck.cards.last.id);
    expect(results.first!.card.id, isNot(results.last!.card.id));
    expect((await first.draw())!.card.id, results.first!.card.id);
    expect((await second.draw())!.card.id, results.last!.card.id);
    expect(firstRandom.calls, 1);
    expect(secondRandom.calls, 1);
    first.dispose();
    second.dispose();
  });
  test('Daily cards persist across reopening and concurrent draws, and reset on a new day', () async {
    var now = DateTime(2026, 10, 15, 23, 59);
    final storage = <String, String>{};
    var writes = 0;
    DailyTarotController create() => DailyTarotController(
      read: (key) async => storage[key],
      write: (key, value) async {
        storage[key] = value;
        writes++;
      },
      clock: () => now,
      random: Random(7),
    );
    final first = create();
    await first.load();
    expect(first.today, isNull);
    final draws = await Future.wait([first.draw(), first.draw()]);
    expect(draws.first!.card.id, draws.last!.card.id);
    expect(writes, 1);
    final second = create();
    await second.load();
    expect(second.today!.card.id, first.today!.card.id);
    final original = first.today!;
    now = DateTime(2026, 10, 16);
    expect(second.today, isNull);
    final next = await second.draw();
    expect(next!.date, '2026-10-16');
    expect(writes, 2);
    now = DateTime(2026, 10, 15);
    expect((await second.draw())!.card.id, original.card.id);
    expect(writes, 2);
    first.dispose();
    second.dispose();
  });

  test(
    'Failed persistence does not reveal a card; retry can save it',
    () async {
      var fail = true;
      final storage = <String, String>{};
      final controller = DailyTarotController(
        read: (key) async => storage[key],
        write: (key, value) async {
          if (fail) throw StateError('Unavailable');
          storage[key] = value;
        },
        random: Random(2),
      );
      expect(await controller.draw(), isNull);
      expect(controller.error, isNotNull);
      expect(controller.today, isNull);
      fail = false;
      expect(await controller.draw(), isNotNull);
      expect(controller.error, isNull);
      controller.dispose();
    },
  );

  testWidgets(
    'All 78 unique tarot cards match bundled art and have individual readings',
    (tester) async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final images = manifest
          .listAssets()
          .where((name) => name.startsWith('lib/assets/tarot_webp/'))
          .toSet();
      expect(
        manifest.listAssets().any(
          (name) => name.startsWith('lib/assets/Tarot Deck/'),
        ),
        isFalse,
        reason: 'Original PNG artwork must not inflate the app bundle',
      );
      expect(TarotDeck.cards.length, 78);
      expect(TarotDeck.cards.map((card) => card.id).toSet().length, 78);
      expect(TarotDeck.cards.map((card) => card.asset).toSet(), images);
      expect(
        TarotDeck.cards.every(
          (card) =>
              card.name.isNotEmpty &&
              card.guidance.isNotEmpty &&
              card.prompt.isNotEmpty,
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'The tarot tile opens a card, saves the draw and shows the same reading on reopening',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final storage = <String, String>{};
      final controller = DailyTarotController(
        read: (key) async => storage[key],
        write: (key, value) async => storage[key] = value,
        random: Random(5),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 160,
                child: TodayTarotCard(controller: controller),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('today-tarot-button')));
      await tester.pumpAndSettle();
      final drawButton = find.byKey(const ValueKey('draw-daily-tarot'));
      await tester.ensureVisible(drawButton);
      await tester.pumpAndSettle();
      await tester.tap(drawButton);
      await tester.pumpAndSettle();
      final selected = controller.today!.card;
      expect(storage.length, 1);
      expect(find.text(selected.name), findsOneWidget);
      expect(find.text(selected.guidance), findsOneWidget);
      expect(find.text(selected.prompt), findsOneWidget);
      expect(drawButton, findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('查看今日解读'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('today-tarot-button')));
      await tester.pumpAndSettle();
      expect(find.text(selected.name), findsOneWidget);
      expect(controller.today!.card.id, selected.id);
      expect(drawButton, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
