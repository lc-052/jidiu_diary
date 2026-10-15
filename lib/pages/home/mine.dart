import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../constants/mood_artwork.dart';
import '../../diary/diary_controller.dart';
import '../../theme/feature_card_colors.dart';
import '../../widgets/data_backup_card.dart';

const _emojis = ['😊', '😌', '😨', '😡', '😐'];

class MinePage extends StatefulWidget {
  const MinePage({super.key});
  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  void _changeMonth(int offset) => setState(() {
    _month = DateTime(_month.year, _month.month + offset);
  });

  @override
  Widget build(BuildContext context) {
    final controller = DiaryScope.maybeOf(context);
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();
    bool inMonth(DateTime date) =>
        date.year == _month.year && date.month == _month.month;
    final entries = controller?.entries ?? <DiaryEntry>[];
    final daily = (controller?.dailyMoods ?? <DateTime, int>{}).entries
        .toList();
    final monthMoodDays = daily.where((entry) => inMonth(entry.key)).length;
    final counts = List.filled(5, 0);
    for (final entry in daily) {
      counts[entry.value]++;
    }
    final writing = List.filled(5, 0);
    var withoutMood = 0;
    for (final entry in entries) {
      if (entry.mood == null) {
        withoutMood++;
      } else {
        writing[entry.mood!]++;
      }
    }
    Text caption(String text) => Text(
      text,
      style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
    );
    return ListView(
      key: const PageStorageKey('mine-content'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        _Panel(
          panelKey: const ValueKey('mine-statistics-card'),
          children: [
            const _Heading(icon: Icons.insights_rounded, title: '我的记录'),
            const SizedBox(height: 8),
            caption('累计记录 · 每一份心情和故事，都在这里。'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _Metric(value: '${daily.length}', label: '累计心情 / 天'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Metric(value: '${entries.length}', label: '累计日记 / 篇'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('每日心情分布', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _Bars(
              values: counts,
              labels: MoodArtwork.labels,
              emojis: _emojis,
              unit: '天',
            ),
            if (daily.isEmpty) ...[
              const SizedBox(height: 10),
              caption('还没有每日心情，在「本周心情」留下一个吧。'),
            ],
            const SizedBox(height: 24),
            const Text('日记心情分布', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            caption('每篇日记独立统计 · 未选心情 $withoutMood 篇'),
            const SizedBox(height: 14),
            _Bars(
              values: writing,
              unit: '篇',
              labels: MoodArtwork.labels,
              emojis: _emojis,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Panel(
          panelKey: const ValueKey('mine-mood-calendar-card'),
          children: [
            const _Heading(icon: Icons.calendar_month_rounded, title: '心情日历'),
            const SizedBox(height: 8),
            caption('本月记录 $monthMoodDays 天 · 每一个表情，都是这一天的你'),
            if (controller != null &&
                !controller.ready &&
                controller.error == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller?.error != null) ...[
              const SizedBox(height: 20),
              Text(controller!.error!),
              TextButton(
                onPressed: controller.retryInitialization,
                child: const Text('重新加载'),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    tooltip: '日历上个月',
                    onPressed: _month.year > 1900 || _month.month > 1
                        ? () => _changeMonth(-1)
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      '${_month.year}年${_month.month}月',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    tooltip: '日历下个月',
                    onPressed: _month.isBefore(DateTime(now.year, now.month))
                        ? () => _changeMonth(1)
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _MoodMonthCalendar(
                month: _month,
                moods: controller?.dailyMoods ?? const {},
              ),
              const SizedBox(height: 12),
              caption('每日心情在「本周心情」中记录，今天以描边标记。'),
            ],
          ],
        ),
        const SizedBox(height: 16),
        const DataBackupCard(),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.panelKey, required this.children});
  final Key panelKey;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    key: panelKey,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) {
    final palette = FeatureCardColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: palette.accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: palette.secondary)),
        ],
      ),
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars({
    required this.values,
    required this.labels,
    required this.unit,
    this.emojis,
  });
  final List<int> values;
  final List<String> labels;
  final String unit;
  final List<String>? emojis;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxValue = math.max(1, values.reduce(math.max));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
            child: Semantics(
              label: '${labels[i]} ${values[i]}$unit',
              child: ExcludeSemantics(
                child: Column(
                  children: [
                    Text(
                      '${values[i]}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 56,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 22,
                          height: values[i] == 0
                              ? 3
                              : 8 + 48 * values[i] / maxValue,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                colors.primary.withValues(alpha: .45),
                                colors.primary,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (emojis != null) ...[
                      Text(emojis![i], style: const TextStyle(fontSize: 21)),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      labels[i],
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MoodMonthCalendar extends StatelessWidget {
  const _MoodMonthCalendar({required this.month, required this.moods});
  final DateTime month;
  final Map<DateTime, int> moods;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = FeatureCardColors.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final first = DateTime(month.year, month.month);
    final offset = first.weekday - 1;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final cells = ((offset + days) / 7).ceil() * 7;
    return Column(
      children: [
        Row(
          children: [
            for (final label in ['一', '二', '三', '四', '五', '六', '日'])
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 12, color: palette.secondary),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          key: const ValueKey('mine-month-grid'),
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 5,
            mainAxisSpacing: 6,
            mainAxisExtent: 58,
          ),
          itemCount: cells,
          itemBuilder: (context, index) {
            final day = index - offset + 1;
            if (day < 1 || day > days) return const SizedBox.shrink();
            final date = DateTime(month.year, month.month, day);
            final mood = moods[date];
            final future = date.isAfter(today);
            final isToday = date == today;
            return Semantics(
              label:
                  '${date.year}年${date.month}月${date.day}日，${future
                      ? '未来日期'
                      : mood == null
                      ? '未记录心情'
                      : MoodArtwork.labels[mood]}',
              child: ExcludeSemantics(
                child: Container(
                  key: ValueKey(
                    'mine-calendar-day-${date.toIso8601String().substring(0, 10)}',
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: future
                        ? palette.background.withValues(alpha: .35)
                        : palette.background,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday
                        ? Border.all(color: colors.primary, width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 11,
                          color: future
                              ? palette.secondary.withValues(alpha: .4)
                              : isToday
                              ? colors.primary
                              : palette.secondary,
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                      if (mood != null && !future)
                        Text(
                          _emojis[mood],
                          style: const TextStyle(fontSize: 22, height: 1.1),
                        )
                      else
                        Text(
                          '·',
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.1,
                            color: palette.secondary.withValues(
                              alpha: future ? .15 : .35,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
