import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_assets.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) context.go('/welcome');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Semantics(
              label: 'MathQuest animal friends',
              child: Image.asset(
                AppAssets.splash,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const ColoredBox(color: AppColors.offWhite),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: const Alignment(0, -0.12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'MathQuest',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w900,
                            shadows: const [
                              Shadow(color: Colors.white, blurRadius: 12),
                            ],
                          ),
                    ),
                    const Text(
                      'by Sommer Learning',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                        shadows: [Shadow(color: Colors.white, blurRadius: 8)],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(
                      width: 180,
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
