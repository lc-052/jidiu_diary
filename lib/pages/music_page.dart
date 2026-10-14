import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';
class MusicPage extends StatefulWidget {
  final ThemeController themeController;
  const MusicPage({required this.themeController, super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
