// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Little Bloom';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get whoAreYou => 'Who are you?';

  @override
  String get roleMother => 'I am a mother';

  @override
  String get rolePhm => 'I am a midwife (PHM)';

  @override
  String get roleAdmin => 'I am an admin (MOH office)';

  @override
  String get continueLabel => 'Continue';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get boy => 'Boy';

  @override
  String get girl => 'Girl';

  @override
  String get offlineSaved => 'No signal – saved on this phone';

  @override
  String get sendNow => 'Send now';

  @override
  String pendingChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting to send',
      one: '1 change waiting to send',
      zero: 'Everything is sent',
    );
    return '$_temp0';
  }

  @override
  String get lowBirthWeight => 'Low birth weight (under 2.5 kg)';

  @override
  String get highBloodPressure => 'Blood pressure is high';

  @override
  String get changeLanguage => 'Change language';

  @override
  String get roleMotherHint => 'See your children\'s health record';

  @override
  String get rolePhmHint => 'Field work · works with no signal';

  @override
  String get roleAdminHint => 'MOH office · sign in with PIN';

  @override
  String get welcome => 'Welcome to Little Bloom';

  @override
  String get welcomeHint => 'Health records for mothers and children';
}
