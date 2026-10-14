import 'dart:typed_data';

import 'package:metadata_audio/metadata_audio.dart';

/// Cover parsing is optional: damaged or untagged files must still play.
Future<Uint8List?> readMusicArtwork(
  Uint8List bytes, {
  String extension = 'mp3',
}) async {
  try {
    final metadata = await parseBytes(
      bytes,
      fileInfo: FileInfo(path: 'track.$extension'),
      options: const ParseOptions(skipPostHeaders: true),
    );
    final pictures = <Picture>[...?metadata.common.picture];
    // Some files expose artwork only in their native APIC/covr tags.
    for (final tags in metadata.native.values) {
      for (final tag in tags) {
        final value = tag.value;
        if (value is Picture) pictures.add(value);
        if (value is List) pictures.addAll(value.whereType<Picture>());
      }
    }
    final picture = selectCover(pictures);
    if (picture == null || picture.data.isEmpty) return null;
    return Uint8List.fromList(picture.data);
  } catch (_) {
    return null;
  }
}
