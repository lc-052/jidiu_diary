import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'mood_calendar.dart';

class WeekMoodCard extends StatefulWidget {
  const WeekMoodCard({
    super.key,
    this.onTodayMoodChanged,
    this.onPastDateSelected,
    this.onDateSelected,
    this.currentDate,
    this.dailyMoods = const {},
    this.onDailyMoodChanged,
  });
  final ValueChanged<DateTime>? onPastDateSelected;
  final ValueChanged<DateTime>? onDateSelected;
  final DateTime? currentDate;
  final ValueChanged<int>? onTodayMoodChanged;
  final Map<DateTime, int> dailyMoods;
  final void Function(DateTime date, int mood)? onDailyMoodChanged;

  @override
  State<WeekMoodCard> createState() => _WeekMoodCardState();
}

class _WeekMoodCardState extends State<WeekMoodCard> {
  static const _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  static const _emojis = ['😊', '😌', '😨', '😡', '😐'];
  static const _moodLabels = ['开心', '平静', '惊恐', '生气', '一般'];

  late DateTime _monday;
  late final DateTime _today;
  late DateTime _selectedDate;
  bool _showMoodPicker = false;
  final Map<DateTime, int> _moods = {};

  @override
  void initState() {
    super.initState();
    final now = widget.currentDate ?? DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _monday = DateTime(now.year, now.month, now.day - now.weekday + 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  Future<void> _openCalendar() async {
    final date = await showMoodCalendar(
      context,
      initialDate: _selectedDate,
      currentDate: _today,
      moods: {..._moods, ...widget.dailyMoods},
    );
    if (date == null || !mounted) return;
    setState(() {
      _selectedDate = date;
      _monday = DateTime(date.year, date.month, date.day - date.weekday + 1);
      _showMoodPicker = false;
    });
    widget.onDateSelected?.call(date);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final primary = colors.primary;
    final tintColor = colors.surfaceContainerLow;
    final lineColor = colors.outlineVariant;
    final mutedColor = colors.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(26),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '本周心情',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        key: const ValueKey('week-calendar-button'),
                        onPressed: _openCalendar,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          backgroundColor: colors.surface,
                          side: BorderSide(color: lineColor),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          '${_selectedDate.year}年${_selectedDate.month}月',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '点击日期记录心情',
                    style: TextStyle(fontSize: 14, color: mutedColor),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final diameter = math.min(
                        48.0,
                        constraints.maxWidth / 7 - 4,
                      );
                      return Row(
                        children: List.generate(7, (index) {
                          final date = DateTime(
                            _monday.year,
                            _monday.month,
                            _monday.day + index,
                          );
                          final selected = date == _selectedDate;
                          final future = date.isAfter(_today);
                          final mood = widget.dailyMoods[date] ?? _moods[date];

                          return Expanded(
                            child: Semantics(
                              button: true,
                              enabled: !future,
                              selected: selected,
                              label:
                                  '${date.month}月${date.day}日，${_weekdays[index]}${mood == null ? '' : '，${_moodLabels[mood]}'}',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: future
                                    ? null
                                    : () {
                                        setState(() {
                                          _selectedDate = date;
                                          _showMoodPicker = true;
                                        });
                                        widget.onDateSelected?.call(date);
                                        if (date.isBefore(_today)) {
                                          widget.onPastDateSelected?.call(date);
                                        }
                                      },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    gradient: selected
                                        ? LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color.lerp(
                                                primary,
                                                colors.onPrimary,
                                                .08,
                                              )!,
                                              primary,
                                            ],
                                          )
                                        : null,
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: primary.withValues(
                                                alpha: 0.25,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Column(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        width: diameter,
                                        height: diameter,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: selected
                                              ? colors.surface
                                              : mood != null
                                              ? tintColor
                                              : colors.surface,
                                          border: Border.all(
                                            color: selected
                                                ? primary.withValues(
                                                    alpha: 0.35,
                                                  )
                                                : future
                                                ? lineColor.withValues(
                                                    alpha: 0.5,
                                                  )
                                                : lineColor,
                                          ),
                                        ),
                                        child: Text(
                                          mood == null
                                              ? '${date.day}'
                                              : _emojis[mood],
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: selected
                                                ? primary
                                                : future
                                                ? mutedColor.withValues(
                                                    alpha: 0.45,
                                                  )
                                                : colors.onSurface,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _weekdays[index],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: selected
                                              ? colors.onPrimary
                                              : future
                                              ? mutedColor.withValues(
                                                  alpha: 0.45,
                                                )
                                              : mutedColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                  if (_showMoodPicker) ...[
                    const SizedBox(height: 24),
                    Divider(height: 1, thickness: 1, color: lineColor),
                    const SizedBox(height: 24),
                    Text(
                      '选择心情 · ${_selectedDate.month}月${_selectedDate.day}日',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final size = math.min(
                          70.0,
                          (constraints.maxWidth - 32) / 5,
                        );
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(_emojis.length, (index) {
                            final selected =
                                (widget.dailyMoods[_selectedDate] ??
                                    _moods[_selectedDate]) ==
                                index;
                            return Semantics(
                              button: true,
                              selected: selected,
                              label: _moodLabels[index],
                              child: InkWell(
                                borderRadius: BorderRadius.circular(19),
                                onTap: () {
                                  setState(() {
                                    _moods[_selectedDate] = index;
                                    _showMoodPicker = false;
                                  });
                                  widget.onDailyMoodChanged?.call(
                                    _selectedDate,
                                    index,
                                  );
                                  if (_selectedDate == _today) {
                                    widget.onTodayMoodChanged?.call(index);
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: size,
                                  height: size,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? tintColor
                                        : colors.surface,
                                    borderRadius: BorderRadius.circular(19),
                                    border: Border.all(
                                      color: selected ? primary : lineColor,
                                      width: selected ? 2 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    _emojis[index],
                                    style: TextStyle(
                                      fontSize: math.min(32.0, size * 0.55),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}
