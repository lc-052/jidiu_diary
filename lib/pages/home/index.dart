import 'package:flutter/material.dart';
import 'package:jidiu_diary/pages/home/today.dart';
import 'package:jidiu_diary/pages/home/diary.dart';
import 'package:jidiu_diary/pages/home/mine.dart';
import 'package:jidiu_diary/widgets/home_app_bar.dart';
import 'package:jidiu_diary/widgets/week_mood_card.dart';

import '../../diary/diary_controller.dart';
import '../diary/diary_actions.dart';
import '../../widgets/app_background.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _contentIndex = 0;
  final _contentStackKey = GlobalKey();
  static const _exitAt = .42;
  static const _swapAt = .46;
  static const _returnAt = .5;
  late final _contentAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
    value: 1,
  )..addListener(_advanceContent);

  void _advanceContent() {
    if (_contentAnimation.value >= _swapAt &&
        _currentIndex < 2 &&
        _contentIndex != _currentIndex) {
      setState(() => _contentIndex = _currentIndex);
    }
  }

  void _selectTab(int index) {
    if (index == _currentIndex) return;
    final animate =
        _currentIndex < 2 &&
        index < 2 &&
        !MediaQuery.disableAnimationsOf(context);
    _contentAnimation.stop();
    setState(() {
      _currentIndex = index;
      if (!animate) _contentIndex = index;
    });
    if (animate && _contentIndex != index) {
      _contentAnimation.forward(from: 0);
    } else {
      _contentAnimation.value = 1;
    }
  }

  @override
  void dispose() {
    _contentAnimation.dispose();
    super.dispose();
  }

  final Map<DateTime, int> _sessionDailyMoods = {};
  DateTime? _diaryDate;
  int? _moodForDate(DiaryController? diary) {
    final now = DateTime.now();
    final date = _diaryDate ?? DateTime(now.year, now.month, now.day);
    return diary?.dailyMoods[date] ?? _sessionDailyMoods[date];
  }

  void _writeDiary() {
    final diary = DiaryScope.maybeOf(context);
    _selectTab(1);
    if (diary?.ready == true) {
      writeDiary(context, diary!, initialDate: _diaryDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final diary = DiaryScope.maybeOf(context);
    final displayMood = _moodForDate(diary);
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 64, child: HomeAppBar()),
              Expanded(
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverToBoxAdapter(
                      child: Visibility(
                        visible: _currentIndex != 2,
                        maintainState: true,
                        child: WeekMoodCard(
                          dailyMoods: diary?.dailyMoods ?? _sessionDailyMoods,
                          onDailyMoodChanged: (date, mood) async {
                            if (diary == null) {
                              setState(() => _sessionDailyMoods[date] = mood);
                              return;
                            }
                            try {
                              await diary.initialize();
                              await diary.setDailyMood(date, mood);
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('每日心情保存失败，请重试')),
                                );
                              }
                            }
                          },
                          onDateSelected: (date) => setState(() {
                            _diaryDate = date;
                          }),
                        ),
                      ),
                    ),
                  ],
                  body: _currentIndex == 2
                      ? const MinePage()
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final travel = constraints.maxHeight + 32;
                            return ClipRect(
                              child: AnimatedBuilder(
                                animation: _contentAnimation,
                                builder: (context, child) {
                                  final value = _contentAnimation.value;
                                  final double displacement;
                                  if (value < _exitAt) {
                                    displacement = Curves.easeInCubic.transform(
                                      value / _exitAt,
                                    );
                                  } else if (value < _returnAt) {
                                    // Swap content only while the entire card is below the viewport.
                                    displacement = 1;
                                  } else {
                                    displacement =
                                        1 -
                                        Curves.easeOutCubic.transform(
                                          (value - _returnAt) / (1 - _returnAt),
                                        );
                                  }
                                  return IgnorePointer(
                                    ignoring: _contentAnimation.isAnimating,
                                    child: Transform.translate(
                                      key: const ValueKey(
                                        'home-content-transition',
                                      ),
                                      offset: Offset(0, travel * displacement),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    key: const ValueKey('home-content-card'),
                                    margin: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: IndexedStack(
                                      key: _contentStackKey,
                                      index: _contentIndex,
                                      children: [
                                        Visibility(
                                          visible: _contentIndex == 0,
                                          maintainState: true,
                                          child: TodayPage(
                                            todayMood: displayMood,
                                            selectedDate: _diaryDate,
                                            active: _contentIndex == 0,
                                            onOpenDiary: _writeDiary,
                                          ),
                                        ),
                                        Visibility(
                                          visible: _contentIndex == 1,
                                          maintainState: true,
                                          child: DiaryPage(
                                            filterDate: _diaryDate,
                                            active: _contentIndex == 1,
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
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Align(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: NavigationBarTheme(
                    data: NavigationBarThemeData(
                      labelTextStyle: WidgetStateProperty.resolveWith((states) {
                        final selected = states.contains(WidgetState.selected);
                        return TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        );
                      }),
                    ),
                    child: NavigationBar(
                      height: 76,
                      elevation: 0,
                      surfaceTintColor: Colors.transparent,
                      backgroundColor: colorScheme.surface,
                      indicatorColor: colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      labelBehavior:
                          NavigationDestinationLabelBehavior.alwaysShow,
                      selectedIndex: _currentIndex,
                      onDestinationSelected: _selectTab,
                      destinations: [
                        NavigationDestination(
                          icon: Image.asset(
                            'lib/assets/today-unselected.png',
                            color: colorScheme.onSurfaceVariant,
                            width: 36,
                            height: 36,
                            excludeFromSemantics: true,
                          ),
                          selectedIcon: Image.asset(
                            'lib/assets/today-selected.png',
                            color: colorScheme.primary,
                            width: 36,
                            height: 36,
                            excludeFromSemantics: true,
                          ),
                          label: '今天',
                        ),
                        NavigationDestination(
                          icon: Image.asset(
                            'lib/assets/diary-unselected.png',
                            color: colorScheme.onSurfaceVariant,
                            width: 36,
                            height: 36,
                            excludeFromSemantics: true,
                          ),
                          selectedIcon: Image.asset(
                            'lib/assets/diary-selected.png',
                            color: colorScheme.primary,
                            width: 36,
                            height: 36,
                            excludeFromSemantics: true,
                          ),
                          label: '日记',
                        ),
                        NavigationDestination(
                          icon: Image.asset(
                            'lib/assets/profile-unselected.png',
                            color: colorScheme.onSurfaceVariant,
                            width: 36,
                            height: 36,
                            excludeFromSemantics: true,
                          ),
                          selectedIcon: Image.asset(
                            'lib/assets/profile-selected.png',
                            color: colorScheme.primary,
                            width: 36,
                            height: 36,
                            excludeFromSemantics: true,
                          ),
                          label: '我的',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
