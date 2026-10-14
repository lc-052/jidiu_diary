import 'package:flutter/material.dart';
import 'package:jidiu_diary/pages/setting_page.dart';
import 'package:jidiu_diary/pages/music_page.dart';
import 'package:jidiu_diary/pages/home/index.dart';
Widget MainPage() {
  return MaterialApp(
    initialRoute: '/',
    routes: <String, WidgetBuilder>{
      '/': (BuildContext context) => HomePage(),
      '/music': (BuildContext context) => MusicPage(),
      '/setting': (BuildContext context) => SettingPage(),
    },
  );
}