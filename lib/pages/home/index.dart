import 'package:flutter/material.dart';
import 'package:jidiu_diary/pages/home/today.dart';
import 'package:jidiu_diary/pages/home/diary.dart';
import 'package:jidiu_diary/pages/home/mine.dart';
import 'package:jidiu_diary/widgets/home_app_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const HomeAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: const [TodayPage(), DiaryPage(), MinePage()],
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
                    indicatorColor: colorScheme.primary.withValues(alpha: 0.1),
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysShow,
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (int index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    destinations: [
                      NavigationDestination(
                        icon: Image.asset(
                          'lib/assets/today-unselected.png',
                          width: 36,
                          height: 36,
                          excludeFromSemantics: true,
                        ),
                        selectedIcon: Image.asset(
                          'lib/assets/today-selected.png',
                          width: 36,
                          height: 36,
                          excludeFromSemantics: true,
                        ),
                        label: '今天',
                      ),
                      NavigationDestination(
                        icon: Image.asset(
                          'lib/assets/diary-unselected.png',
                          width: 36,
                          height: 36,
                          excludeFromSemantics: true,
                        ),
                        selectedIcon: Image.asset(
                          'lib/assets/diary-selected.png',
                          width: 36,
                          height: 36,
                          excludeFromSemantics: true,
                        ),
                        label: '日记',
                      ),
                      NavigationDestination(
                        icon: Image.asset(
                          'lib/assets/profile-unselected.png',
                          width: 36,
                          height: 36,
                          excludeFromSemantics: true,
                        ),
                        selectedIcon: Image.asset(
                          'lib/assets/profile-selected.png',
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
    );
  }
}
