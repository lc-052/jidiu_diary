import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/diary_entry.dart';
import '../state/diary_store.dart';
import '../widgets/diary_actions.dart';

class DiaryDetailPage extends StatelessWidget {
  const DiaryDetailPage({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<DiaryStore>();
    final matches = store.entries.where((entry) => entry.id == id);
    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('日记已删除')),
      );
    }
    final entry = matches.first;
    return Scaffold(
      appBar: AppBar(
        title: const Text('日记详情'),
        actions: [
          IconButton(
            tooltip: '编辑日记',
            onPressed: store.busy
                ? null
                : () => openEditor(context, entry: entry),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: '删除日记',
            onPressed: store.busy
                ? null
                : () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('删除这篇日记？'),
                        content: const Text('删除后无法恢复，当天心情记录会保留。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('删除'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true || !context.mounted) return;
                    try {
                      await store.deleteEntry(id);
                      if (context.mounted) Navigator.pop(context);
                    } catch (_) {
                      if (context.mounted) showSaveError(context);
                    }
                  },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                '${dateKey(entry.date)} · ${entry.mood.emoji} ${entry.mood.label}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              SelectableText(
                entry.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              SelectableText(
                entry.content,
                style: const TextStyle(fontSize: 17, height: 1.9),
              ),
              const SizedBox(height: 32),
              Text(
                '最后修改：${dateKey(entry.updatedAt)} ${entry.updatedAt.hour.toString().padLeft(2, '0')}:${entry.updatedAt.minute.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
