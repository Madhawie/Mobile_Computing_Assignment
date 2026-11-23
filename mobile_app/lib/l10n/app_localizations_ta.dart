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
}
