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

  @override
  String get today => 'Today';

  @override
  String get register => 'Register';

  @override
  String get mothersTab => 'Mothers';

  @override
  String get childrenTab => 'Children';

  @override
  String get searchHint => 'Name or mobile number';

  @override
  String get visitsDue => 'Pregnancy visits due';

  @override
  String get childrenToWeigh => 'Children to weigh';

  @override
  String get toWatch => 'To watch';

  @override
  String get nothingDue => 'Nothing due this week.';

  @override
  String lastSyncAt(String time) {
    return 'Last sent $time';
  }

  @override
  String get neverSynced => 'Not sent to the server yet';

  @override
  String pregnantWeeks(int weeks) {
    return 'Pregnant · $weeks weeks';
  }

  @override
  String dueOn(String date) {
    return 'Due $date';
  }

  @override
  String childrenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count children',
      one: '1 child',
      zero: 'No children',
    );
    return '$_temp0';
  }

  @override
  String ageMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
      zero: 'Newborn',
    );
    return '$_temp0';
  }

  @override
  String ageYears(int years, int months) {
    return '$years y $months m';
  }

  @override
  String get pregnancyVisits => 'Pregnancy visits';

  @override
  String get noVisitsYet => 'No visits recorded yet.';

  @override
  String get noChildrenYet => 'No children registered yet.';

  @override
  String get notSentYet => 'Not sent yet';

  @override
  String nextVisitOn(String date) {
    return 'Next visit $date';
  }

  @override
  String daysLate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days late',
      one: '1 day late',
    );
    return '$_temp0';
  }

  @override
  String get dueTodayLabel => 'Due today';

  @override
  String dueInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count days',
      one: 'Tomorrow',
    );
    return '$_temp0';
  }

  @override
  String get neverWeighed => 'Not weighed yet';

  @override
  String get lowBirthWeightShort => 'Low birth weight';

  @override
  String get highBpShort => 'High BP';

  @override
  String get noResults => 'No one found.';

  @override
  String weeksShort(int weeks) {
    return '$weeks w';
  }

  @override
  String bpValue(int systolic, int diastolic) {
    return 'BP $systolic/$diastolic';
  }

  @override
  String kgValue(String kg) {
    return '$kg kg';
  }

  @override
  String get loadSampleData => 'Load sample data (testing only)';

  @override
  String get emptyRegister => 'No mothers in your area yet.';

  @override
  String get addMother => 'Add mother';

  @override
  String get saveMother => 'Save mother';

  @override
  String get saveAndAddChild => 'Save and add a child';

  @override
  String get fullName => 'Full name';

  @override
  String get ageLabel => 'Age';

  @override
  String get addressLabel => 'Address';

  @override
  String get pregnantNow => 'Pregnant now?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get weeksPregnant => 'Weeks pregnant';

  @override
  String get dueDateLabel => 'Due date';

  @override
  String get phoneAlreadyRegistered =>
      'This mobile number is already registered.';

  @override
  String get requiredField => 'Please fill this in';

  @override
  String numberBetween(String min, String max) {
    return 'Enter a number from $min to $max';
  }

  @override
  String get dateInFuture => 'The date cannot be in the future.';

  @override
  String get addChild => 'Add child';

  @override
  String get childName => 'Child\'s name';

  @override
  String get boyOrGirl => 'Boy or girl';

  @override
  String get sexChartHint => 'Sets the blue or pink CHDR growth chart';

  @override
  String get dateOfBirth => 'Date of birth';

  @override
  String get birthWeightKg => 'Birth weight (kg)';

  @override
  String get lowBirthWeightWatch =>
      'Low birth weight (under 2.5 kg). This baby will be on your watch list.';

  @override
  String get olderThanFive => 'Children are followed until 5 years of age.';

  @override
  String get saveChild => 'Save child';

  @override
  String get recordGrowth => 'Record growth';

  @override
  String get weightKgLabel => 'Weight (kg)';

  @override
  String get heightCmLabel => 'Height (cm), optional';

  @override
  String get dateLabel => 'Date';

  @override
  String get zoneNormal => 'Green zone · normal weight for age';

  @override
  String get zoneModerate =>
      'Orange zone · underweight. Give feeding advice and weigh again in 2 weeks.';

  @override
  String get zoneSevere =>
      'Red zone · severely underweight. Refer to the MOH clinic.';

  @override
  String get zoneOverweight => 'Above the green zone · overweight for age';

  @override
  String get zoneUnavailable =>
      'Growth zone not shown: the WHO growth table is not added yet.';

  @override
  String get recordVisit => 'Record pregnancy visit';

  @override
  String get motherWeightKg => 'Mother\'s weight (kg)';

  @override
  String get bpTop => 'BP top number';

  @override
  String get bpBottom => 'BP bottom number';

  @override
  String get bpOrder => 'The top number must be higher than the bottom number.';

  @override
  String get nextVisitLabel => 'Next visit';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get nextVisitAfter => 'The next visit must be after this visit.';

  @override
  String get beforeBirth => 'The date cannot be before the date of birth.';

  @override
  String get recordVaccine => 'Record vaccine';

  @override
  String get vaccineLabel => 'Vaccine';

  @override
  String get doseLabel => 'Dose';

  @override
  String get givenOnLabel => 'Date given';

  @override
  String get batchOptional => 'Batch number (optional)';

  @override
  String get savedOnPhone =>
      'Saved on this phone. It will be sent when there is signal.';

  @override
  String get checkRecords => 'Check a record';

  @override
  String recordsToCheck(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records to check',
      one: '1 record to check',
    );
    return '$_temp0';
  }

  @override
  String get conflictSameField =>
      'Changed on two phones at the same time. The newer value is kept; the other is saved.';

  @override
  String get conflictDeleteVsUpdate =>
      'Deleted on one phone but changed on another. The record was kept.';

  @override
  String valueNow(String value) {
    return 'Now: $value';
  }

  @override
  String otherValueFrom(String source, String value) {
    return 'Other value ($source): $value';
  }

  @override
  String get fromYourPhone => 'your phone';

  @override
  String get fromOtherDevice => 'another phone';

  @override
  String get keepCurrent => 'Keep as it is';

  @override
  String get useOtherValue => 'Use the other value';

  @override
  String get nothingToCheck => 'Nothing to check. All records agree.';

  @override
  String get needSignalToDecide =>
      'You need signal to decide. Try again when you have signal.';

  @override
  String get shownFromPhone =>
      'Shown from this phone. Pull down to update when you have signal.';

  @override
  String get decisionSaved => 'Saved. Other phones get it at their next sync.';

  @override
  String get deletedLabel => 'Deleted';

  @override
  String get emptyValue => '(empty)';
}
