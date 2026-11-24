import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
    Locale('ta'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Little Bloom'**
  String get appName;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @whoAreYou.
  ///
  /// In en, this message translates to:
  /// **'Who are you?'**
  String get whoAreYou;

  /// No description provided for @roleMother.
  ///
  /// In en, this message translates to:
  /// **'I am a mother'**
  String get roleMother;

  /// No description provided for @rolePhm.
  ///
  /// In en, this message translates to:
  /// **'I am a midwife (PHM)'**
  String get rolePhm;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'I am an admin (MOH office)'**
  String get roleAdmin;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @boy.
  ///
  /// In en, this message translates to:
  /// **'Boy'**
  String get boy;

  /// No description provided for @girl.
  ///
  /// In en, this message translates to:
  /// **'Girl'**
  String get girl;

  /// No description provided for @offlineSaved.
  ///
  /// In en, this message translates to:
  /// **'No signal – saved on this phone'**
  String get offlineSaved;

  /// No description provided for @sendNow.
  ///
  /// In en, this message translates to:
  /// **'Send now'**
  String get sendNow;

  /// Sync screen: how many outbox entries are not sent yet.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Everything is sent} =1{1 change waiting to send} other{{count} changes waiting to send}}'**
  String pendingChanges(int count);

  /// No description provided for @lowBirthWeight.
  ///
  /// In en, this message translates to:
  /// **'Low birth weight (under 2.5 kg)'**
  String get lowBirthWeight;

  /// No description provided for @highBloodPressure.
  ///
  /// In en, this message translates to:
  /// **'Blood pressure is high'**
  String get highBloodPressure;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get changeLanguage;

  /// No description provided for @roleMotherHint.
  ///
  /// In en, this message translates to:
  /// **'See your children\'s health record'**
  String get roleMotherHint;

  /// No description provided for @rolePhmHint.
  ///
  /// In en, this message translates to:
  /// **'Field work · works with no signal'**
  String get rolePhmHint;

  /// No description provided for @roleAdminHint.
  ///
  /// In en, this message translates to:
  /// **'MOH office · sign in with PIN'**
  String get roleAdminHint;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Little Bloom'**
  String get welcome;

  /// No description provided for @welcomeHint.
  ///
  /// In en, this message translates to:
  /// **'Health records for mothers and children'**
  String get welcomeHint;

  /// No description provided for @yourMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Your mobile number'**
  String get yourMobileNumber;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a Sri Lankan mobile number, e.g. 076 482 3310'**
  String get invalidPhone;

  /// No description provided for @phoneNotRegisteredMother.
  ///
  /// In en, this message translates to:
  /// **'This number is not registered. Ask your midwife (PHM) to add it.'**
  String get phoneNotRegisteredMother;

  /// No description provided for @phoneNotRegisteredStaff.
  ///
  /// In en, this message translates to:
  /// **'This number is not registered. Ask the MOH office to add it.'**
  String get phoneNotRegisteredStaff;

  /// No description provided for @noSignal.
  ///
  /// In en, this message translates to:
  /// **'No signal. Try again when you have signal.'**
  String get noSignal;

  /// No description provided for @somethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWrong;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get enterCode;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code by SMS to {phone}'**
  String codeSentTo(String phone);

  /// No description provided for @checkCode.
  ///
  /// In en, this message translates to:
  /// **'Check code'**
  String get checkCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Send the code again'**
  String get resendCode;

  /// No description provided for @wrongCode.
  ///
  /// In en, this message translates to:
  /// **'That code is not right. Check the SMS and try again.'**
  String get wrongCode;

  /// No description provided for @wrongRoleMother.
  ///
  /// In en, this message translates to:
  /// **'This number belongs to a staff account. Go back and choose midwife or MOH office.'**
  String get wrongRoleMother;

  /// No description provided for @wrongRoleStaff.
  ///
  /// In en, this message translates to:
  /// **'This number belongs to a mother. Go back and choose \"I am a mother\".'**
  String get wrongRoleStaff;

  /// No description provided for @setPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a 4-digit PIN'**
  String get setPinTitle;

  /// No description provided for @setPinHelp.
  ///
  /// In en, this message translates to:
  /// **'You will use it to open the app on this phone, even with no signal.'**
  String get setPinHelp;

  /// No description provided for @confirmPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Type the PIN again'**
  String get confirmPinTitle;

  /// No description provided for @pinsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'The two PINs are different. Start again.'**
  String get pinsDoNotMatch;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get enterPin;

  /// Unlock screen: tries left before sign-out.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Wrong PIN. 1 try left.} other{Wrong PIN. {count} tries left.}}'**
  String wrongPin(int count);

  /// No description provided for @pinLockedOut.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong tries. Sign in again with an SMS code.'**
  String get pinLockedOut;

  /// No description provided for @forgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN? Sign in with SMS'**
  String get forgotPin;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @helloName.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String helloName(String name);

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'This part of the app is being built.'**
  String get comingSoon;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @mothersTab.
  ///
  /// In en, this message translates to:
  /// **'Mothers'**
  String get mothersTab;

  /// No description provided for @childrenTab.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get childrenTab;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Name or mobile number'**
  String get searchHint;

  /// No description provided for @visitsDue.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy visits due'**
  String get visitsDue;

  /// No description provided for @childrenToWeigh.
  ///
  /// In en, this message translates to:
  /// **'Children to weigh'**
  String get childrenToWeigh;

  /// No description provided for @toWatch.
  ///
  /// In en, this message translates to:
  /// **'To watch'**
  String get toWatch;

  /// No description provided for @nothingDue.
  ///
  /// In en, this message translates to:
  /// **'Nothing due this week.'**
  String get nothingDue;

  /// No description provided for @lastSyncAt.
  ///
  /// In en, this message translates to:
  /// **'Last sent {time}'**
  String lastSyncAt(String time);

  /// No description provided for @neverSynced.
  ///
  /// In en, this message translates to:
  /// **'Not sent to the server yet'**
  String get neverSynced;

  /// No description provided for @pregnantWeeks.
  ///
  /// In en, this message translates to:
  /// **'Pregnant · {weeks} weeks'**
  String pregnantWeeks(int weeks);

  /// No description provided for @dueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String dueOn(String date);

  /// No description provided for @childrenCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No children} =1{1 child} other{{count} children}}'**
  String childrenCount(int count);

  /// No description provided for @ageMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Newborn} =1{1 month} other{{count} months}}'**
  String ageMonths(int count);

  /// No description provided for @ageYears.
  ///
  /// In en, this message translates to:
  /// **'{years} y {months} m'**
  String ageYears(int years, int months);

  /// No description provided for @pregnancyVisits.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy visits'**
  String get pregnancyVisits;

  /// No description provided for @noVisitsYet.
  ///
  /// In en, this message translates to:
  /// **'No visits recorded yet.'**
  String get noVisitsYet;

  /// No description provided for @noChildrenYet.
  ///
  /// In en, this message translates to:
  /// **'No children registered yet.'**
  String get noChildrenYet;

  /// No description provided for @notSentYet.
  ///
  /// In en, this message translates to:
  /// **'Not sent yet'**
  String get notSentYet;

  /// No description provided for @nextVisitOn.
  ///
  /// In en, this message translates to:
  /// **'Next visit {date}'**
  String nextVisitOn(String date);

  /// No description provided for @daysLate.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day late} other{{count} days late}}'**
  String daysLate(int count);

  /// No description provided for @dueTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueTodayLabel;

  /// No description provided for @dueInDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Tomorrow} other{In {count} days}}'**
  String dueInDays(int count);

  /// No description provided for @neverWeighed.
  ///
  /// In en, this message translates to:
  /// **'Not weighed yet'**
  String get neverWeighed;

  /// No description provided for @lowBirthWeightShort.
  ///
  /// In en, this message translates to:
  /// **'Low birth weight'**
  String get lowBirthWeightShort;

  /// No description provided for @highBpShort.
  ///
  /// In en, this message translates to:
  /// **'High BP'**
  String get highBpShort;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No one found.'**
  String get noResults;

  /// No description provided for @weeksShort.
  ///
  /// In en, this message translates to:
  /// **'{weeks} w'**
  String weeksShort(int weeks);

  /// No description provided for @bpValue.
  ///
  /// In en, this message translates to:
  /// **'BP {systolic}/{diastolic}'**
  String bpValue(int systolic, int diastolic);

  /// No description provided for @kgValue.
  ///
  /// In en, this message translates to:
  /// **'{kg} kg'**
  String kgValue(String kg);

  /// No description provided for @loadSampleData.
  ///
  /// In en, this message translates to:
  /// **'Load sample data (testing only)'**
  String get loadSampleData;

  /// No description provided for @emptyRegister.
  ///
  /// In en, this message translates to:
  /// **'No mothers in your area yet.'**
  String get emptyRegister;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
