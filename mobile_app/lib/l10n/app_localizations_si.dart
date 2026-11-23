// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Sinhala Sinhalese (`si`).
class AppLocalizationsSi extends AppLocalizations {
  AppLocalizationsSi([String locale = 'si']) : super(locale);

  @override
  String get appName => 'Little Bloom';

  @override
  String get chooseLanguage => 'ඔබේ භාෂාව තෝරන්න';

  @override
  String get whoAreYou => 'ඔබ කවුද?';

  @override
  String get roleMother => 'මම මවක්';

  @override
  String get rolePhm => 'මම පවුල් සෞඛ්‍ය සේවා නිලධාරිනියක් (PHM)';

  @override
  String get roleAdmin => 'මම පරිපාලකයෙක් (සෞඛ්‍ය වෛද්‍ය නිලධාරී කාර්යාලය)';

  @override
  String get continueLabel => 'ඉදිරියට';

  @override
  String get save => 'සුරකින්න';

  @override
  String get cancel => 'අවලංගු කරන්න';

  @override
  String get boy => 'පිරිමි ළමයා';

  @override
  String get girl => 'ගැහැණු ළමයා';

  @override
  String get offlineSaved => 'සංඥා නැත – මෙම දුරකථනයේ සුරැකිණි';

  @override
  String get sendNow => 'දැන් යවන්න';

  @override
  String pendingChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'යැවීමට වෙනස්කම් $countක් ඉතිරිව ඇත',
      one: 'යැවීමට වෙනස්කම් 1ක් ඉතිරිව ඇත',
      zero: 'සියල්ල යවා ඇත',
    );
    return '$_temp0';
  }

  @override
  String get lowBirthWeight => 'අඩු උපත් බර (කි.ග්‍රෑ. 2.5ට අඩු)';

  @override
  String get highBloodPressure => 'රුධිර පීඩනය ඉහළයි';

  @override
  String get changeLanguage => 'භාෂාව වෙනස් කරන්න';

  @override
  String get roleMotherHint => 'ඔබේ දරුවන්ගේ සෞඛ්‍ය වාර්තාව බලන්න';

  @override
  String get rolePhmHint => 'ක්ෂේත්‍ර සේවය · සංඥා නැතිවත් ක්‍රියා කරයි';

  @override
  String get roleAdminHint => 'සෞ.වෛ.නි. කාර්යාලය · PIN අංකයෙන් ඇතුළු වන්න';

  @override
  String get welcome => 'Little Bloom වෙත සාදරයෙන් පිළිගනිමු';

  @override
  String get welcomeHint => 'මව්වරුන්ගේ සහ දරුවන්ගේ සෞඛ්‍ය වාර්තා';
}
