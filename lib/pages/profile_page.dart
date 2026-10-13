import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/diary_store.dart';
import '../widgets/diary_actions.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<DiaryStore>();
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          '我的',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        CircleAvatar(
          radius: 36,
          backgroundColor: colors.primaryContainer,
          child: Icon(Icons.spa_outlined, size: 40, color: colors.primary),
        ),
        const SizedBox(height: 16),
        const Center(child: Text('慢慢记录，好好生活', style: TextStyle(fontSize: 20))),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${store.entries.length}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Text('篇日记'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${store.moodCount}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Text('天心情'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '心情足迹',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                for (final total in store.moodTotals.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 85,
                          child: Text('${total.key.emoji} ${total.key.label}'),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: store.moodCount == 0
                                ? 0
                                : total.value / store.moodCount,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('${total.value} 天'),
                      ],
                    ),
                  ),
                if (store.moodCount == 0) const Text('记录第一次心情后，这里会显示你的心情分布。'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('深色模式'),
                secondary: const Icon(Icons.dark_mode_outlined),
                value: store.darkMode,
                onChanged: store.busy
                    ? null
                    : (value) async {
                        try {
                          await store.setDarkMode(value);
                        } catch (_) {
                          if (context.mounted) showSaveError(context);
                        }
                      },
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('复制数据备份'),
                subtitle: const Text('将全部日记和心情复制为 JSON 文本'),
                onTap: store.loadError != null
                    ? null
                    : () async {
                        try {
                          await Clipboard.setData(
                            ClipboardData(text: store.exportJson()),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已复制，请粘贴到文件中保存')),
                            );
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('复制失败，请重试')),
                            );
                          }
                        }
                      },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('关于寄丢日记'),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: '寄丢日记',
                  applicationVersion: '1.0.0',
                  children: [
                    const Text(
                      '一个离线的日记与心情记录应用。\n\n数据保存在当前设备的应用存储中，卸载或清除应用数据会丢失记录。建议定期复制备份。\n\n每日一想来自内置题库，按日期轮换。',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Center(child: Text('愿每一个普通的日子，都值得被记住。')),
        const SizedBox(height: 20),
      ],
    );
  }
}
