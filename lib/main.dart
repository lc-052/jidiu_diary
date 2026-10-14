import 'package:flutter/material.dart';
import 'package:jidiu_diary/routes/index.dart';
import 'package:jidiu_diary/theme/app_theme.dart';
import 'theme/theme_controller.dart';
void main() =>runApp(MainPage());
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  void initState() {
    super.initState();
    _themeController.loadTheme();
  }
  //创建控制器
  final ThemeController _themeController = ThemeController();
  //释放控制器
  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: _themeController,
        builder: (context, child){
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeController.themeMode,
        initialRoute: '/',
        routes: createRoutes(_themeController),
      );
    });
  }
}
