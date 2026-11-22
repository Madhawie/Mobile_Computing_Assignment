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
}
