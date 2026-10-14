import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';
class SettingPage extends StatefulWidget {
  final ThemeController themeController;

  const SettingPage({required this.themeController, super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("设置"),
      ),
      body: ListenableBuilder(
          listenable: widget.themeController, 
          builder: (context, child) {
        return SafeArea(
            child: Column(
              children: [
                ThemeSetting(themeController: widget.themeController),
              ],
            )
        );
      }),
    );
  }
}
class ThemeSetting extends StatefulWidget {
  final ThemeController themeController;
  const ThemeSetting({required this.themeController, super.key});

  @override
  State<ThemeSetting> createState() => _ThemeSettingState();
}

class _ThemeSettingState extends State<ThemeSetting> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10.0),
      padding: EdgeInsets.all(10.0),
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(  borderRadius: BorderRadius.circular(30.0)),
        child: Column(
        children: [
          Text("外观设置",style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold),),
          Row(
            children: [
              Expanded(
                  child: InkWell(
                    onTap: () {
                      widget.themeController.setThemeMode(ThemeMode.system);
                    },
                    child: Container(
                      padding: EdgeInsets.all(10.0),
                      margin: EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: widget.themeController.themeMode == ThemeMode.system ? Theme.of(context).colorScheme.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      height: 150,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.devices,
                            color: Theme.of(context).colorScheme.primary,
                            size:20,
                          ),

                          Text("跟随系统",style: TextStyle(fontSize: 15.0,color: Colors.black),),
                          Icon(
                            widget.themeController.themeMode == ThemeMode.system
                                ? Icons.check_circle_outline
                                : Icons.circle,
                            color: widget.themeController.themeMode == ThemeMode.system
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            size: 20,
                          )

                        ],
                      ),
                    ),

                  )),
              Expanded(
                  child: InkWell(
                    onTap: () {
                      widget.themeController.setThemeMode(ThemeMode.light);
                    },
                    child: Container(

                      padding: EdgeInsets.all(10.0),
                      margin: EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: Color(0xFFC7BAEC),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: widget.themeController.themeMode == ThemeMode.light ? Theme.of(context).colorScheme.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      height: 150,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.light_mode_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size:20,
                          ),

                          Text("浅色模式",style: TextStyle(fontSize: 15.0,color: Colors.black),),
                          Icon(
                            widget.themeController.themeMode == ThemeMode.light
                                ? Icons.check_circle_outline
                                : Icons.circle,
                            color: widget.themeController.themeMode == ThemeMode.light
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            size: 20,
                          )

                        ],
                      ),
                    ),

                  )),
              Expanded(
                  child: InkWell(
                    onTap: () {
                      widget.themeController.setThemeMode(ThemeMode.dark);
                    },
                    child: Container(
                      padding: EdgeInsets.all(10.0),
                      margin: EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: widget.themeController.themeMode == ThemeMode.dark ? Theme.of(context).colorScheme.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      height: 150,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.dark_mode_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size:20,
                          ),

                          Text("深色模式",style: TextStyle(fontSize: 15.0, color: Colors.white),),
                          Icon(
                            widget.themeController.themeMode == ThemeMode.dark
                                ? Icons.check_circle_outline
                                : Icons.circle,
                            color: widget.themeController.themeMode == ThemeMode.dark
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            size: 20,
                          )
                        ],
                      ),
                    ),

                  )),

            ]
          ),
          Text("选择您喜欢的主题外观，点击卡片即可切换",style: TextStyle(fontSize: 15.0, color: Colors.grey),)
        ],
      ),
    );
  }
}

