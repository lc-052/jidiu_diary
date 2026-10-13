import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/diary_entry.dart';
import '../state/diary_store.dart';
import '../widgets/diary_actions.dart';
import 'diary_detail_page.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});
  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  String _query = '';
  Mood? _mood;
  DateTime? _date;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<DiaryStore>();
    final entries = store.entries
        .where(
          (entry) =>
              (entry.title.toLowerCase().contains(_query) ||
                  entry.content.toLowerCase().contains(_query)) &&
              (_mood == null || entry.mood == _mood) &&
              (_date == null || dateKey(entry.date) == dateKey(_date!)),
        )
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '我的日记',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: '新增日记',
                    onPressed: () => openEditor(context),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
                decoration: const InputDecoration(
                  hintText: '搜索标题或正文',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('全部心情'),
                      selected: _mood == null,
                      onSelected: (_) => setState(() => _mood = null),
                    ),
                    for (final mood in Mood.values)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text('${mood.emoji} ${mood.label}'),
                          selected: _mood == mood,
                          onSelected: (_) => setState(
                            () => _mood = _mood == mood ? null : mood,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '共 ${entries.length} 篇',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: Text(_date == null ? '按日期筛选' : dateKey(_date!)),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _date ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null && mounted) setState(() => _date = date);
                    },
                  ),
                  if (_date != null)
                    IconButton(
                      tooltip: '取消日期筛选',
                      onPressed: () => setState(() => _date = null),
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_stories_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          store.entries.isEmpty
                              ? '还没有日记，从今天开始吧'
                              : '没有找到符合条件的日记',
                        ),
                        const SizedBox(height: 16),
                        if (store.entries.isEmpty)
                          FilledButton(
                            onPressed: () => openEditor(context),
                            child: const Text('写第一篇日记'),
                          ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: entries.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Card(
                      margin: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => DiaryDetailPage(id: entry.id),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${dateKey(entry.date)} · ${entry.mood.emoji} ${entry.mood.label}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                entry.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                entry.content,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(height: 1.6),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
