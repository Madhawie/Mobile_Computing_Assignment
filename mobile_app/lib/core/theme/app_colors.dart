import 'package:material_ui/material_ui.dart';

import '../constants/user_role.dart';

/// Colours from docs/ui/README.md ("Colour rules").
///
/// Each pair is a light background plus a dark colour for text and icons
/// on it. The dark colours pass WCAG AA contrast on their background.
class AppColors {
  AppColors._();

  // Page
  static const background = Color(0xFFF8F7FC);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF2B2D42);
  static const muted = Color(0xFF646878);
  static const border = Color(0xFFE6E3EE);
  static const track = Color(0xFFECEAF3); // segmented control background

  // One colour per user, so it is always clear which app is open.
  static const motherLight = Color(0xFFECE6FA); // lavender
  static const motherDark = Color(0xFF5E4E99);
  static const phmLight = Color(0xFFDDF3EA); // mint
  static const phmDark = Color(0xFF2F7356);
  static const mohLight = Color(0xFFFFF1CC); // butter
  static const mohDark = Color(0xFF8A5A12);

  // Same as the CHDR book: blue for boys, pink for girls.
  // Never the only cue: screens also show the words "Boy" / "Girl".
  static const boyLight = Color(0xFFDCEBFA);
  static const boyAccent = Color(0xFF6FA3D9);
  static const boyText = Color(0xFF1F4166);
  static const girlLight = Color(0xFFFBE1EA);
  static const girlAccent = Color(0xFFE58FAE);
  static const girlText = Color(0xFF7A2D4B);

  // Growth zones and status messages.
  static const goodLight = Color(0xFFDDF3EA);
  static const good = Color(0xFF2F7356);
  static const warnLight = Color(0xFFFFF1CC);
  static const warn = Color(0xFF6E5410);
  static const dangerLight = Color(0xFFFDE3DF);
  static const danger = Color(0xFF9A3B2E);

  static Color roleLight(UserRole role) => switch (role) {
        UserRole.mother => motherLight,
        UserRole.phm => phmLight,
        UserRole.supervisor || UserRole.admin => mohLight,
      };

  static Color roleDark(UserRole role) => switch (role) {
        UserRole.mother => motherDark,
        UserRole.phm => phmDark,
        UserRole.supervisor || UserRole.admin => mohDark,
      };
}
