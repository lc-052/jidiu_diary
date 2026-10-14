import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jidiu_diary/music/music_controller.dart';
import 'package:jidiu_diary/theme/app_theme.dart';
import 'package:jidiu_diary/widgets/music_import_card.dart';
import 'package:sembast/sembast_memory.dart';

class FakePlayer implements AudioPlayer {
  final states = StreamController<PlayerState>.broadcast(sync: true);
  final completed = StreamController<void>.broadcast(sync: true);
  Source? lastSource;
  Duration? sought;
  bool fail = false;
  @override
  Stream<PlayerState> get onPlayerStateChanged => states.stream;
  @override
  Stream<Duration> get onPositionChanged => const Stream.empty();
  @override
  Stream<Duration> get onDurationChanged => const Stream.empty();
  @override
  Stream<void> get onPlayerComplete => completed.stream;
  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    if (fail) throw StateError('Unsupported audio');
    lastSource = source;
    states.add(PlayerState.playing);
  }

  @override
  Future<void> pause() async => states.add(PlayerState.paused);
  @override
  Future<void> resume() async => states.add(PlayerState.playing);
  @override
  Future<void> stop() async => states.add(PlayerState.stopped);
  @override
  Future<void> seek(Duration position) async {
    sought = position;
  }

  @override
  Future<void> dispose() async {
    await states.close();
    await completed.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Persists bytes, skips duplicates, and enforces 50 imports atomically',
    () async {
      final factory = newDatabaseFactoryMemory();
      final db = await factory.openDatabase('library');
      final music = MusicController();
      await music.initialize(database: db, discoverDefault: false);
      expect(
        await music.addTrack('song.mp3', Uint8List.fromList([1, 2, 3])),
        isTrue,
      );
      expect(
        await music.addTrack('renamed.mp3', Uint8List.fromList([1, 2, 3])),
        isFalse,
      );
      await Future.wait(
        List.generate(
          60,
          (i) => music.addTrack('$i.wav', Uint8List.fromList([i, 9, 8, 7])),
        ),
      );
      expect(music.importedCount, 50);
      music.dispose();
      await Future<void>.delayed(Duration.zero);
      final restored = MusicController();
      await restored.initialize(
        database: await factory.openDatabase('library'),
        discoverDefault: false,
      );
      expect(restored.importedCount, 50);
      await restored.remove(restored.tracks.first);
      expect(restored.importedCount, 49);
      expect(
        await restored.addTrack('new.mp3', Uint8List.fromList([254])),
        isTrue,
      );
      restored.dispose();
    },
  );

  test(
    'Playback, pause, resume, seek, next, previous, completion and failure',
    () async {
      final player = FakePlayer();
      final music = MusicController(playerFactory: () => player);
      await music.initialize(
        database: await newDatabaseFactoryMemory().openDatabase('playback'),
        discoverDefault: false,
      );
      await music.addTrack('one.mp3', Uint8List.fromList([1]));
      await music.addTrack('two.mp3', Uint8List.fromList([2]));
      await music.toggle();
      expect(music.playing, isTrue);
      expect((player.lastSource as BytesSource).bytes, [1]);
      await music.toggle();
      expect(music.playing, isFalse);
      await music.toggle();
      expect(music.playing, isTrue);
      await music.seek(const Duration(seconds: 5));
      expect(player.sought, const Duration(seconds: 5));
      await music.next();
      expect(music.current!.name, 'two.mp3');
      await music.next();
      expect(music.current!.name, 'one.mp3');
      await music.previous();
      expect(music.current!.name, 'two.mp3');
      player.completed.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(music.current!.name, 'one.mp3');
      player.fail = true;
      await music.next();
      expect(music.error, isNotNull);
      expect(music.busy, isFalse);
      expect(music.playing, isFalse);
      music.dispose();
    },
  );

  test(
    'The supplied default BGM is bundled and does not use import capacity',
    () async {
      final music = MusicController();
      await music.initialize(
        database: await newDatabaseFactoryMemory().openDatabase('default'),
      );
      expect(music.ready, isTrue);
      expect(music.current!.asset, isNotNull);
      expect(music.current!.artwork, isNotNull);
      expect(music.current!.artwork!.length, greaterThan(0));
      final bytes = await rootBundle.load(music.current!.asset!);
      expect(bytes.lengthInBytes, greaterThan(0));
      expect(music.importedCount, 0);
      music.dispose();
    },
  );

  testWidgets(
    'Import card follows dark theme and shows local songs on small screens',
    (tester) async {
      final music = MusicController();
      await tester.runAsync(() async {
        await music.initialize(
          database: await newDatabaseFactoryMemory().openDatabase('card'),
          discoverDefault: false,
        );
        await music.addTrack('song.mp3', Uint8List.fromList([1]));
      });
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(music.dispose);
      await tester.pumpWidget(
        MusicScope(
          controller: music,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: SingleChildScrollView(child: MusicImportCard()),
            ),
          ),
        ),
      );
      expect(find.text('1 / 50'), findsOneWidget);
      expect(find.text('song.mp3'), findsOneWidget);
      expect(find.text('从本地导入'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Removing the built-in BGM stays removed after reopening the library',
    () async {
      final factory = newDatabaseFactoryMemory();
      final music = MusicController();
      await music.initialize(database: await factory.openDatabase('removal'));
      final builtIn = music.current!;
      await music.remove(builtIn);
      expect(music.tracks, isEmpty);
      expect(music.importedCount, 0);
      music.dispose();
      await Future<void>.delayed(Duration.zero);
      final restored = MusicController();
      await restored.initialize(
        database: await factory.openDatabase('removal'),
      );
      expect(restored.tracks, isEmpty);
      expect(restored.ready, isTrue);
      restored.dispose();
    },
  );

  test('Imported artwork survives reopening the library', () async {
    final factory = newDatabaseFactoryMemory();
    final music = MusicController();
    await music.initialize(database: await factory.openDatabase('artwork'));
    final data = await rootBundle.load(music.current!.asset!);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    await music.addTrack('cover.mp3', bytes);
    final artwork = music.tracks.last.artwork!;
    music.dispose();
    await Future<void>.delayed(Duration.zero);
    final restored = MusicController();
    await restored.initialize(
      database: await factory.openDatabase('artwork'),
      discoverDefault: false,
    );
    expect(restored.current!.artwork, orderedEquals(artwork));
    restored.dispose();
  });
}
