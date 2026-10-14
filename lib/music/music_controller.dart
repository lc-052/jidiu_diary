import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/blob.dart';

import 'music_database.dart';
import 'music_artwork.dart';

class MusicTrack {
  const MusicTrack({
    required this.id,
    required this.name,
    required this.extension,
    this.asset,
    this.artwork,
  });
  final String id;
  final String name;
  final String extension;
  final String? asset;
  final Uint8List? artwork;

  String get mimeType => switch (extension) {
    'wav' => 'audio/wav',
    'ogg' => 'audio/ogg',
    'm4a' => 'audio/mp4',
    _ => 'audio/mpeg',
  };
}

class MusicController extends ChangeNotifier {
  MusicController({AudioPlayer Function()? playerFactory})
    : _playerFactory = playerFactory ?? AudioPlayer.new;
  final AudioPlayer Function() _playerFactory;
  static const maxImports = 50;
  static const extensions = ['mp3', 'wav', 'ogg', 'm4a'];
  static const defaultAsset = 'lib/assets/audio/default_bgm.mp3';
  final _metadata = stringMapStoreFactory.store('tracks');
  final _audio = stringMapStoreFactory.store('audio');
  final _hiddenAssets = stringMapStoreFactory.store('hidden_assets');
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Database? _database;
  AudioPlayer? _player;
  bool _disposed = false;
  bool ready = false;
  bool importing = false;
  bool busy = false;
  bool playing = false;
  String? error;
  List<MusicTrack> tracks = [];
  int currentIndex = 0;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  MusicTrack? get current => tracks.isEmpty ? null : tracks[currentIndex];
  int get importedCount => tracks.where((track) => track.asset == null).length;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize({
    Database? database,
    bool discoverDefault = true,
  }) async {
    try {
      _database = database ?? await openMusicDatabase();
      if (_disposed) {
        await _database?.close();
        return;
      }
      final records = await _metadata.find(_database!);
      tracks = [];
      for (final record in records) {
        var artwork = (record.value['artwork'] as Blob?)?.bytes;
        if (record.value['artworkChecked'] != true) {
          final audio = await _audio.record(record.key).get(_database!);
          if (audio != null) {
            artwork = await readMusicArtwork(
              (audio['bytes'] as Blob).bytes,
              extension: record.value['extension'] as String,
            );
            await _metadata.record(record.key).update(_database!, {
              'artworkChecked': true,
              if (artwork != null) 'artwork': Blob(artwork),
            });
          }
        }
        tracks.add(
          MusicTrack(
            id: record.key,
            name: record.value['name'] as String,
            extension: record.value['extension'] as String,
            artwork: artwork,
          ),
        );
      }
      if (discoverDefault) {
        final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
        final assets =
            manifest
                .listAssets()
                .where(
                  (asset) =>
                      asset.startsWith('lib/assets/audio/') &&
                      extensions.contains(asset.split('.').last.toLowerCase()),
                )
                .toList()
              ..sort();
        final defaultPath = assets.contains(defaultAsset)
            ? defaultAsset
            : assets.firstOrNull;
        if (defaultPath != null &&
            !await _hiddenAssets.record(defaultPath).exists(_database!)) {
          final artwork = await readMusicArtwork(
            await _assetBytes(defaultPath),
            extension: defaultPath.split('.').last.toLowerCase(),
          );
          tracks.insert(
            0,
            MusicTrack(
              id: 'default',
              name: defaultPath == defaultAsset
                  ? '默认 BGM'
                  : defaultPath.split('/').last,
              extension: defaultPath.split('.').last.toLowerCase(),
              asset: defaultPath,
              artwork: artwork,
            ),
          );
        }
      }
      ready = true;
    } catch (_) {
      error = '音乐库加载失败，请重新打开应用';
    }
    _notify();
  }

  AudioPlayer get _audioPlayer {
    if (_player != null) return _player!;
    final player = _player = _playerFactory();
    _subscriptions.addAll([
      player.onPlayerStateChanged.listen((state) {
        playing = state == PlayerState.playing;
        _notify();
      }),
      player.onPositionChanged.listen((value) {
        position = value;
        _notify();
      }),
      player.onDurationChanged.listen((value) {
        duration = value;
        _notify();
      }),
      player.onPlayerComplete.listen((_) => unawaited(next())),
    ]);
    return player;
  }

  Future<void> _run(Future<void> Function() action) async {
    if (busy || current == null || _disposed) return;
    busy = true;
    error = null;
    _notify();
    try {
      await action();
    } catch (_) {
      error = '无法播放这首音乐，请尝试其他文件';
      playing = false;
    } finally {
      busy = false;
      _notify();
    }
  }

  String? _loadedId;
  Future<void> _playCurrent() async {
    final track = current!;
    final bytes = track.asset != null
        ? await _assetBytes(track.asset!)
        : ((await _audio.record(track.id).get(_database!))!['bytes'] as Blob)
              .bytes;
    position = Duration.zero;
    duration = Duration.zero;
    _loadedId = null;
    await _audioPlayer.play(BytesSource(bytes, mimeType: track.mimeType));
    _loadedId = track.id;
  }

  Future<Uint8List> _assetBytes(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<void> toggle() => _run(() async {
    if (playing) {
      await _audioPlayer.pause();
    } else if (_loadedId == current!.id) {
      await _audioPlayer.resume();
    } else {
      await _playCurrent();
    }
  });

  Future<void> select(int index) => _run(() async {
    if (index < 0 || index >= tracks.length) return;
    await _audioPlayer.stop();
    currentIndex = index;
    await _playCurrent();
  });
  Future<void> next() =>
      select(tracks.isEmpty ? 0 : (currentIndex + 1) % tracks.length);
  Future<void> previous() => select(
    tracks.isEmpty ? 0 : (currentIndex - 1 + tracks.length) % tracks.length,
  );
  Future<void> seek(Duration value) => _run(() => _audioPlayer.seek(value));

  Future<String> importFiles() async {
    if (!ready || importing) return '音乐库尚未准备好';
    if (importedCount >= maxImports) return '最多导入 50 首音乐';
    importing = true;
    _notify();
    int added = 0, skipped = 0, failed = 0;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
        allowMultiple: true,
        withData: kIsWeb,
      );
      if (result == null) return '已取消导入';
      for (final file in result.xFiles) {
        if (importedCount >= maxImports) {
          skipped++;
          continue;
        }
        try {
          final bytes = await file.readAsBytes();
          final outcome = await addTrack(file.name, bytes);
          if (outcome) {
            added++;
          } else {
            skipped++;
          }
        } catch (_) {
          failed++;
        }
      }
      return '已导入 $added 首${skipped > 0 ? '，跳过 $skipped 首（重复或已达上限）' : ''}${failed > 0 ? '，$failed 首导入失败' : ''}';
    } catch (_) {
      return '导入失败，请检查文件或本地存储空间';
    } finally {
      importing = false;
      _notify();
    }
  }

  Future<bool> addTrack(String name, Uint8List bytes) async {
    final extension = name.split('.').last.toLowerCase();
    if (!extensions.contains(extension) || bytes.isEmpty) {
      throw const FormatException('Unsupported audio');
    }
    final id = sha256.convert(bytes).toString();
    final artwork = await readMusicArtwork(bytes, extension: extension);
    final added = await _database!.transaction((txn) async {
      if (await _metadata.count(txn) >= maxImports ||
          await _metadata.record(id).exists(txn)) {
        return false;
      }
      await _audio.record(id).put(txn, {'bytes': Blob(bytes)});
      await _metadata.record(id).put(txn, {
        'name': name,
        'extension': extension,
        'artworkChecked': true,
        if (artwork != null) 'artwork': Blob(artwork),
      });
      return true;
    });
    if (added) {
      tracks.add(
        MusicTrack(id: id, name: name, extension: extension, artwork: artwork),
      );
      _notify();
    }
    return added;
  }

  Future<void> remove(MusicTrack track) async {
    if (busy || importing) return;
    busy = true;
    _notify();
    try {
      final selectedId = current?.id;
      if (selectedId == track.id) {
        await _player?.stop();
        _loadedId = null;
        playing = false;
        position = Duration.zero;
        duration = Duration.zero;
      }
      await _database!.transaction((txn) async {
        if (track.asset != null) {
          await _hiddenAssets.record(track.asset!).put(txn, {'removed': true});
          return;
        }
        await _metadata.record(track.id).delete(txn);
        await _audio.record(track.id).delete(txn);
      });
      tracks.removeWhere((item) => item.id == track.id);
      final retained = tracks.indexWhere((item) => item.id == selectedId);
      currentIndex = retained < 0 ? 0 : retained;
    } catch (_) {
      error = '移除失败，请稍后重试';
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_player?.dispose());
    unawaited(_database?.close());
    super.dispose();
  }
}

class MusicScope extends InheritedNotifier<MusicController> {
  const MusicScope({
    super.key,
    required MusicController controller,
    required super.child,
  }) : super(notifier: controller);
  static MusicController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MusicScope>()?.notifier;
}
