import 'package:flutter/material.dart';
import 'package:jidiu_diary/pages/home/index.dart';
import 'package:jidiu_diary/pages/music_page.dart';
import 'package:jidiu_diary/pages/setting_page.dart';
import '../theme/theme_controller.dart';

Map<String, WidgetBuilder> createRoutes(
    ThemeController controller,
    ) => <String, WidgetBuilder>{
          '/': (BuildContext context) => HomePage(),
          '/music': (BuildContext context) => MusicPage(themeController: controller),
          '/setting': (BuildContext context) => SettingPage(themeController: controller),
        };
