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
}
