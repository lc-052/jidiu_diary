import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark ? AppDarkColors.gradient : AppLightColors.gradient,
        ),
      ),
      child: SizedBox.expand(child: child),
    );
  }
}
