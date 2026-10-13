import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/diary_entry.dart';
import '../state/diary_store.dart';
import '../pages/diary_editor_page.dart';

Future<void> openEditor(
  BuildContext context, {
  DiaryEntry? entry,
  DateTime? date,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => DiaryEditorPage(entry: entry, date: date),
  ),
);

void showSaveError(BuildContext context) {
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('保存失败，请检查本地存储后重试。你的输入仍然保留。')));
}

Future<void> chooseMood(BuildContext context, DateTime date) async {
  final store = context.read<DiaryStore>();
  final mood = await showModalBottomSheet<Mood>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${dateKey(date)} 的心情',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Mood.values
                  .map(
                    (mood) => ChoiceChip(
                      label: Text('${mood.emoji} ${mood.label}'),
                      selected: store.moodOn(date) == mood,
                      onSelected: (_) => Navigator.pop(context, mood),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text('每天保留一个心情记录，可以随时更新。'),
          ],
        ),
      ),
    ),
  );
  if (mood == null || !context.mounted) return;
  try {
    await store.setMood(date, mood);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('心情已记录')));
    }
  } catch (_) {
    if (context.mounted) showSaveError(context);
  }
}
