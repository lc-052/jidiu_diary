import 'package:flutter/material.dart';

class FeatureCardColors {
  FeatureCardColors.of(BuildContext context) {
    final theme = Theme.of(context);
    background = theme.colorScheme.surfaceContainerLow;
    foreground = theme.colorScheme.onSurface;
    secondary = theme.colorScheme.onSurfaceVariant;
    decoration = theme.colorScheme.outlineVariant;
    accent = theme.colorScheme.primary;
  }

  late final Color background;
  late final Color foreground;
  late final Color secondary;
  late final Color decoration;
  late final Color accent;
}
