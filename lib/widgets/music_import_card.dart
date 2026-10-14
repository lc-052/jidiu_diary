import 'package:flutter/material.dart';

import '../music/music_controller.dart';

class MusicImportCard extends StatelessWidget {
  const MusicImportCard({super.key});

  @override
  Widget build(BuildContext context) {
    final music = MusicScope.maybeOf(context);
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Material(
        color: colors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(color: colors.primary.withValues(alpha: 0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.library_music_outlined,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '本地音乐',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    '${music?.importedCount ?? 0} / 50',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '导入喜欢的音乐，陪你记录日常',
                style: TextStyle(color: colors.onSurface, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                '支持 MP3、WAV、OGG、M4A，最多导入 50 首。默认 BGM 不占额度。',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed:
                      music == null ||
                          !music.ready ||
                          music.importing ||
                          music.importedCount >= MusicController.maxImports
                      ? null
                      : () async {
                          final message = await music.importFiles();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(message)));
                          }
                        },
                  icon: music?.importing == true
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_rounded),
                  label: Text(
                    music?.importing == true
                        ? '正在导入…'
                        : music?.importedCount == 50
                        ? '已达到 50 首上限'
                        : '从本地导入',
                  ),
                ),
              ),
              if (music?.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  music!.error!,
                  style: TextStyle(color: colors.error, fontSize: 12),
                ),
              ],
              if (music != null && music.tracks.isNotEmpty) ...[
                const SizedBox(height: 16),
                Divider(color: colors.primary.withValues(alpha: 0.1)),
                ...music.tracks.map(
                  (track) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      track.id == music.current?.id && music.playing
                          ? Icons.equalizer_rounded
                          : Icons.music_note_rounded,
                      color: colors.primary,
                    ),
                    title: Text(
                      track.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: track.asset != null
                        ? const Text('内置背景音乐', style: TextStyle(fontSize: 12))
                        : null,
                    onTap: music.busy
                        ? null
                        : () => music.select(music.tracks.indexOf(track)),
                    trailing: IconButton(
                      tooltip: '移除 ${track.name}',
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: music.busy || music.importing
                          ? null
                          : () => music.remove(track),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
