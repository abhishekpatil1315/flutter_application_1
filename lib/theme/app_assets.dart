abstract final class AppAssets {
  static const splash = 'assets/Splash scrren 2-2.png';
  static const welcomeBackground = 'assets/Splashscreen01.jpg';
  static const welcomeCharacters = 'assets/SL_characters_math app.jpg';
  static const journey = 'assets/journey screen_math app.jpg';
  static const courseOne = 'assets/Course-1BG.png';
  static const courseTwo = 'assets/Course-2BG.png';
  static const courseThree = 'assets/Course-3BG.png';
  static const home = 'assets/Home.png';
  static const rank = 'assets/Rank.png';
  static const settings = 'assets/settings.png';
  static const animals = welcomeCharacters;

  static String numberCard(int value) => value == 0
      ? 'assets/card0.png'
      : 'assets/card$value.jpg';
}
