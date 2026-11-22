import 'dart:ui';

/// The three languages of the app. Names are written in their own script
/// so a user can find their language whatever language is active.
enum AppLanguage {
  sinhala('si', 'සිංහල'),
  tamil('ta', 'தமிழ்'),
  english('en', 'English');

  const AppLanguage(this.code, this.nativeName);

  final String code;
  final String nativeName;

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String? code) =>
      values.firstWhere((l) => l.code == code, orElse: () => english);
}
