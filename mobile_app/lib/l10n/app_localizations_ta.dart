// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appName => 'Little Bloom';

  @override
  String get chooseLanguage => 'உங்கள் மொழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get whoAreYou => 'நீங்கள் யார்?';

  @override
  String get roleMother => 'நான் ஒரு தாய்';

  @override
  String get rolePhm => 'நான் குடும்பநல உத்தியோகத்தர் (PHM)';

  @override
  String get roleAdmin => 'நான் நிர்வாகி (சுகாதார வைத்திய அதிகாரி அலுவலகம்)';

  @override
  String get continueLabel => 'தொடரவும்';

  @override
  String get save => 'சேமிக்கவும்';

  @override
  String get cancel => 'ரத்துசெய்';

  @override
  String get boy => 'ஆண் குழந்தை';

  @override
  String get girl => 'பெண் குழந்தை';

  @override
  String get offlineSaved =>
      'சிக்னல் இல்லை – இந்தத் தொலைபேசியில் சேமிக்கப்பட்டது';

  @override
  String get sendNow => 'இப்போது அனுப்பு';

  @override
  String pendingChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count மாற்றங்கள் அனுப்பக் காத்திருக்கின்றன',
      one: '1 மாற்றம் அனுப்பக் காத்திருக்கிறது',
      zero: 'அனைத்தும் அனுப்பப்பட்டது',
    );
    return '$_temp0';
  }

  @override
  String get lowBirthWeight => 'குறைந்த பிறப்பு எடை (2.5 கி.கி.க்கு குறைவு)';

  @override
  String get highBloodPressure => 'இரத்த அழுத்தம் அதிகமாக உள்ளது';

  @override
  String get changeLanguage => 'மொழியை மாற்று';

  @override
  String get roleMotherHint =>
      'உங்கள் பிள்ளைகளின் சுகாதாரப் பதிவைப் பார்க்கவும்';

  @override
  String get rolePhmHint => 'களப்பணி · சிக்னல் இல்லாமலும் இயங்கும்';

  @override
  String get roleAdminHint => 'சு.வை.அ. அலுவலகம் · PIN மூலம் உள்நுழைக';

  @override
  String get welcome => 'Little Bloom-க்கு வரவேற்கிறோம்';

  @override
  String get welcomeHint => 'தாய்மார் மற்றும் பிள்ளைகளின் சுகாதாரப் பதிவுகள்';

  @override
  String get yourMobileNumber => 'உங்கள் கைபேசி இலக்கம்';

  @override
  String get sendCode => 'குறியீட்டை அனுப்பு';

  @override
  String get invalidPhone =>
      'இலங்கை கைபேசி இலக்கத்தை உள்ளிடவும், எ.கா. 076 482 3310';

  @override
  String get phoneNotRegisteredMother =>
      'இந்த இலக்கம் பதிவு செய்யப்படவில்லை. அதைச் சேர்க்க உங்கள் குடும்பநல உத்தியோகத்தரிடம் கேளுங்கள்.';

  @override
  String get phoneNotRegisteredStaff =>
      'இந்த இலக்கம் பதிவு செய்யப்படவில்லை. அதைச் சேர்க்க சு.வை.அ. அலுவலகத்திடம் கேளுங்கள்.';

  @override
  String get noSignal =>
      'சிக்னல் இல்லை. சிக்னல் கிடைத்ததும் மீண்டும் முயற்சிக்கவும்.';

  @override
  String get somethingWrong => 'ஏதோ தவறு நடந்தது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get enterCode => 'குறியீட்டை உள்ளிடவும்';

  @override
  String codeSentTo(String phone) {
    return '$phone இலக்கத்திற்கு 6 இலக்கக் குறியீட்டை SMS மூலம் அனுப்பினோம்';
  }

  @override
  String get checkCode => 'குறியீட்டைச் சரிபார்';

  @override
  String get resendCode => 'குறியீட்டை மீண்டும் அனுப்பு';

  @override
  String get wrongCode =>
      'அந்தக் குறியீடு சரியில்லை. SMS-ஐப் பார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get wrongRoleMother =>
      'இந்த இலக்கம் ஊழியர் கணக்கிற்கு உரியது. திரும்பிச் சென்று PHM அல்லது சு.வை.அ. அலுவலகத்தைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get wrongRoleStaff =>
      'இந்த இலக்கம் ஒரு தாய்க்கு உரியது. திரும்பிச் சென்று \"நான் ஒரு தாய்\" என்பதைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get setPinTitle => '4 இலக்க PIN-ஐத் தேர்ந்தெடுக்கவும்';

  @override
  String get setPinHelp =>
      'சிக்னல் இல்லாதபோதும் இந்தத் தொலைபேசியில் செயலியைத் திறக்க இதைப் பயன்படுத்துவீர்கள்.';

  @override
  String get confirmPinTitle => 'PIN-ஐ மீண்டும் தட்டச்சு செய்யவும்';

  @override
  String get pinsDoNotMatch =>
      'இரண்டு PIN-களும் வேறுபட்டவை. மீண்டும் தொடங்கவும்.';

  @override
  String get enterPin => 'உங்கள் PIN-ஐ உள்ளிடவும்';

  @override
  String wrongPin(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'தவறான PIN. இன்னும் $count முயற்சிகள் உள்ளன.',
      one: 'தவறான PIN. இன்னும் 1 முயற்சி உள்ளது.',
    );
    return '$_temp0';
  }

  @override
  String get pinLockedOut =>
      'அதிகமான தவறான முயற்சிகள். SMS குறியீட்டுடன் மீண்டும் உள்நுழையவும்.';

  @override
  String get forgotPin => 'PIN மறந்துவிட்டதா? SMS மூலம் உள்நுழைக';

  @override
  String get signOut => 'வெளியேறு';

  @override
  String helloName(String name) {
    return 'வணக்கம், $name';
  }

  @override
  String get comingSoon => 'செயலியின் இந்தப் பகுதி உருவாக்கப்பட்டு வருகிறது.';

  @override
  String get today => 'இன்று';

  @override
  String get register => 'பதிவேடு';

  @override
  String get mothersTab => 'தாய்மார்';

  @override
  String get childrenTab => 'பிள்ளைகள்';

  @override
  String get searchHint => 'பெயர் அல்லது கைபேசி இலக்கம்';

  @override
  String get visitsDue => 'நிலுவையிலுள்ள கர்ப்பகால வருகைகள்';

  @override
  String get childrenToWeigh => 'நிறை அளக்க வேண்டிய பிள்ளைகள்';

  @override
  String get toWatch => 'கவனிக்க வேண்டியவை';

  @override
  String get nothingDue => 'இந்த வாரம் எதுவும் நிலுவையில் இல்லை.';

  @override
  String lastSyncAt(String time) {
    return 'கடைசியாக அனுப்பியது $time';
  }

  @override
  String get neverSynced => 'இன்னும் சேவையகத்திற்கு அனுப்பப்படவில்லை';

  @override
  String pregnantWeeks(int weeks) {
    return 'கர்ப்பம் · $weeks வாரங்கள்';
  }

  @override
  String dueOn(String date) {
    return 'எதிர்பார்க்கும் திகதி $date';
  }

  @override
  String childrenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count பிள்ளைகள்',
      one: '1 பிள்ளை',
      zero: 'பிள்ளைகள் இல்லை',
    );
    return '$_temp0';
  }

  @override
  String ageMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count மாதங்கள்',
      one: '1 மாதம்',
      zero: 'புதிதாகப் பிறந்தது',
    );
    return '$_temp0';
  }

  @override
  String ageYears(int years, int months) {
    return '$years வ $months மா';
  }

  @override
  String get pregnancyVisits => 'கர்ப்பகால வருகைகள்';

  @override
  String get noVisitsYet => 'இன்னும் வருகைகள் பதிவு செய்யப்படவில்லை.';

  @override
  String get noChildrenYet => 'இன்னும் பிள்ளைகள் பதிவு செய்யப்படவில்லை.';

  @override
  String get notSentYet => 'இன்னும் அனுப்பப்படவில்லை';

  @override
  String nextVisitOn(String date) {
    return 'அடுத்த வருகை $date';
  }

  @override
  String daysLate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count நாட்கள் தாமதம்',
      one: '1 நாள் தாமதம்',
    );
    return '$_temp0';
  }

  @override
  String get dueTodayLabel => 'இன்று நிலுவை';

  @override
  String dueInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count நாட்களில்',
      one: 'நாளை',
    );
    return '$_temp0';
  }

  @override
  String get neverWeighed => 'இன்னும் நிறை அளக்கப்படவில்லை';

  @override
  String get lowBirthWeightShort => 'குறைந்த பிறப்பு எடை';

  @override
  String get highBpShort => 'உயர் இரத்த அழுத்தம்';

  @override
  String get noResults => 'யாரும் கிடைக்கவில்லை.';

  @override
  String weeksShort(int weeks) {
    return '$weeks வா';
  }

  @override
  String bpValue(int systolic, int diastolic) {
    return 'இ.அ. $systolic/$diastolic';
  }

  @override
  String kgValue(String kg) {
    return '$kg கி.கி.';
  }

  @override
  String get loadSampleData => 'மாதிரித் தரவை ஏற்று (சோதனைக்கு மட்டும்)';

  @override
  String get emptyRegister => 'உங்கள் பகுதியில் இன்னும் தாய்மார் இல்லை.';

  @override
  String get addMother => 'தாயைச் சேர்';

  @override
  String get saveMother => 'தாயைச் சேமி';

  @override
  String get saveAndAddChild => 'சேமித்து பிள்ளையைச் சேர்';

  @override
  String get fullName => 'முழுப் பெயர்';

  @override
  String get ageLabel => 'வயது';

  @override
  String get addressLabel => 'முகவரி';

  @override
  String get pregnantNow => 'இப்போது கர்ப்பமா?';

  @override
  String get yes => 'ஆம்';

  @override
  String get no => 'இல்லை';

  @override
  String get weeksPregnant => 'கர்ப்ப வாரங்கள்';

  @override
  String get dueDateLabel => 'எதிர்பார்க்கும் பிரசவ திகதி';

  @override
  String get phoneAlreadyRegistered =>
      'இந்தக் கைபேசி இலக்கம் ஏற்கனவே பதிவு செய்யப்பட்டுள்ளது.';

  @override
  String get requiredField => 'தயவுசெய்து இதை நிரப்பவும்';

  @override
  String numberBetween(String min, String max) {
    return '$min முதல் $max வரையான எண்ணை உள்ளிடவும்';
  }

  @override
  String get dateInFuture => 'திகதி எதிர்காலத்தில் இருக்க முடியாது.';

  @override
  String get addChild => 'பிள்ளையைச் சேர்';

  @override
  String get childName => 'பிள்ளையின் பெயர்';

  @override
  String get boyOrGirl => 'ஆண் அல்லது பெண்';

  @override
  String get sexChartHint =>
      'நீல அல்லது இளஞ்சிவப்பு CHDR வளர்ச்சி அட்டவணையைத் தீர்மானிக்கும்';

  @override
  String get dateOfBirth => 'பிறந்த திகதி';

  @override
  String get birthWeightKg => 'பிறப்பு எடை (கி.கி.)';

  @override
  String get lowBirthWeightWatch =>
      'குறைந்த பிறப்பு எடை (2.5 கி.கி.க்கு குறைவு). இந்தக் குழந்தை உங்கள் கவனிப்புப் பட்டியலில் சேர்க்கப்படும்.';

  @override
  String get olderThanFive =>
      'பிள்ளைகள் 5 வயது வரை மட்டுமே கண்காணிக்கப்படுவர்.';

  @override
  String get saveChild => 'பிள்ளையைச் சேமி';

  @override
  String get recordGrowth => 'வளர்ச்சியைப் பதிவு செய்';

  @override
  String get weightKgLabel => 'எடை (கி.கி.)';

  @override
  String get heightCmLabel => 'உயரம் (செ.மீ.), விரும்பினால்';

  @override
  String get dateLabel => 'திகதி';

  @override
  String get zoneNormal => 'பச்சை வலயம் · வயதுக்கேற்ற எடை';

  @override
  String get zoneModerate =>
      'செம்மஞ்சள் வலயம் · எடை குறைவு. உணவு ஆலோசனை வழங்கி 2 வாரங்களில் மீண்டும் நிறுக்கவும்.';

  @override
  String get zoneSevere =>
      'சிவப்பு வலயம் · மிகக் குறைந்த எடை. சு.வை.அ. சிகிச்சை நிலையத்திற்கு அனுப்பவும்.';

  @override
  String get zoneOverweight => 'பச்சை வலயத்திற்கு மேல் · வயதுக்கு அதிக எடை';

  @override
  String get zoneUnavailable =>
      'வளர்ச்சி வலயம் காட்டப்படவில்லை: WHO வளர்ச்சி அட்டவணை இன்னும் சேர்க்கப்படவில்லை.';

  @override
  String get recordVisit => 'கர்ப்பகால வருகையைப் பதிவு செய்';

  @override
  String get motherWeightKg => 'தாயின் எடை (கி.கி.)';

  @override
  String get bpTop => 'இ.அ. மேல் எண்';

  @override
  String get bpBottom => 'இ.அ. கீழ் எண்';

  @override
  String get bpOrder => 'மேல் எண் கீழ் எண்ணை விட அதிகமாக இருக்க வேண்டும்.';

  @override
  String get nextVisitLabel => 'அடுத்த வருகை';

  @override
  String get notesOptional => 'குறிப்புகள் (விரும்பினால்)';

  @override
  String get nextVisitAfter =>
      'அடுத்த வருகை இந்த வருகைக்குப் பிறகு இருக்க வேண்டும்.';

  @override
  String get beforeBirth => 'திகதி பிறந்த திகதிக்கு முன் இருக்க முடியாது.';

  @override
  String get recordVaccine => 'தடுப்பூசியைப் பதிவு செய்';

  @override
  String get vaccineLabel => 'தடுப்பூசி';

  @override
  String get doseLabel => 'அளவு';

  @override
  String get givenOnLabel => 'வழங்கிய திகதி';

  @override
  String get batchOptional => 'தொகுதி இலக்கம் (விரும்பினால்)';

  @override
  String get savedOnPhone =>
      'இந்தத் தொலைபேசியில் சேமிக்கப்பட்டது. சிக்னல் கிடைத்ததும் அனுப்பப்படும்.';

  @override
  String get checkRecords => 'பதிவைச் சரிபார்';

  @override
  String recordsToCheck(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'சரிபார்க்க வேண்டிய $count பதிவுகள்',
      one: 'சரிபார்க்க வேண்டிய 1 பதிவு',
    );
    return '$_temp0';
  }

  @override
  String get conflictSameField =>
      'இரண்டு தொலைபேசிகளில் ஒரே நேரத்தில் மாற்றப்பட்டது. புதிய மதிப்பு வைக்கப்பட்டது; மற்றது சேமிக்கப்பட்டது.';

  @override
  String get conflictDeleteVsUpdate =>
      'ஒரு தொலைபேசியில் நீக்கப்பட்டு மற்றொன்றில் மாற்றப்பட்டது. பதிவு வைக்கப்பட்டது.';

  @override
  String valueNow(String value) {
    return 'இப்போது: $value';
  }

  @override
  String otherValueFrom(String source, String value) {
    return 'மற்ற மதிப்பு ($source): $value';
  }

  @override
  String get fromYourPhone => 'உங்கள் தொலைபேசி';

  @override
  String get fromOtherDevice => 'வேறொரு தொலைபேசி';

  @override
  String get keepCurrent => 'அப்படியே வை';

  @override
  String get useOtherValue => 'மற்ற மதிப்பைப் பயன்படுத்து';

  @override
  String get nothingToCheck =>
      'சரிபார்க்க எதுவும் இல்லை. எல்லாப் பதிவுகளும் ஒத்துப்போகின்றன.';

  @override
  String get needSignalToDecide =>
      'தீர்மானிக்க சிக்னல் தேவை. சிக்னல் கிடைத்ததும் மீண்டும் முயற்சிக்கவும்.';

  @override
  String get shownFromPhone =>
      'இந்தத் தொலைபேசியிலிருந்து காட்டப்படுகிறது. சிக்னல் இருக்கும்போது புதுப்பிக்க கீழே இழுக்கவும்.';

  @override
  String get decisionSaved =>
      'சேமிக்கப்பட்டது. மற்ற தொலைபேசிகளுக்கு அடுத்த ஒத்திசைவில் கிடைக்கும்.';

  @override
  String get deletedLabel => 'நீக்கப்பட்டது';

  @override
  String get emptyValue => '(வெறுமை)';
}
