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

  @override
  String get yourMobileNumber => 'Your mobile number';

  @override
  String get sendCode => 'Send code';

  @override
  String get invalidPhone =>
      'Enter a Sri Lankan mobile number, e.g. 076 482 3310';

  @override
  String get phoneNotRegisteredMother =>
      'This number is not registered. Ask your midwife (PHM) to add it.';

  @override
  String get phoneNotRegisteredStaff =>
      'This number is not registered. Ask the MOH office to add it.';

  @override
  String get noSignal => 'No signal. Try again when you have signal.';

  @override
  String get somethingWrong => 'Something went wrong. Please try again.';

  @override
  String get enterCode => 'Enter the code';

  @override
  String codeSentTo(String phone) {
    return 'We sent a 6-digit code by SMS to $phone';
  }

  @override
  String get checkCode => 'Check code';

  @override
  String get resendCode => 'Send the code again';

  @override
  String get wrongCode =>
      'That code is not right. Check the SMS and try again.';

  @override
  String get wrongRoleMother =>
      'This number belongs to a staff account. Go back and choose midwife or MOH office.';

  @override
  String get wrongRoleStaff =>
      'This number belongs to a mother. Go back and choose \"I am a mother\".';

  @override
  String get setPinTitle => 'Choose a 4-digit PIN';

  @override
  String get setPinHelp =>
      'You will use it to open the app on this phone, even with no signal.';

  @override
  String get confirmPinTitle => 'Type the PIN again';

  @override
  String get pinsDoNotMatch => 'The two PINs are different. Start again.';

  @override
  String get enterPin => 'Enter your PIN';

  @override
  String wrongPin(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wrong PIN. $count tries left.',
      one: 'Wrong PIN. 1 try left.',
    );
    return '$_temp0';
  }

  @override
  String get pinLockedOut =>
      'Too many wrong tries. Sign in again with an SMS code.';

  @override
  String get forgotPin => 'Forgot PIN? Sign in with SMS';

  @override
  String get signOut => 'Sign out';

  @override
  String helloName(String name) {
    return 'Hello, $name';
  }

  @override
  String get comingSoon => 'This part of the app is being built.';
}
