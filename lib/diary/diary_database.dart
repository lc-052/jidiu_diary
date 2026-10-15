import 'package:sembast/sembast.dart';

import 'diary_database_native.dart'
    if (dart.library.js_interop) 'diary_database_web.dart'
    as platform;

Future<Database> openDiaryDatabase() => platform.openDiaryDatabase();
