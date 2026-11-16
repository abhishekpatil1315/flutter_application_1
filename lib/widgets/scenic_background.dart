import 'package:flutter/material.dart';

import '../theme/app_assets.dart';
import '../theme/app_theme.dart';

class ScenicBackground extends StatelessWidget {
  const ScenicBackground({
    required this.child,
    this.overlayOpacity = 0.72,
    super.key,
  });

  final Widget child;
  final double overlayOpacity;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        AppAssets.welcomeBackground,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const ColoredBox(color: AppColors.offWhite),
      ),
      ColoredBox(color: Colors.white.withValues(alpha: overlayOpacity)),
      child,
    ],
  );
}
