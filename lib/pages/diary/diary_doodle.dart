import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../widgets/app_background.dart';

class DiaryDoodle extends StatefulWidget {
  const DiaryDoodle({super.key});
  @override
  State<DiaryDoodle> createState() => _DiaryDoodleState();
}

class _Stroke {
  _Stroke(this.color, this.width, this.points);
  final Color color;
  final double width;
  final List<Offset> points;
}

class _DiaryDoodleState extends State<DiaryDoodle> {
  static const _colors = [
    Color(0xFF786753),
    Color(0xFF2B2925),
    Color(0xFFF06E9C),
    Color(0xFFEF9465),
    Color(0xFFF3C64F),
    Color(0xFF58B8A3),
    Color(0xFF5C9DE8),
  ];
  final _strokes = <_Stroke>[];
  final _redo = <_Stroke>[];
  Color _color = _colors.first;
  double _width = 5;
  bool _eraser = false;
  bool _saving = false;
  bool _allowPop = false;

  Future<void> _close() async {
    if (_saving) return;
    if (_strokes.isNotEmpty || _redo.isNotEmpty) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('放弃这张涂鸦？'),
          content: const Text('点击「插入日记」可以保存这张画。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('继续画'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('放弃'),
            ),
          ],
        ),
      );
      if (leave != true || !mounted) return;
    }
    if (mounted) {
      setState(() => _allowPop = true);
      Navigator.pop(context);
    }
  }

  Future<void> _save() async {
    if (_saving || _strokes.isEmpty) return;
    setState(() => _saving = true);
    ui.Image? image;
    ui.Picture? picture;
    try {
      final recorder = ui.PictureRecorder();
      _DoodlePainter(_strokes).paint(Canvas(recorder), const Size(1200, 900));
      picture = recorder.endRecording();
      image = await picture.toImage(1200, 900);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('PNG unavailable');
      final bytes = Uint8List.fromList(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      if (!mounted) return;
      setState(() => _allowPop = true);
      Navigator.pop(context, bytes);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('涂鸦保存失败，请重试')));
      }
    } finally {
      image?.dispose();
      picture?.dispose();
    }
  }

  Future<void> _clear() async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空画布？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (clear == true && mounted) {
      setState(() {
        _strokes.clear();
        _redo.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _close();
      },
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            title: const Text('画下此刻'),
            leading: IconButton(
              tooltip: '返回日记',
              onPressed: _saving ? null : _close,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton(
                  onPressed: _saving || _strokes.isEmpty ? null : _save,
                  child: Text(_saving ? '插入中…' : '插入日记'),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: AbsorbPointer(
              absorbing: _saving,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('用颜色记录，不用画得完美。'),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (var i = 0; i < _colors.length; i++)
                              Semantics(
                                label: '画笔颜色 ${i + 1}',
                                selected: !_eraser && _color == _colors[i],
                                child: InkWell(
                                  onTap: () => setState(() {
                                    _color = _colors[i];
                                    _eraser = false;
                                  }),
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _colors[i],
                                      border: Border.all(
                                        color: !_eraser && _color == _colors[i]
                                            ? colors.onSurface
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                    child: !_eraser && _color == _colors[i]
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 18,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(_eraser ? '橡皮大小' : '画笔粗细'),
                            Expanded(
                              child: Slider(
                                value: _width,
                                min: 2,
                                max: 18,
                                divisions: 8,
                                label: '${_width.round()}',
                                onChanged: (value) =>
                                    setState(() => _width = value),
                              ),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            TextButton.icon(
                              onPressed: () =>
                                  setState(() => _eraser = !_eraser),
                              icon: Icon(
                                _eraser
                                    ? Icons.brush_rounded
                                    : Icons.auto_fix_normal_rounded,
                              ),
                              label: Text(_eraser ? '切换画笔' : '橡皮擦'),
                            ),
                            IconButton(
                              tooltip: '撤销',
                              onPressed: _strokes.isEmpty
                                  ? null
                                  : () => setState(
                                      () => _redo.add(_strokes.removeLast()),
                                    ),
                              icon: const Icon(Icons.undo_rounded),
                            ),
                            IconButton(
                              tooltip: '重做',
                              onPressed: _redo.isEmpty
                                  ? null
                                  : () => setState(
                                      () => _strokes.add(_redo.removeLast()),
                                    ),
                              icon: const Icon(Icons.redo_rounded),
                            ),
                            IconButton(
                              tooltip: '清空画布',
                              onPressed: _strokes.isEmpty ? null : _clear,
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          Offset normalized(Offset point) => Offset(
                            (point.dx / constraints.maxWidth).clamp(0, 1),
                            (point.dy / constraints.maxHeight).clamp(0, 1),
                          );
                          return Semantics(
                            label: '涂鸦画布',
                            child: GestureDetector(
                              key: const ValueKey('doodle-canvas'),
                              behavior: HitTestBehavior.opaque,
                              onTapUp: (details) => setState(() {
                                _redo.clear();
                                _strokes.add(
                                  _Stroke(
                                    _eraser ? Colors.white : _color,
                                    _eraser ? _width * 3 : _width,
                                    [normalized(details.localPosition)],
                                  ),
                                );
                              }),
                              onPanStart: (details) => setState(() {
                                _redo.clear();
                                _strokes.add(
                                  _Stroke(
                                    _eraser ? Colors.white : _color,
                                    _eraser ? _width * 3 : _width,
                                    [normalized(details.localPosition)],
                                  ),
                                );
                              }),
                              onPanUpdate: (details) {
                                if (_strokes.isNotEmpty) {
                                  setState(
                                    () => _strokes.last.points.add(
                                      normalized(details.localPosition),
                                    ),
                                  );
                                }
                              },
                              child: CustomPaint(
                                painter: _DoodlePainter(_strokes),
                                size: Size.infinite,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '在白色画布上自由涂画，完成后点击「插入日记」。',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
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

class _DoodlePainter extends CustomPainter {
  _DoodlePainter(this.strokes);
  final List<_Stroke> strokes;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawColor(Colors.white, BlendMode.src);
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width * size.width / 600
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      Offset point(Offset p) => Offset(p.dx * size.width, p.dy * size.height);
      if (stroke.points.length == 1) {
        canvas.drawCircle(
          point(stroke.points.first),
          paint.strokeWidth / 2,
          Paint()..color = stroke.color,
        );
      } else {
        final path = Path()
          ..moveTo(
            point(stroke.points.first).dx,
            point(stroke.points.first).dy,
          );
        for (final p in stroke.points.skip(1)) {
          path.lineTo(point(p).dx, point(p).dy);
        }
        canvas.drawPath(path, paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DoodlePainter oldDelegate) => true;
}
