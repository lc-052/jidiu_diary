import 'package:sembast_web/sembast_web.dart';

Future<Database> openDiaryDatabase() =>
    databaseFactoryWeb.openDatabase('jidiu_diary');
