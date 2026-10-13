import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/diary_entry.dart';
import '../state/diary_store.dart';
import '../widgets/diary_actions.dart';

class DiaryEditorPage extends StatefulWidget {
  const DiaryEditorPage({super.key, this.entry, this.date});
  final DiaryEntry? entry;
  final DateTime? date;
  @override
  State<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends State<DiaryEditorPage> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  late DateTime _date;
  late Mood _mood;
  late DateTime _initialDate;
  late Mood _initialMood;
  bool _saving = false;
  bool _allowPop = false;
  String? _validation;
  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.entry?.title ?? '');
    _content = TextEditingController(text: widget.entry?.content ?? '');
    _date = widget.entry?.date ?? widget.date ?? DateTime.now();
    _mood =
        widget.entry?.mood ??
        context.read<DiaryStore>().moodOn(_date) ??
        Mood.calm;
    _initialDate = _date;
    _initialMood = _mood;
    _title.addListener(_refresh);
    _content.addListener(_refresh);
  }

  void _refresh() {
    setState(() {});
  }

  bool get _dirty =>
      _title.text != (widget.entry?.title ?? '') ||
      _content.text != (widget.entry?.content ?? '') ||
      _mood != _initialMood ||
      dateKey(_date) != dateKey(_initialDate);

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_content.text.trim().isEmpty) {
      setState(() => _validation = '写下几句话，再保存吧');
      return;
    }
    setState(() {
      _saving = true;
      _validation = null;
    });
    final now = DateTime.now();
    final entry = DiaryEntry(
      id: widget.entry?.id ?? now.microsecondsSinceEpoch.toString(),
      date: DateTime(_date.year, _date.month, _date.day),
      title: _title.text.trim().isEmpty ? '无题日记' : _title.text.trim(),
      content: _content.text.trim(),
      mood: _mood,
      updatedAt: now,
    );
    try {
      await context.read<DiaryStore>().saveEntry(entry);
      if (!mounted) return;
      setState(() => _allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showSaveError(context);
      }
    }
  }

  Future<void> _confirmLeave() async {
    if (_saving) return;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃未保存的修改？'),
        content: const Text('返回后，这次输入的内容不会保存。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('继续编辑'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('放弃修改'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      setState(() => _allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop || (!_dirty && !_saving),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _confirmLeave();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? '写下今天' : '编辑日记'),
        actions: [
          TextButton(
            onPressed: _saving || context.watch<DiaryStore>().busy
                ? null
                : _save,
            child: Text(_saving ? '保存中…' : '保存'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(dateKey(_date)),
                  onPressed: _saving
                      ? null
                      : () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (date != null && mounted) {
                            setState(() => _date = date);
                          }
                        },
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _title,
                enabled: !_saving,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: '标题（可不填）',
                  hintText: '给今天起个名字',
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Mood.values
                    .map(
                      (mood) => ChoiceChip(
                        label: Text('${mood.emoji} ${mood.label}'),
                        selected: _mood == mood,
                        onSelected: _saving
                            ? null
                            : (_) => setState(() => _mood = mood),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _content,
                enabled: !_saving,
                minLines: 12,
                maxLines: null,
                maxLength: 20000,
                decoration: InputDecoration(
                  hintText: '今天发生了什么？有什么想对自己说的话？',
                  errorText: _validation,
                  alignLabelWithHint: true,
                  labelText: '正文',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '保存日记也会更新当天心情。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
