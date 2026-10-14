import 'dart:math' as math;

import 'package:flutter/material.dart';

class WeekMoodCard extends StatefulWidget {
  const WeekMoodCard({super.key});

  @override
  State<WeekMoodCard> createState() => _WeekMoodCardState();
}

class _WeekMoodCardState extends State<WeekMoodCard> {
  static const _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  static const _emojis = ['😊', '😌', '😨', '😡', '😐'];
  static const _moodLabels = ['开心', '平静', '惊恐', '生气', '一般'];

  late final DateTime _monday;
  late DateTime _selectedDate;
  bool _showMoodPicker = false;
  final Map<DateTime, int> _moods = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monday = DateTime(now.year, now.month, now.day - now.weekday + 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = colors.primary;
    final frameColor = isDark
        ? const Color(0xFF2B2340)
        : const Color(0xFFF5F2FF);
    final tintColor = isDark
        ? const Color(0xFF3D3058)
        : const Color(0xFFEEE7FF);
    final lineColor = isDark
        ? const Color(0xFF4A3C63)
        : const Color(0xFFE7DFFF);
    final mutedColor = isDark
        ? const Color(0xFFB5ABC9)
        : const Color(0xFF8585A6);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: frameColor,
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
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: frameColor,
                          borderRadius: BorderRadius.circular(24),
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
                    '点击日期，留下今天的小心情',
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
                          final mood = _moods[date];

                          return Expanded(
                            child: Semantics(
                              button: true,
                              selected: selected,
                              label:
                                  '${date.month}月${date.day}日，${_weekdays[index]}${mood == null ? '' : '，${_moodLabels[mood]}'}',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () => setState(() {
                                  _selectedDate = date;
                                  _showMoodPicker = true;
                                }),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
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
                                              ? primary
                                              : mood != null
                                              ? tintColor
                                              : colors.surface,
                                          border: Border.all(
                                            color: selected
                                                ? primary
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
                                                ? colors.onPrimary
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
                                              ? primary
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
                            final selected = _moods[_selectedDate] == index;
                            return Semantics(
                              button: true,
                              selected: selected,
                              label: _moodLabels[index],
                              child: InkWell(
                                borderRadius: BorderRadius.circular(19),
                                onTap: () => setState(() {
                                  _moods[_selectedDate] = index;
                                  _showMoodPicker = false;
                                }),
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
