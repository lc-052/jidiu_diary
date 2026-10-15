import 'package:flutter/material.dart';

import '../../diary/diary_controller.dart';
import 'diary_editor.dart';

Future<void> writeDiary(
  BuildContext context,
  DiaryController controller, {
  DiaryEntry? initial,
  int? initialMood,
  DateTime? initialDate,
}) async {
  final id = await Navigator.push<String>(
    context,
    MaterialPageRoute(
      builder: (_) => DiaryEditor(
        controller: controller,
        initial: initial,
        initialMood: initialMood,
        initialDate: initialDate,
      ),
    ),
  );
  if (id != null && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('日记已保存')));
  }
}

Future<void> deleteDiary(
  BuildContext context,
  DiaryController controller,
  String id,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('删除这篇日记？'),
      content: const Text('删除后无法恢复。'),
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
  if (confirmed != true) return;
  try {
    await controller.delete(id);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('日记已删除')));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('删除失败，请重试')));
    }
  }
}
