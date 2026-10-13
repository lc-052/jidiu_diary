import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/diary_entry.dart';
import '../state/diary_store.dart';
import 'diary_actions.dart';

class WeeklyMoodCard extends StatefulWidget {
  const WeeklyMoodCard({super.key});
  @override
  State<WeeklyMoodCard> createState() => _WeeklyMoodCardState();
}

class _WeeklyMoodCardState extends State<WeeklyMoodCard> {
  DateTime _selected = DateTime.now();
  @override
  Widget build(BuildContext context) {
    final store = context.watch<DiaryStore>();
    final colors = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final start = DateTime(
      _selected.year,
      _selected.month,
      _selected.day,
    ).subtract(Duration(days: _selected.weekday - 1));
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '本周心情',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selected,
                      firstDate: DateTime(2000),
                      lastDate: today,
                    );
                    if (date != null && mounted) {
                      setState(() => _selected = date);
                    }
                  },
                  child: Text('${_selected.year}年${_selected.month}月 ▾'),
                ),
              ],
            ),
            const Text('在平凡的日子里，也要好好照顾自己'),
            const SizedBox(height: 16),
            Row(
              children: List.generate(7, (index) {
                final date = start.add(Duration(days: index));
                final selected = dateKey(date) == dateKey(_selected);
                final mood = store.moodOn(date);
                final future = dateKey(date).compareTo(dateKey(today)) > 0;
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: future || store.busy
                        ? null
                        : () {
                            setState(() => _selected = date);
                            chooseMood(context, date);
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? colors.primaryContainer : null,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Text(
                            mood?.emoji ?? '○',
                            style: TextStyle(
                              fontSize: 24,
                              color: future
                                  ? colors.outlineVariant
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(['一', '二', '三', '四', '五', '六', '日'][index]),
                          Text(
                            '${date.day}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text('点击日期记录心情', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
