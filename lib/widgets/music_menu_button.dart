import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../music/music_controller.dart';

class MusicMenuButton extends StatelessWidget {
  const MusicMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return MenuAnchor(
      consumeOutsideTap: true,
      alignmentOffset: const Offset(0, 12),
      style: MenuStyle(
        alignment: Alignment.bottomRight,
        backgroundColor: WidgetStatePropertyAll(colors.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: WidgetStatePropertyAll(
          colors.primary.withValues(alpha: 0.2),
        ),
        elevation: const WidgetStatePropertyAll(12),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: colors.primary.withValues(alpha: 0.12)),
          ),
        ),
      ),
      menuChildren: [
        SizedBox(
          width: math.min(240, MediaQuery.sizeOf(context).width - 32),
          child: const _MusicPanel(),
        ),
      ],
      builder: (context, controller, child) => IconButton(
        tooltip: '音乐',
        style: IconButton.styleFrom(
          foregroundColor: colors.primary,
          backgroundColor: colors.primary.withValues(alpha: 0.1),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.music_note_rounded, size: 23),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

class _MusicPanel extends StatefulWidget {
  const _MusicPanel();

  @override
  State<_MusicPanel> createState() => _MusicPanelState();
}

class _MusicPanelState extends State<_MusicPanel> {
  double? _dragSeconds;
  String _time(Duration value) =>
      '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final music = MusicScope.maybeOf(context);
    final canPlay = music?.current != null && music?.busy == false;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '音乐小憩',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 104,
            height: 104,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primary.withValues(alpha: 0.08),
                  colors.primary.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: music?.current?.artwork != null
                ? Image.memory(
                    music!.current!.artwork!,
                    key: ValueKey(music.current!.id),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, error, stackTrace) => Icon(
                      Icons.music_note_rounded,
                      color: colors.primary,
                      size: 44,
                    ),
                  )
                : Icon(
                    Icons.music_note_rounded,
                    color: colors.primary,
                    size: 44,
                  ),
          ),
          const SizedBox(height: 14),
          Text(
            music?.current?.name ?? '暂无音乐',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.onSurface, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            music?.current == null
                ? '在设置中导入喜欢的音乐'
                : '${music!.currentIndex + 1} / ${music.tracks.length}',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (music?.current != null) ...[
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                value: (_dragSeconds ?? music!.position.inMilliseconds / 1000)
                    .clamp(
                      0,
                      math.max(1.0, music!.duration.inMilliseconds / 1000),
                    ),
                max: math.max(1.0, music.duration.inMilliseconds / 1000),
                onChanged: canPlay && music.duration > Duration.zero
                    ? (value) => setState(() => _dragSeconds = value)
                    : null,
                onChangeEnd: (value) {
                  music.seek(Duration(milliseconds: (value * 1000).round()));
                  setState(() => _dragSeconds = null);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _time(music.position),
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  _time(music.duration),
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (music?.error != null)
            Text(
              music!.error!,
              style: TextStyle(fontSize: 12, color: colors.error),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                tooltip: '上一首',
                onPressed: canPlay ? music!.previous : null,
                icon: const Icon(Icons.skip_previous_rounded),
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  disabledForegroundColor: colors.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                ),
              ),
              IconButton(
                tooltip: music?.playing == true ? '暂停' : '播放',
                onPressed: canPlay ? music!.toggle : null,
                icon: music?.busy == true
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        music?.playing == true
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 30,
                      ),
                style: IconButton.styleFrom(
                  minimumSize: const Size(52, 52),
                  foregroundColor: colors.onPrimary,
                  backgroundColor: colors.primary,
                  disabledBackgroundColor: colors.primary.withValues(
                    alpha: 0.1,
                  ),
                  disabledForegroundColor: colors.primary.withValues(
                    alpha: 0.45,
                  ),
                ),
              ),
              IconButton(
                tooltip: '下一首',
                onPressed: canPlay ? music!.next : null,
                icon: const Icon(Icons.skip_next_rounded),
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  disabledForegroundColor: colors.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
