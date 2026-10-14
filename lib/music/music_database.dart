import 'package:sembast/sembast.dart';

import 'music_database_native.dart'
    if (dart.library.js_interop) 'music_database_web.dart'
    as platform;

Future<Database> openMusicDatabase() => platform.openMusicDatabase();
