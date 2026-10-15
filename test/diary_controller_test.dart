import 'package:flutter_test/flutter_test.dart';
import 'package:jidiu_diary/diary/diary_controller.dart';
import 'package:sembast/sembast_memory.dart';

DiaryEntry makeEntry(
  String id, {
  String title = '',
  String body = '今天散步，看见一朵花。',
  int? mood = 0,
  DateTime? date,
  int hour = 12,
}) => DiaryEntry(
  id: id,
  date: date ?? DateTime(2026, 10, 14),
  title: title,
  body: body,
  mood: mood,
  createdAt: DateTime(2026, 10, 14, hour),
  updatedAt: DateTime(2026, 10, 14, hour),
);

void main() {
  test('Daily moods persist independently from all diary moods', () async {
    final diary = DiaryController();
    final factory = newDatabaseFactoryMemory();
    await diary.initialize(
      database: await factory.openDatabase('calendar_moods'),
    );
    await diary.publish(makeEntry('early', mood: 0, hour: 8));
    await diary.publish(makeEntry('late', mood: 3, hour: 20));
    await diary.publish(makeEntry('no_mood', mood: null, hour: 22));
    expect(diary.dailyMoods, isEmpty);
    await diary.setDailyMood(DateTime(2026, 10, 14), 1);
    expect(diary.entry('late')!.mood, 3);
    await diary.delete('late');
    expect(diary.dailyMoods[DateTime(2026, 10, 14)], 1);
    diary.dispose();
    await Future<void>.delayed(Duration.zero);
    final restored = DiaryController();
    await restored.initialize(
      database: await factory.openDatabase('calendar_moods'),
    );
    expect(restored.dailyMoods[DateTime(2026, 10, 14)], 1);
    expect(restored.entry('early')!.mood, 0);
    restored.dispose();
  });
  test(
    'Initialization runs once and can retry after storage failure',
    () async {
      final factory = newDatabaseFactoryMemory();
      var attempts = 0;
      final diary = DiaryController(
        databaseOpener: () async {
          attempts++;
          if (attempts == 1) throw StateError('Temporary database failure');
          return factory.openDatabase('retry');
        },
      );
      await Future.wait([diary.initialize(), diary.initialize()]);
      expect(attempts, 1);
      expect(diary.ready, isFalse);
      expect(diary.error, isNotNull);
      await diary.retryInitialization();
      expect(attempts, 2);
      expect(diary.ready, isTrue);
      expect(diary.error, isNull);
      await diary.publish(makeEntry('first'));
      expect(diary.entries.length, 1);
      diary.dispose();
    },
  );
  test(
    'Multiple entries per day persist and sort by date and creation time',
    () async {
      final factory = newDatabaseFactoryMemory();
      final diary = DiaryController();
      await diary.initialize(database: await factory.openDatabase('multi'));
      await diary.publish(makeEntry('morning', hour: 8));
      await diary.publish(makeEntry('evening', title: '晚饭', hour: 20));
      await diary.publish(makeEntry('past', date: DateTime(2025, 1, 1)));
      expect(diary.entries.map((entry) => entry.id), [
        'evening',
        'morning',
        'past',
      ]);
      expect(diary.entry('morning')!.displayTitle, '10月14日的日记');
      diary.dispose();
      await Future<void>.delayed(Duration.zero);
      final restored = DiaryController();
      await restored.initialize(database: await factory.openDatabase('multi'));
      expect(restored.entries.length, 3);
      expect(restored.entry('evening')!.mood, 0);
      restored.dispose();
    },
  );

  test(
    'Draft edits never overwrite published content and survive reopening',
    () async {
      final factory = newDatabaseFactoryMemory();
      final diary = DiaryController();
      await diary.initialize(database: await factory.openDatabase('draft'));
      await diary.publish(makeEntry('one', body: '正式内容'));
      await diary.saveDraft(makeEntry('one', body: '还没写完的修改'));
      expect(diary.entry('one')!.body, '正式内容');
      diary.dispose();
      await Future<void>.delayed(Duration.zero);
      final restored = DiaryController();
      await restored.initialize(database: await factory.openDatabase('draft'));
      expect(restored.draft('one')!.body, '还没写完的修改');
      await restored.publish(makeEntry('one', body: '修改完成'));
      expect(restored.entries.length, 1);
      expect(restored.entry('one')!.body, '修改完成');
      expect(restored.drafts, isEmpty);
      restored.dispose();
    },
  );

  test(
    'Search matches titles, body and dates; deleting only affects one entry',
    () async {
      final diary = DiaryController();
      await diary.initialize(
        database: await newDatabaseFactoryMemory().openDatabase('search'),
      );
      await diary.publish(makeEntry('a', title: '旅行', body: '海边很安静'));
      await diary.publish(makeEntry('b', title: 'Work', body: '完成了一件小事'));
      expect(diary.search('旅行').single.id, 'a');
      expect(diary.search('海边').single.id, 'a');
      expect(diary.search('work').single.id, 'b');
      expect(diary.search('2026年10月14日').length, 2);
      await diary.saveDraft(makeEntry('a', body: '草稿'));
      await diary.delete('a');
      expect(diary.entry('a'), isNull);
      expect(diary.draft('a'), isNull);
      expect(diary.entry('b'), isNotNull);
      diary.dispose();
    },
  );

  test(
    'Queued draft writes followed by publish leave no stale draft',
    () async {
      final diary = DiaryController();
      await diary.initialize(
        database: await newDatabaseFactoryMemory().openDatabase('queue'),
      );
      await Future.wait([
        diary.saveDraft(makeEntry('a', body: '第一版')),
        diary.saveDraft(makeEntry('a', body: '第二版')),
        diary.publish(makeEntry('a', body: '最终版')),
      ]);
      expect(diary.entry('a')!.body, '最终版');
      expect(diary.drafts, isEmpty);
      await expectLater(
        diary.publish(makeEntry('empty', body: '  ')),
        throwsFormatException,
      );
      expect(diary.entry('empty'), isNull);
      diary.dispose();
    },
  );
}
