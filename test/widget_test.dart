import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jidiu_diary/main.dart';
import 'package:jidiu_diary/state/diary_store.dart';

void main() {
  Future<DiaryStore> launch(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = DiaryStore(await SharedPreferences.getInstance())..load();
    await tester.pumpWidget(DiaryApp(store: store));
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('write, read, edit, search and delete a diary', (tester) async {
    final store = await launch(tester);
    await tester.tap(find.text('日记'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('新增日记'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('写下几句话，再保存吧'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), '测试标题');
    await tester.enterText(find.byType(TextField).at(1), '今天完成了日记功能。');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(store.entries.length, 1);
    await tester.tap(find.text('测试标题'));
    await tester.pumpAndSettle();
    expect(find.text('今天完成了日记功能。'), findsOneWidget);
    await tester.tap(find.byTooltip('编辑日记'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '修改标题');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('修改标题'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '不存在');
    await tester.pumpAndSettle();
    expect(find.text('没有找到符合条件的日记'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '修改');
    await tester.pumpAndSettle();
    await tester.tap(find.text('修改标题'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('删除日记'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(store.entries, isEmpty);
    expect(store.moodCount, 1);
  });

  testWidgets(
    'unsaved edits require confirmation and small screen remains usable',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await launch(tester);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('日记'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('新增日记'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), '未保存');
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('放弃未保存的修改？'), findsOneWidget);
      await tester.tap(find.text('继续编辑'));
      await tester.pumpAndSettle();
      expect(find.text('未保存'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
