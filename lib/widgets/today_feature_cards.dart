import 'package:flutter/material.dart';

import '../constants/mood_artwork.dart';
import '../music/music_controller.dart';
import 'today_tarot_card.dart';

class TodayFeatureCards extends StatelessWidget {
  const TodayFeatureCards({
    super.key,
    required this.onOpenDiary,
    this.todayMood,
    this.selectedDate,
  });
  final int? todayMood;
  final DateTime? selectedDate;
  final VoidCallback onOpenDiary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tile = colors.surfaceContainerLow;
    final now = DateTime.now();
    final historical =
        selectedDate != null &&
        selectedDate != DateTime(now.year, now.month, now.day);
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tile,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          historical ? '当日心情' : '今日心情',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (historical)
                          Text(
                            '${selectedDate!.month}月${selectedDate!.day}日',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        _TodayMoodArtwork(
                          mood: todayMood,
                          emptyText: !historical ? '选一个今天的心情' : '当天还没有记录心情',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: TodayTarotCard(selectedDate: selectedDate)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.primaryContainer, colors.surfaceContainerHigh],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onOpenDiary,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 28,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        color: colors.onPrimaryContainer,
                        size: 36,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '写下今天',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: colors.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '一句话也算，什么都可以写。',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.6,
                                color: colors.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: colors.primary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayMoodArtwork extends StatelessWidget {
  const _TodayMoodArtwork({required this.mood, required this.emptyText});
  final String emptyText;
  final int? mood;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final playing = MusicScope.maybeOf(context)?.playing ?? false;
    final asset = mood == null
        ? null
        : (playing ? MoodArtwork.headphonesAssets : MoodArtwork.assets)[mood!];
    return SizedBox(
      height: 128,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: ExcludeSemantics(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 106,
                        height: 106,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              colors.primary.withValues(alpha: 0.15),
                              colors.primary.withValues(alpha: 0.02),
                            ],
                          ),
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 2,
                    top: 10,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: colors.primary.withValues(alpha: 0.38),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    top: 28,
                    child: Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: colors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    bottom: 24,
                    child: Icon(
                      Icons.favorite_rounded,
                      size: 13,
                      color: colors.secondary.withValues(alpha: 0.45),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 12,
                    child: Transform.rotate(
                      angle: -0.55,
                      child: Container(
                        width: 5,
                        height: 13,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    top: 0,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 22,
                    top: 4,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: colors.secondary.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    bottom: 8,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Keep the character above every decoration, including transitions.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: mood == null
                ? Column(
                    key: const ValueKey('no-today-mood'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sentiment_satisfied_alt_rounded,
                        color: colors.primary.withValues(alpha: 0.45),
                        size: 42,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        emptyText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  )
                : Image.asset(
                    asset!,
                    key: ValueKey(asset),
                    width: double.infinity,
                    height: 128,
                    fit: BoxFit.contain,
                    cacheWidth: 320,
                    semanticLabel: MoodArtwork.labels[mood!],
                  ),
          ),
        ],
      ),
    );
  }
}
