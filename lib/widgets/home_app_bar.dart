import 'package:flutter/material.dart';
import 'package:jidiu_diary/widgets/music_menu_button.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'lib/assets/app_icon.png',
                width: 32,
                height: 32,
                cacheWidth: 96,
                semanticLabel: '寄丢日记图标',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: '寄丢'),
                    TextSpan(
                      text: '日记',
                      style: TextStyle(color: colors.primary),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const MusicMenuButton(),
            const SizedBox(width: 6),
            IconButton(
              tooltip: '设置',
              style: IconButton.styleFrom(
                foregroundColor: colors.onSurfaceVariant,
                backgroundColor: colors.surface,
                minimumSize: const Size(48, 48),
                shape: const CircleBorder(),
              ),
              icon: const Icon(Icons.menu_rounded, size: 23),
              onPressed: () => Navigator.pushNamed(context, '/setting'),
            ),
          ],
        ),
      ),
    );
  }
}
