import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_assets.dart';

abstract final class AppColors {
  static const primaryDark = Color(0xFF075B3A);
  static const primaryGreen = Color(0xFF168A48);
  static const actionGreen = Color(0xFF22B95A);
  static const skyBlue = Color(0xFF159FE3);
  static const navy = Color(0xFF10233F);
  static const gold = Color(0xFFFFC928);
  static const error = Color(0xFFF55B58);
  static const warning = Color(0xFFFF9800);
  static const offWhite = Color(0xFFF4FBF6);
  static const courseOne = Color(0xFF2DB7D6);
  static const courseTwo = Color(0xFF4CC16E);
  static const courseThree = Color(0xFF8FB8E8);
  static const darkGrey = Color(0xFF647488);
  static const lightGrey = Color(0xFFE5E7EB);
  static const success = Color(0xFF2ECC71);
  static const info = Color(0xFF3B82F6);
  static const beachOcean = Color(0xFF7DD3FC);
  static const beachTurquoise = Color(0xFF2DD4BF);
  static const beachSand = Color(0xFFFDE68A);
  static const forest = Color(0xFF84CC16);
  static const olive = Color(0xFF65A30D);
  static const earth = Color(0xFFA16207);
  static const ice = Color(0xFFBFDBFE);
  static const snow = Color(0xFFF1F5F9);
  static const mountain = Color(0xFF94A3B8);
}

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class AppRadius {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const pill = 999.0;
}

abstract final class AppElevation {
  static const low = BoxShadow(
    color: Color(0x1410233F),
    blurRadius: 4,
    offset: Offset(0, 2),
  );
  static const medium = BoxShadow(
    color: Color(0x1A10233F),
    blurRadius: 8,
    offset: Offset(0, 4),
  );
  static const high = BoxShadow(
    color: Color(0x2410233F),
    blurRadius: 16,
    offset: Offset(0, 8),
  );
}

class CourseTheme {
  const CourseTheme({
    required this.course,
    required this.title,
    required this.region,
    required this.primary,
    required this.accent,
    required this.surface,
    required this.backgroundAsset,
  });

  final int course;
  final String title;
  final String region;
  final Color primary;
  final Color accent;
  final Color surface;
  final String backgroundAsset;

  static const courses = <CourseTheme>[
    CourseTheme(
      course: 1,
      title: 'Foundations',
      region: 'Beach',
      primary: AppColors.beachOcean,
      accent: AppColors.beachTurquoise,
      surface: AppColors.beachSand,
      backgroundAsset: AppAssets.courseOne,
    ),
    CourseTheme(
      course: 2,
      title: 'Reasoning',
      region: 'Forest',
      primary: AppColors.forest,
      accent: AppColors.olive,
      surface: Color(0xFFECFCCB),
      backgroundAsset: AppAssets.courseTwo,
    ),
    CourseTheme(
      course: 3,
      title: 'Mastery',
      region: 'Snow',
      primary: AppColors.ice,
      accent: AppColors.mountain,
      surface: AppColors.snow,
      backgroundAsset: AppAssets.courseThree,
    ),
  ];

  static CourseTheme forCourse(int course) {
    if (course < 1 || course > courses.length) {
      throw RangeError.range(course, 1, courses.length, 'course');
    }
    return courses[course - 1];
  }
}

class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.offWhite,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryGreen,
      primary: AppColors.primaryGreen,
      secondary: AppColors.skyBlue,
      error: AppColors.error,
      surface: Colors.white,
    ),
    textTheme: GoogleFonts.nunitoTextTheme()
        .copyWith(
          displayLarge: GoogleFonts.nunito(
            fontSize: 32,
            height: 40 / 32,
            fontWeight: FontWeight.w800,
          ),
          headlineLarge: GoogleFonts.nunito(
            fontSize: 28,
            height: 34 / 28,
            fontWeight: FontWeight.w800,
          ),
          headlineMedium: GoogleFonts.nunito(
            fontSize: 24,
            height: 30 / 24,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: GoogleFonts.nunito(fontSize: 18, height: 26 / 18),
          bodyMedium: GoogleFonts.nunito(fontSize: 16, height: 24 / 16),
          bodySmall: GoogleFonts.nunito(fontSize: 14, height: 20 / 14),
          labelLarge: GoogleFonts.nunito(
            fontSize: 14,
            height: 18 / 14,
            fontWeight: FontWeight.w700,
          ),
          labelSmall: GoogleFonts.nunito(fontSize: 12, height: 16 / 12),
        )
        .apply(bodyColor: AppColors.navy, displayColor: AppColors.navy),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.offWhite,
      foregroundColor: AppColors.navy,
      centerTitle: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        foregroundColor: AppColors.primaryDark,
        side: const BorderSide(color: AppColors.primaryDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.primaryDark,
      indicatorColor: Colors.white,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? AppColors.primaryDark
              : Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.primaryDark
              : Colors.white,
        ),
      ),
    ),
  );
}
