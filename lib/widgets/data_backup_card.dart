import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../backup/diary_backup.dart';
import '../diary/diary_controller.dart';
import '../theme/feature_card_colors.dart';

class DataBackupCard extends StatefulWidget {
  const DataBackupCard({super.key});
  @override
  State<DataBackupCard> createState() => _DataBackupCardState();
}

class _DataBackupCardState extends State<DataBackupCard> {
  bool _busy = false;
  bool _failed = false;
  String? _status;

  void _message(String text, {bool failed = false}) {
    if (mounted) {
      setState(() {
        _status = text;
        _failed = failed;
      });
    }
  }

  Future<void> _export(DiaryController diary) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
      _status = '正在整理备份…';
    });
    try {
      final backup = await DiaryBackup.capture(diary);
      final bytes = backup.encode();
      if (!mounted) return;
      final stamp = DateTime.now()
          .toIso8601String()
          .substring(0, 19)
          .replaceAll(':', '-')
          .replaceAll('T', '_');
      final path = await FilePicker.platform.saveFile(
        dialogTitle: '保存寄丢日记备份',
        fileName: 'jidiu-backup-$stamp.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );
      _message(
        kIsWeb
            ? '已开始下载备份文件'
            : path == null
            ? '已取消导出'
            : '备份文件已保存',
      );
    } catch (_) {
      _message('导出失败，请检查保存位置后重试', failed: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import(DiaryController diary) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
      _status = '请选择备份文件';
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: '选择寄丢日记备份',
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (!mounted) return;
      if (result == null || result.files.isEmpty) {
        _message('已取消导入');
        return;
      }
      final bytes = result.files.single.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw const FormatException('文件为空或无法读取，请重新选择');
      }
      final backup = DiaryBackup.decode(bytes);
      if (!mounted) return;
      final date = backup.createdAt.toLocal();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('导入这份备份？'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('备份时间：${date.year}年${date.month}月${date.day}日'),
                const SizedBox(height: 14),
                Text(
                  '${backup.diary.entries.length} 篇日记 · ${backup.diary.drafts.length} 份草稿\n'
                  '${backup.mediaCount} 张图片 / 涂鸦\n'
                  '${backup.diary.dailyMoods.length} 天心情 · ${backup.tarot.length} 条塔罗记录',
                  style: const TextStyle(height: 1.8),
                ),
                const SizedBox(height: 14),
                const Text('记录将与当前数据合并，重复记录保留当前版本。'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认导入'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) {
        _message('已取消导入');
        return;
      }
      _message('正在恢复记录…');
      final restored = await backup.restore(diary);
      _message('导入完成：新增 ${restored.added} 条记录，保留 ${restored.skipped} 条已有记录');
    } on FormatException catch (error) {
      _message('导入失败：${error.message}', failed: true);
    } on StateError catch (error) {
      _message('导入未完成：${error.message}', failed: true);
    } catch (_) {
      _message('导入失败，请检查备份文件后重试', failed: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = FeatureCardColors.of(context);
    final diary = DiaryScope.maybeOf(context);
    final available = diary?.ready == true && !_busy;
    return Material(
      key: const ValueKey('data-backup-card'),
      color: colors.surface,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: palette.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 24,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '数据备份',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '把珍贵的日常，妥善留存。',
              style: TextStyle(fontSize: 14, color: palette.foreground),
            ),
            const SizedBox(height: 8),
            Text(
              '包含日记、草稿、图片、涂鸦、每日心情和塔罗记录；不包含本地音乐。',
              style: TextStyle(
                fontSize: 12,
                height: 1.7,
                color: palette.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: available ? () => _export(diary!) : null,
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text('导出数据'),
                ),
                OutlinedButton.icon(
                  onPressed: available ? () => _import(diary!) : null,
                  icon: const Icon(Icons.file_upload_outlined, size: 18),
                  label: const Text('导入数据'),
                ),
              ],
            ),
            if (_busy) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(minHeight: 2),
            ],
            if (_status != null || diary?.ready != true) ...[
              const SizedBox(height: 12),
              Text(
                _status ?? '加载记录后即可导入或导出',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: _failed ? colors.error : palette.secondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
