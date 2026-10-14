import 'package:sembast_web/sembast_web.dart';

Future<Database> openMusicDatabase() =>
    databaseFactoryWeb.openDatabase('jidiu_music');
