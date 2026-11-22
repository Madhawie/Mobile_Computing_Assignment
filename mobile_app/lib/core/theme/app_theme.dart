import 'package:material_ui/material_ui.dart';

import '../constants/user_role.dart';
import 'app_colors.dart';

/// Builds the app theme. Before sign-in [role] is null and the neutral
/// (mother lavender) colour is used; after sign-in the role's colour is used.
///
/// Design rules from the UI: large text, large touch targets (≥ 48 px),
/// rounded shapes, one main button per screen.
class AppTheme {
  AppTheme._();

  /// Nunito is the design font. Sinhala and Tamil letters are not in Nunito,
  /// so they fall back to Noto Sans Sinhala / Noto Sans Tamil.
  static const fontFamily = 'Nunito';
  static const fontFallback = ['NotoSansSinhala', 'NotoSansTamil'];

  static ThemeData forRole(UserRole? role) {
    final primary = role == null ? AppColors.motherDark : AppColors.roleDark(role);
    final primaryLight = role == null ? AppColors.motherLight : AppColors.roleLight(role);

    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryLight,
      onPrimaryContainer: primary,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.danger,
    );

    const radius = BorderRadius.all(Radius.circular(16));

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: base.textTheme
          .copyWith(
            headlineMedium: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            titleLarge: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            bodyLarge: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            bodyMedium: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            bodySmall: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted),
            labelLarge: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          )
          .apply(bodyColor: AppColors.text, displayColor: AppColors.text),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          backgroundColor: AppColors.surface,
          minimumSize: const Size.fromHeight(50),
          shape: const StadiumBorder(),
          side: const BorderSide(color: AppColors.border, width: 1.5),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: const OutlineInputBorder(borderRadius: radius),
        enabledBorder: const OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: AppColors.danger, width: 2),
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
      ),
    );
  }
}
