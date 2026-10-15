import 'package:flutter/material.dart';

import '../theme/theme_controller.dart';
import '../widgets/app_background.dart';
import '../widgets/music_import_card.dart';
import '../widgets/data_backup_card.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({required this.themeController, super.key});
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) => AppBackground(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListenableBuilder(
        listenable: themeController,
        builder: (context, child) => SafeArea(
          child: ListView(
            children: [
              ThemeSetting(themeController: themeController),
              const MusicImportCard(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: DataBackupCard(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ThemeSetting extends StatelessWidget {
  const ThemeSetting({required this.themeController, super.key});
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const modes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];
    const labels = ['跟随系统', '浅色模式', '深色模式'];
    const icons = [
      Icons.devices_rounded,
      Icons.light_mode_outlined,
      Icons.dark_mode_outlined,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '外观设置',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: List.generate(3, (index) {
                  final selected = themeController.themeMode == modes[index];
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index == 2 ? 0 : 8),
                      child: Material(
                        color: colors.primary.withValues(
                          alpha: selected ? 0.12 : 0.04,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: selected
                                ? colors.primary
                                : colors.primary.withValues(alpha: 0.08),
                            width: selected ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () =>
                              themeController.setThemeMode(modes[index]),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 16,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  icons[index],
                                  size: 24,
                                  color: colors.primary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  labels[index],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Icon(
                                  selected
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  size: 18,
                                  color: selected
                                      ? colors.primary
                                      : colors.onSurfaceVariant.withValues(
                                          alpha: 0.4,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              Text(
                '选择喜欢的外观，让记录更自在',
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
