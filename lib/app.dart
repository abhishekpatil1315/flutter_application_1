import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/account_screens.dart';
import 'screens/achievement_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screens.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
    GoRoute(
      path: '/access',
      builder: (context, state) => AccessScreen(
        startInSignIn: state.uri.queryParameters['mode'] == 'signin',
      ),
    ),
    GoRoute(
      path: '/verify',
      builder: (context, state) => VerifyEmailScreen(email: state.extra as String?),
    ),
    GoRoute(path: '/profile-setup', builder: (context, state) => const ProfileSetupScreen()),
    GoRoute(path: '/ready', builder: (context, state) => const ReadyScreen()),
    GoRoute(path: '/profiles', builder: (context, state) => const ProfileSelectorScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsTab()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileTab()),
    GoRoute(path: '/achievements', builder: (context, state) => const AchievementScreen()),
  ],
);

class MathQuestApp extends StatelessWidget {
  const MathQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MathQuest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
