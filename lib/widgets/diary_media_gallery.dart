import 'package:flutter/material.dart';

import '../diary/diary_controller.dart';

class DiaryMediaGallery extends StatelessWidget {
  const DiaryMediaGallery({
    super.key,
    required this.attachments,
    this.onRemove,
  });
  final List<DiaryAttachment> attachments;
  final ValueChanged<String>? onRemove;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      for (var i = 0; i < attachments.length; i++)
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            children: [
              Positioned.fill(
                child: Material(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: ValueKey('diary-image-${attachments[i].id}'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _MediaPreview(
                          attachments: attachments,
                          initialIndex: i,
                        ),
                      ),
                    ),
                    child: Image.memory(
                      attachments[i].bytes,
                      fit: BoxFit.cover,
                      cacheWidth: 240,
                      semanticLabel: attachments[i].isDrawing
                          ? '日记涂鸦'
                          : attachments[i].name,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
              ),
              if (attachments[i].isDrawing)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: Icon(
                      Icons.brush_rounded,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              if (onRemove != null)
                Positioned(
                  right: 2,
                  top: 2,
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: IconButton.filled(
                      tooltip: '移除${attachments[i].isDrawing ? '涂鸦' : '图片'}',
                      padding: EdgeInsets.zero,
                      iconSize: 17,
                      onPressed: () => onRemove!(attachments[i].id),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ),
            ],
          ),
        ),
    ],
  );
}

class _MediaPreview extends StatefulWidget {
  const _MediaPreview({required this.attachments, required this.initialIndex});
  final List<DiaryAttachment> attachments;
  final int initialIndex;
  @override
  State<_MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<_MediaPreview> {
  late final _page = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('图片 ${_index + 1} / ${widget.attachments.length}'),
    ),
    body: PageView.builder(
      controller: _page,
      itemCount: widget.attachments.length,
      onPageChanged: (index) => setState(() => _index = index),
      itemBuilder: (context, index) => InteractiveViewer(
        minScale: .5,
        maxScale: 5,
        child: Center(
          child: Image.memory(
            widget.attachments[index].bytes,
            errorBuilder: (_, _, _) => const Text('图片无法显示'),
          ),
        ),
      ),
    ),
  );
}
