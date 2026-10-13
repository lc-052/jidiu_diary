import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/diary_entry.dart';
import '../state/diary_store.dart';
import '../widgets/weekly_mood_card.dart';
import '../widgets/diary_actions.dart';

const reflections = [
  '今天有什么小事，让你觉得生活还不错？',
  '如果给今天的自己写一句鼓励，你会说什么？',
  '今天学到的一件事是什么？',
  '有什么烦恼，可以暂时放一放？',
  '你想感谢今天遇见的哪个人？',
  '最近一次感到放松，是什么时候？',
  '明天，你想为自己做一件什么小事？',
];

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<DiaryStore>();
    final now = DateTime.now();
    final prompt =
        reflections[DateTime(
              now.year,
              now.month,
              now.day,
            ).difference(DateTime(2020)).inDays %
            reflections.length];
    final colors = Theme.of(context).colorScheme;
    final mood = store.moodOn(now);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surface,
            colors.primaryContainer.withValues(alpha: .45),
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Icon(Icons.send_rounded, color: colors.primary, size: 30),
              const SizedBox(width: 8),
              const Text(
                '寄丢日记',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${dateKey(now)} · 给今天留一个位置',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          const WeeklyMoodCard(),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '今日心情',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    mood == null
                        ? '今天的你，感觉怎么样？'
                        : '${mood.emoji} 今天感觉${mood.label}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: store.busy
                        ? null
                        : () => chooseMood(context, now),
                    child: Text(mood == null ? '记录心情' : '更新心情'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: colors.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '每日一想',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    prompt,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                  const SizedBox(height: 8),
                  const Text('不用寻找标准答案，记录真实的想法就好。'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => openEditor(context),
            icon: const Icon(Icons.edit_outlined),
            label: const Padding(
              padding: EdgeInsets.all(12),
              child: Text('写下今天'),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '已留下 ${store.entries.length} 篇日记 · ${store.moodCount} 天心情',
            ),
          ),
        ],
      ),
    );
  }
}
