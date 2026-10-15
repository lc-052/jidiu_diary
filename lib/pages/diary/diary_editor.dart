import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../constants/mood_artwork.dart';
import '../../diary/diary_controller.dart';
import '../../widgets/app_background.dart';
import '../../widgets/mood_calendar.dart';
import '../../widgets/diary_media_gallery.dart';
import 'diary_doodle.dart';

class DiaryEditor extends StatefulWidget {
  const DiaryEditor({
    super.key,
    required this.controller,
    this.initial,
    this.initialMood,
    this.initialDate,
  });
  final DiaryController controller;
  final DiaryEntry? initial;
  final int? initialMood;
  final DateTime? initialDate;
  @override
  State<DiaryEditor> createState() => _DiaryEditorState();
}

class _DiaryEditorState extends State<DiaryEditor> with WidgetsBindingObserver {
  final _title = TextEditingController();
  final _body = TextEditingController();
  late final String _id;
  late final DateTime _createdAt;
  late DateTime _date;
  int? _mood;
  final List<DiaryAttachment> _attachments = [];
  bool _importing = false;
  Timer? _timer;
  bool _dirty = false;
  bool _saving = false;
  bool _leaving = false;
  bool _allowPop = false;
  int _revision = 0;
  String _status = '内容自动保存为草稿';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final initial = widget.initial;
    _id = initial?.id ?? widget.controller.newId();
    _createdAt = initial?.createdAt ?? DateTime.now();
    final content = widget.controller.draft(_id) ?? initial;
    _date = content?.date ?? widget.initialDate ?? DateTime.now();
    _mood = content != null ? content.mood : widget.initialMood;
    _title.text = content?.title ?? '';
    _body.text = content?.body ?? '';
    _attachments.addAll(content?.attachments ?? []);
    if (widget.controller.draft(_id) != null) _status = '已恢复上次的草稿';
    _title.addListener(_changed);
    _body.addListener(_changed);
  }

  DiaryEntry _snapshot() => DiaryEntry(
    id: _id,
    date: _date,
    title: _title.text.trim(),
    body: _body.text,
    mood: _mood,
    attachments: _attachments,
    createdAt: _createdAt,
    updatedAt: DateTime.now(),
  );

  void _changed() {
    _dirty = true;
    _revision++;
    _timer?.cancel();
    _timer = Timer(
      const Duration(milliseconds: 600),
      () => unawaited(_persistDraft()),
    );
    if (mounted) setState(() => _status = '正在记录…');
  }

  Future<bool> _persistDraft() async {
    if (!_dirty) return true;
    final revision = _revision;
    try {
      await widget.controller.saveDraft(_snapshot());
      if (revision == _revision) _dirty = false;
      if (mounted) setState(() => _status = '草稿已保存');
      return true;
    } catch (_) {
      if (mounted) setState(() => _status = '草稿保存失败，请重试');
      return false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && !_saving && !_leaving) {
      _timer?.cancel();
      unawaited(_persistDraft());
    }
  }

  Future<void> _exit() async {
    if (_saving || _leaving) return;
    _leaving = true;
    _timer?.cancel();
    final saved = await _persistDraft();
    if (!mounted) return;
    if (!saved) {
      setState(() => _leaving = false);
      return;
    }
    setState(() => _allowPop = true);
    Navigator.pop(context);
  }

  Future<void> _save() async {
    if (_saving || _leaving || _importing) return;
    if (_body.text.trim().isEmpty && _attachments.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('写一点正文，或插入图片、涂鸦再保存吧')));
      return;
    }
    _timer?.cancel();
    setState(() => _saving = true);
    final value = _snapshot();
    try {
      await widget.controller.publish(value);
      _dirty = false;
      if (!mounted) return;
      setState(() => _allowPop = true);
      Navigator.pop(context, value.id);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('保存失败，内容仍在，请重试')));
      }
    }
  }

  Future<void> _insertImages() async {
    FocusScope.of(context).unfocus();
    setState(() => _importing = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
        allowMultiple: true,
        withData: true,
      );
      if (result == null || !mounted) return;
      final added = <DiaryAttachment>[];
      var skipped = 0;
      for (final file in result.files) {
        final bytes = file.bytes;
        if (bytes == null || bytes.isEmpty || bytes.length > 20 * 1024 * 1024) {
          skipped++;
          continue;
        }
        ui.Codec? codec;
        ui.Image? image;
        try {
          codec = await ui.instantiateImageCodec(
            bytes,
            targetWidth: 64,
            allowUpscaling: false,
          );
          image = (await codec.getNextFrame()).image;
          added.add(
            DiaryAttachment(
              id: widget.controller.newId(),
              name: file.name,
              bytes: bytes,
            ),
          );
        } catch (_) {
          skipped++;
        } finally {
          image?.dispose();
          codec?.dispose();
        }
      }
      if (!mounted) return;
      if (added.isNotEmpty) {
        _attachments.addAll(added);
        _changed();
      }
      if (skipped > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$skipped 张图片未能导入，请选择有效且不超过 20 MB 的图片')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('图片导入失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _insertDoodle() async {
    FocusScope.of(context).unfocus();
    final bytes = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(builder: (_) => const DiaryDoodle()),
    );
    if (bytes == null || !mounted) return;
    _attachments.add(
      DiaryAttachment(
        id: widget.controller.newId(),
        name: '涂鸦.png',
        bytes: bytes,
        isDrawing: true,
      ),
    );
    _changed();
  }

  Future<void> _discard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃这份草稿？'),
        content: const Text('未保存为日记的修改会被移除，原来的日记不受影响。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('继续写'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('放弃草稿'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _timer?.cancel();
    setState(() => _saving = true);
    try {
      await widget.controller.discardDraft(_id);
      _dirty = false;
      if (mounted) {
        setState(() => _allowPop = true);
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _status = '移除草稿失败，请重试';
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_exit());
      },
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(widget.initial == null ? '写下今天' : '编辑日记'),
            leading: IconButton(
              tooltip: '返回并保留草稿',
              onPressed: _saving ? null : _exit,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            actions: [
              IconButton(
                tooltip: '放弃草稿',
                onPressed: _saving ? null : _discard,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton.icon(
                  onPressed: _saving || _importing ? null : _save,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(_saving ? '保存中…' : '保存'),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: AbsorbPointer(
              absorbing: _saving || _leaving,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _EditorCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                            ),
                            label: Text(
                              '${_date.year}年${_date.month}月${_date.day}日',
                            ),
                            onPressed: () async {
                              final moods = widget.controller.dailyMoods;
                              final date = await showMoodCalendar(
                                context,
                                initialDate: _date,
                                moods: moods,
                              );
                              if (date != null && mounted) {
                                _date = date;
                                _changed();
                              }
                            },
                          ),
                        ),
                        Text(
                          '${_body.text.length} 字',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _EditorCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '这一篇的心情',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: List.generate(
                            5,
                            (index) => ChoiceChip(
                              showCheckmark: false,
                              backgroundColor: colors.primary.withValues(
                                alpha: 0.05,
                              ),
                              selectedColor: colors.primary.withValues(
                                alpha: 0.15,
                              ),
                              side: BorderSide(
                                color: _mood == index
                                    ? colors.primary
                                    : Colors.transparent,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              label: Text(
                                ['😊', '😌', '😨', '😡', '😐'][index],
                              ),
                              tooltip: MoodArtwork.labels[index],
                              selected: _mood == index,
                              onSelected: (selected) {
                                _mood = selected ? index : null;
                                _changed();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _EditorCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _importing ? null : _insertImages,
                              icon: const Icon(
                                Icons.add_photo_alternate_outlined,
                              ),
                              label: Text(_importing ? '导入中…' : '插入图片'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _importing ? null : _insertDoodle,
                              icon: const Icon(Icons.draw_outlined),
                              label: const Text('涂鸦'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '图片和涂鸦会一起保存，点击缩略图可放大查看。',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          key: const ValueKey('diary-title'),
                          controller: _title,
                          maxLength: 100,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            hintText: '标题（选填）',
                            border: InputBorder.none,
                            counterText: '',
                          ),
                        ),
                        Divider(color: colors.primary.withValues(alpha: 0.1)),
                        TextField(
                          key: const ValueKey('diary-body'),
                          controller: _body,
                          minLines: 12,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          style: const TextStyle(fontSize: 16, height: 1.8),
                          decoration: const InputDecoration(
                            hintText: '今天发生了什么？\n一句话也算，什么都可以写。',
                            border: InputBorder.none,
                          ),
                        ),
                        if (_attachments.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: DiaryMediaGallery(
                              attachments: _attachments,
                              onRemove: (id) {
                                _attachments.removeWhere(
                                  (item) => item.id == id,
                                );
                                _changed();
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _EditorCard(
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _status,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.primary.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
