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

  /// No description provided for @addMother.
  ///
  /// In en, this message translates to:
  /// **'Add mother'**
  String get addMother;

  /// No description provided for @saveMother.
  ///
  /// In en, this message translates to:
  /// **'Save mother'**
  String get saveMother;

  /// No description provided for @saveAndAddChild.
  ///
  /// In en, this message translates to:
  /// **'Save and add a child'**
  String get saveAndAddChild;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageLabel;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @pregnantNow.
  ///
  /// In en, this message translates to:
  /// **'Pregnant now?'**
  String get pregnantNow;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @weeksPregnant.
  ///
  /// In en, this message translates to:
  /// **'Weeks pregnant'**
  String get weeksPregnant;

  /// No description provided for @dueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDateLabel;

  /// No description provided for @phoneAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This mobile number is already registered.'**
  String get phoneAlreadyRegistered;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Please fill this in'**
  String get requiredField;

  /// No description provided for @numberBetween.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from {min} to {max}'**
  String numberBetween(String min, String max);

  /// No description provided for @dateInFuture.
  ///
  /// In en, this message translates to:
  /// **'The date cannot be in the future.'**
  String get dateInFuture;

  /// No description provided for @addChild.
  ///
  /// In en, this message translates to:
  /// **'Add child'**
  String get addChild;

  /// No description provided for @childName.
  ///
  /// In en, this message translates to:
  /// **'Child\'s name'**
  String get childName;

  /// No description provided for @boyOrGirl.
  ///
  /// In en, this message translates to:
  /// **'Boy or girl'**
  String get boyOrGirl;

  /// No description provided for @sexChartHint.
  ///
  /// In en, this message translates to:
  /// **'Sets the blue or pink CHDR growth chart'**
  String get sexChartHint;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirth;

  /// No description provided for @birthWeightKg.
  ///
  /// In en, this message translates to:
  /// **'Birth weight (kg)'**
  String get birthWeightKg;

  /// No description provided for @lowBirthWeightWatch.
  ///
  /// In en, this message translates to:
  /// **'Low birth weight (under 2.5 kg). This baby will be on your watch list.'**
  String get lowBirthWeightWatch;

  /// No description provided for @olderThanFive.
  ///
  /// In en, this message translates to:
  /// **'Children are followed until 5 years of age.'**
  String get olderThanFive;

  /// No description provided for @saveChild.
  ///
  /// In en, this message translates to:
  /// **'Save child'**
  String get saveChild;

  /// No description provided for @recordGrowth.
  ///
  /// In en, this message translates to:
  /// **'Record growth'**
  String get recordGrowth;

  /// No description provided for @weightKgLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightKgLabel;

  /// No description provided for @heightCmLabel.
  ///
  /// In en, this message translates to:
  /// **'Height (cm), optional'**
  String get heightCmLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @zoneNormal.
  ///
  /// In en, this message translates to:
  /// **'Green zone · normal weight for age'**
  String get zoneNormal;

  /// No description provided for @zoneModerate.
  ///
  /// In en, this message translates to:
  /// **'Orange zone · underweight. Give feeding advice and weigh again in 2 weeks.'**
  String get zoneModerate;

  /// No description provided for @zoneSevere.
  ///
  /// In en, this message translates to:
  /// **'Red zone · severely underweight. Refer to the MOH clinic.'**
  String get zoneSevere;

  /// No description provided for @zoneOverweight.
  ///
  /// In en, this message translates to:
  /// **'Above the green zone · overweight for age'**
  String get zoneOverweight;

  /// No description provided for @zoneUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Growth zone not shown: the WHO growth table is not added yet.'**
  String get zoneUnavailable;

  /// No description provided for @recordVisit.
  ///
  /// In en, this message translates to:
  /// **'Record pregnancy visit'**
  String get recordVisit;

  /// No description provided for @motherWeightKg.
  ///
  /// In en, this message translates to:
  /// **'Mother\'s weight (kg)'**
  String get motherWeightKg;

  /// No description provided for @bpTop.
  ///
  /// In en, this message translates to:
  /// **'BP top number'**
  String get bpTop;

  /// No description provided for @bpBottom.
  ///
  /// In en, this message translates to:
  /// **'BP bottom number'**
  String get bpBottom;

  /// No description provided for @bpOrder.
  ///
  /// In en, this message translates to:
  /// **'The top number must be higher than the bottom number.'**
  String get bpOrder;

  /// No description provided for @nextVisitLabel.
  ///
  /// In en, this message translates to:
  /// **'Next visit'**
  String get nextVisitLabel;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @nextVisitAfter.
  ///
  /// In en, this message translates to:
  /// **'The next visit must be after this visit.'**
  String get nextVisitAfter;

  /// No description provided for @beforeBirth.
  ///
  /// In en, this message translates to:
  /// **'The date cannot be before the date of birth.'**
  String get beforeBirth;

  /// No description provided for @recordVaccine.
  ///
  /// In en, this message translates to:
  /// **'Record vaccine'**
  String get recordVaccine;

  /// No description provided for @vaccineLabel.
  ///
  /// In en, this message translates to:
  /// **'Vaccine'**
  String get vaccineLabel;

  /// No description provided for @doseLabel.
  ///
  /// In en, this message translates to:
  /// **'Dose'**
  String get doseLabel;

  /// No description provided for @givenOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Date given'**
  String get givenOnLabel;

  /// No description provided for @batchOptional.
  ///
  /// In en, this message translates to:
  /// **'Batch number (optional)'**
  String get batchOptional;

  /// No description provided for @savedOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone. It will be sent when there is signal.'**
  String get savedOnPhone;

  /// No description provided for @checkRecords.
  ///
  /// In en, this message translates to:
  /// **'Check a record'**
  String get checkRecords;

  /// No description provided for @recordsToCheck.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 record to check} other{{count} records to check}}'**
  String recordsToCheck(int count);

  /// No description provided for @conflictSameField.
  ///
  /// In en, this message translates to:
  /// **'Changed on two phones at the same time. The newer value is kept; the other is saved.'**
  String get conflictSameField;

  /// No description provided for @conflictDeleteVsUpdate.
  ///
  /// In en, this message translates to:
  /// **'Deleted on one phone but changed on another. The record was kept.'**
  String get conflictDeleteVsUpdate;

  /// No description provided for @valueNow.
  ///
  /// In en, this message translates to:
  /// **'Now: {value}'**
  String valueNow(String value);

  /// No description provided for @otherValueFrom.
  ///
  /// In en, this message translates to:
  /// **'Other value ({source}): {value}'**
  String otherValueFrom(String source, String value);

  /// No description provided for @fromYourPhone.
  ///
  /// In en, this message translates to:
  /// **'your phone'**
  String get fromYourPhone;

  /// No description provided for @fromOtherDevice.
  ///
  /// In en, this message translates to:
  /// **'another phone'**
  String get fromOtherDevice;

  /// No description provided for @keepCurrent.
  ///
  /// In en, this message translates to:
  /// **'Keep as it is'**
  String get keepCurrent;

  /// No description provided for @useOtherValue.
  ///
  /// In en, this message translates to:
  /// **'Use the other value'**
  String get useOtherValue;

  /// No description provided for @nothingToCheck.
  ///
  /// In en, this message translates to:
  /// **'Nothing to check. All records agree.'**
  String get nothingToCheck;

  /// No description provided for @needSignalToDecide.
  ///
  /// In en, this message translates to:
  /// **'You need signal to decide. Try again when you have signal.'**
  String get needSignalToDecide;

  /// No description provided for @shownFromPhone.
  ///
  /// In en, this message translates to:
  /// **'Shown from this phone. Pull down to update when you have signal.'**
  String get shownFromPhone;

  /// No description provided for @decisionSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved. Other phones get it at their next sync.'**
  String get decisionSaved;

  /// No description provided for @deletedLabel.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deletedLabel;

  /// No description provided for @emptyValue.
  ///
  /// In en, this message translates to:
  /// **'(empty)'**
  String get emptyValue;
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
