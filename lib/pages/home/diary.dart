import 'dart:async';

import 'package:flutter/material.dart';

import '../../constants/mood_artwork.dart';
import '../../diary/diary_controller.dart';
import '../../theme/feature_card_colors.dart';
import '../../widgets/diary_media_gallery.dart';
import '../diary/diary_actions.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({
    super.key,
    this.active = true,
    this.initialMood,
    this.filterDate,
  });
  final DateTime? filterDate;
  final bool active;
  final int? initialMood;
  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  final _search = TextEditingController();
  @override
  void didUpdateWidget(covariant DiaryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filterDate != widget.filterDate) _search.clear();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final diary = DiaryScope.maybeOf(context);
    if (diary != null && !diary.ready && diary.error == null) {
      unawaited(diary.initialize());
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _discardDraft(DiaryController diary, DiaryEntry draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除这份草稿？'),
        content: const Text('未保存的内容会被移除，原来的日记不受影响。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('移除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await diary.discardDraft(draft.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('草稿移除失败，请重试')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cardColors = FeatureCardColors.of(context);
    final diary = DiaryScope.maybeOf(context);
    final entries = (diary?.search(_search.text) ?? <DiaryEntry>[])
        .where(
          (entry) =>
              widget.filterDate == null || entry.date == widget.filterDate,
        )
        .toList();
    final drafts =
        diary?.drafts
            .where(
              (draft) =>
                  widget.filterDate == null || draft.date == widget.filterDate,
            )
            .toList() ??
        <DiaryEntry>[];
    final groups = <DateTime, List<DiaryEntry>>{};
    for (final entry in entries) {
      groups.putIfAbsent(entry.date, () => []).add(entry);
    }
    final widgets = <Widget>[
      for (final group in groups.entries)
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: _DiaryDayCard(
            key: ValueKey(
              'diary-day-${group.key.toIso8601String().substring(0, 10)}',
            ),
            entries: [...group.value]
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
            controller: diary!,
          ),
        ),
    ];
    return ListView(
      key: const PageStorageKey('diary-content'),
      primary: widget.active,
      shrinkWrap: true,
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '我的日记',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: diary?.ready == true
                  ? () => writeDiary(
                      context,
                      diary!,
                      initialMood: widget.filterDate == null
                          ? widget.initialMood
                          : null,
                      initialDate: widget.filterDate,
                    )
                  : null,
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('写日记'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '每一天，都可以留下不止一个片段',
          style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 18),
        TextField(
          key: const ValueKey('diary-search'),
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '搜索标题、正文或日期',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: cardColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: '清空搜索',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _search.clear();
                      setState(() {});
                    },
                  ),
          ),
        ),
        if (diary?.error != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(diary!.error!, style: TextStyle(color: colors.error)),
          ),
          TextButton.icon(
            onPressed: diary.retryInitialization,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重新加载日记库'),
          ),
        ],
        if (diary == null)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('日记服务未连接，请完整重启应用。'),
          ),
        if (diary != null && !diary.ready && diary.error == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (diary != null && drafts.isNotEmpty && _search.text.isEmpty) ...[
          const SizedBox(height: 16),
          Material(
            color: cardColors.background,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              key: const PageStorageKey('diary-drafts-panel'),
              title: Text('草稿箱 · ${drafts.length}'),
              subtitle: const Text(
                '继续上次没写完的故事',
                style: TextStyle(fontSize: 12),
              ),
              initiallyExpanded: true,
              shape: const Border(),
              collapsedShape: const Border(),
              children: drafts
                  .map(
                    (draft) => ListTile(
                      title: Text(
                        draft.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        draft.dateLabel,
                        style: const TextStyle(fontSize: 12),
                      ),
                      leading: Icon(
                        Icons.drafts_outlined,
                        color: colors.primary,
                      ),
                      onTap: () => writeDiary(context, diary, initial: draft),
                      trailing: IconButton(
                        tooltip: '移除草稿',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => _discardDraft(diary, draft),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        if (entries.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            _search.text.isEmpty
                ? '${entries.length} 篇日记'
                : '找到 ${entries.length} 篇日记',
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
          ...widgets,
        ] else if (diary == null || diary.ready) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
            decoration: BoxDecoration(
              color: cardColors.background,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  size: 48,
                  color: cardColors.accent,
                ),
                const SizedBox(height: 16),
                Text(
                  _search.text.isEmpty
                      ? widget.filterDate == null
                            ? '还没有日记'
                            : '这一天还没有日记'
                      : '没有找到相关日记',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: cardColors.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _search.text.isEmpty ? '把值得记住的日常，留在这里。' : '换一个词，试着找找看。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: cardColors.secondary),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DiaryDayCard extends StatelessWidget {
  const _DiaryDayCard({
    super.key,
    required this.entries,
    required this.controller,
  });
  final List<DiaryEntry> entries;
  final DiaryController controller;

  @override
  Widget build(BuildContext context) {
    final palette = FeatureCardColors.of(context);
    return Material(
      color: palette.background,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entries.first.dateLabel,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: palette.foreground,
                    ),
                  ),
                ),
                Text(
                  '${entries.length} 篇',
                  style: TextStyle(fontSize: 12, color: palette.secondary),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            indent: 18,
            endIndent: 18,
            color: palette.decoration,
          ),
          for (var index = 0; index < entries.length; index++) ...[
            if (index > 0)
              Divider(
                height: 1,
                indent: 18,
                endIndent: 18,
                color: palette.decoration,
              ),
            InkWell(
              onTap: () =>
                  writeDiary(context, controller, initial: entries[index]),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        entries[index].timeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: palette.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entries[index].displayTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: palette.foreground,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                key: ValueKey(
                                  'diary-actions-${entries[index].id}',
                                ),
                                tooltip: '日记操作',
                                icon: Icon(
                                  Icons.more_horiz_rounded,
                                  color: palette.secondary,
                                ),
                                onSelected: (action) {
                                  if (action == 'edit') {
                                    writeDiary(
                                      context,
                                      controller,
                                      initial: entries[index],
                                    );
                                  } else {
                                    deleteDiary(
                                      context,
                                      controller,
                                      entries[index].id,
                                    );
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('编辑日记'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('删除日记'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entries[index].body,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: palette.secondary,
                            ),
                          ),
                          if (entries[index].attachments.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            DiaryMediaGallery(
                              attachments: entries[index].attachments,
                            ),
                          ],
                          if (entries[index].mood != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${['😊', '😌', '😨', '😡', '😐'][entries[index].mood!]} ${MoodArtwork.labels[entries[index].mood!]}',
                              style: TextStyle(
                                fontSize: 12,
                                color: palette.secondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
