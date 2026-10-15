import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/mood_artwork.dart';

Future<DateTime?> showMoodCalendar(
  BuildContext context, {
  required DateTime initialDate,
  Map<DateTime, int> moods = const {},
  DateTime? currentDate,
}) => showDialog<DateTime>(
  context: context,
  builder: (_) => MoodCalendar(
    initialDate: initialDate,
    moods: moods,
    currentDate: currentDate,
  ),
);

class MoodCalendar extends StatefulWidget {
  const MoodCalendar({
    super.key,
    required this.initialDate,
    this.moods = const {},
    this.currentDate,
  });
  final DateTime initialDate;
  final Map<DateTime, int> moods;
  final DateTime? currentDate;
  @override
  State<MoodCalendar> createState() => _MoodCalendarState();
}

class _MoodCalendarState extends State<MoodCalendar> {
  late final DateTime _today;
  late DateTime _selected;
  late DateTime _month;
  @override
  void initState() {
    super.initState();
    final now = widget.currentDate ?? DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    final initial = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _selected = initial.isAfter(_today)
        ? _today
        : initial.isBefore(DateTime(1900))
        ? DateTime(1900)
        : initial;
    _month = DateTime(_selected.year, _selected.month);
  }

  Future<void> _chooseMonth() async {
    var year = _month.year;
    var month = _month.month;
    final chosen = await showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('选择年月'),
          content: Row(
            children: [
              Expanded(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: year,
                  items: List.generate(
                    _today.year - 1899,
                    (i) => DropdownMenuItem(
                      value: 1900 + i,
                      child: Text('${1900 + i}年'),
                    ),
                  ),
                  onChanged: (value) => setLocalState(() {
                    year = value!;
                    if (year == _today.year) {
                      month = math.min(month, _today.month);
                    }
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: month,
                  items: List.generate(
                    year == _today.year ? _today.month : 12,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('${i + 1}月'),
                    ),
                  ),
                  onChanged: (value) => setLocalState(() => month = value!),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, DateTime(year, month)),
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
    if (chosen != null && mounted) setState(() => _month = chosen);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final firstOffset = _month.weekday - 1;
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final count = ((firstOffset + days) / 7).ceil() * 7;
    final canPrevious = _month.isAfter(DateTime(1900));
    final canNext = _month.isBefore(DateTime(_today.year, _today.month));
    return Dialog(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: colors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '心情日历',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '关闭日历',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '选择日期，回看每一天的小心情',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _chooseMonth,
                        icon: const Icon(Icons.expand_more_rounded, size: 18),
                        label: Text(
                          '${_month.year}年${_month.month}月',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '上个月',
                      onPressed: canPrevious
                          ? () => setState(
                              () => _month = DateTime(
                                _month.year,
                                _month.month - 1,
                              ),
                            )
                          : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    IconButton(
                      tooltip: '下个月',
                      onPressed: canNext
                          ? () => setState(
                              () => _month = DateTime(
                                _month.year,
                                _month.month + 1,
                              ),
                            )
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: ['一', '二', '三', '四', '五', '六', '日']
                      .map(
                        (day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: count,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisExtent: 58,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 4,
                  ),
                  itemBuilder: (context, index) {
                    final day = index - firstOffset + 1;
                    if (day < 1 || day > days) return const SizedBox.shrink();
                    final date = DateTime(_month.year, _month.month, day);
                    final future = date.isAfter(_today);
                    final selected = date == _selected;
                    final today = date == _today;
                    final mood = widget.moods[date];
                    return Semantics(
                      button: true,
                      selected: selected,
                      enabled: !future,
                      label:
                          '${date.year}年${date.month}月${date.day}日${mood == null ? '' : '，${MoodArtwork.labels[mood]}'}',
                      child: Material(
                        color: colors.primary.withValues(
                          alpha: selected
                              ? 0.16
                              : future
                              ? 0.02
                              : 0.06,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: selected
                                ? colors.primary
                                : today
                                ? colors.primary.withValues(alpha: 0.4)
                                : Colors.transparent,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: ValueKey(
                            'calendar-day-${date.toIso8601String().substring(0, 10)}',
                          ),
                          onTap: future
                              ? null
                              : () => setState(() => _selected = date),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$day',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: future
                                        ? colors.onSurfaceVariant.withValues(
                                            alpha: 0.3,
                                          )
                                        : selected
                                        ? colors.primary
                                        : colors.onSurface,
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: mood == null || future
                                        ? today
                                              ? Container(
                                                  width: 4,
                                                  height: 4,
                                                  decoration: BoxDecoration(
                                                    color: colors.primary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                )
                                              : const SizedBox.shrink()
                                        : Text(
                                            [
                                              '😊',
                                              '😌',
                                              '😨',
                                              '😡',
                                              '😐',
                                            ][mood],
                                            style: const TextStyle(
                                              fontSize: 22,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  '已选：${_selected.year}年${_selected.month}月${_selected.day}日',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        _selected = _today;
                        _month = DateTime(_today.year, _today.month);
                      }),
                      child: const Text('回到今天'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 6),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, _selected),
                      child: const Text('确定'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
