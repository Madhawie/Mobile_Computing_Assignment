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

  @override
  String get yourMobileNumber => 'ඔබේ ජංගම දුරකථන අංකය';

  @override
  String get sendCode => 'කේතය යවන්න';

  @override
  String get invalidPhone =>
      'ශ්‍රී ලංකා ජංගම අංකයක් ඇතුළත් කරන්න, උදා. 076 482 3310';

  @override
  String get phoneNotRegisteredMother =>
      'මෙම අංකය ලියාපදිංචි කර නැත. එය එක් කිරීමට ඔබේ පවුල් සෞඛ්‍ය සේවා නිලධාරිනියගෙන් ඉල්ලන්න.';

  @override
  String get phoneNotRegisteredStaff =>
      'මෙම අංකය ලියාපදිංචි කර නැත. එය එක් කිරීමට සෞ.වෛ.නි. කාර්යාලයෙන් ඉල්ලන්න.';

  @override
  String get noSignal => 'සංඥා නැත. සංඥා ලැබුණු විට නැවත උත්සාහ කරන්න.';

  @override
  String get somethingWrong => 'යමක් වැරදී ඇත. කරුණාකර නැවත උත්සාහ කරන්න.';

  @override
  String get enterCode => 'කේතය ඇතුළත් කරන්න';

  @override
  String codeSentTo(String phone) {
    return 'අපි $phone අංකයට ඉලක්කම් 6ක කේතයක් SMS මගින් යැව්වෙමු';
  }

  @override
  String get checkCode => 'කේතය පරීක්ෂා කරන්න';

  @override
  String get resendCode => 'කේතය නැවත යවන්න';

  @override
  String get wrongCode =>
      'එම කේතය නිවැරදි නැත. SMS පණිවිඩය බලා නැවත උත්සාහ කරන්න.';

  @override
  String get wrongRoleMother =>
      'මෙම අංකය කාර්ය මණ්ඩල ගිණුමකට අයත්ය. ආපසු ගොස් PHM හෝ සෞ.වෛ.නි. කාර්යාලය තෝරන්න.';

  @override
  String get wrongRoleStaff =>
      'මෙම අංකය මවකට අයත්ය. ආපසු ගොස් \"මම මවක්\" තෝරන්න.';

  @override
  String get setPinTitle => 'ඉලක්කම් 4ක PIN අංකයක් තෝරන්න';

  @override
  String get setPinHelp =>
      'සංඥා නැති විටත් මෙම දුරකථනයේ යෙදුම විවෘත කිරීමට එය භාවිත කරයි.';

  @override
  String get confirmPinTitle => 'PIN අංකය නැවත ටයිප් කරන්න';

  @override
  String get pinsDoNotMatch => 'PIN අංක දෙක වෙනස්ය. නැවත අරඹන්න.';

  @override
  String get enterPin => 'ඔබේ PIN අංකය ඇතුළත් කරන්න';

  @override
  String wrongPin(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'PIN අංකය වැරදියි. තවත් වතාවක් $count ඉතිරිය.',
      one: 'PIN අංකය වැරදියි. තවත් 1 වතාවක් ඉතිරිය.',
    );
    return '$_temp0';
  }

  @override
  String get pinLockedOut =>
      'වැරදි උත්සාහ වැඩියි. SMS කේතයකින් නැවත ඇතුළු වන්න.';

  @override
  String get forgotPin => 'PIN අමතකද? SMS මගින් ඇතුළු වන්න';

  @override
  String get signOut => 'ඉවත් වන්න';

  @override
  String helloName(String name) {
    return 'ආයුබෝවන්, $name';
  }

  @override
  String get comingSoon => 'යෙදුමේ මෙම කොටස සකසමින් පවතී.';

  @override
  String get today => 'අද';

  @override
  String get register => 'ලේඛනය';

  @override
  String get mothersTab => 'මව්වරු';

  @override
  String get childrenTab => 'දරුවන්';

  @override
  String get searchHint => 'නම හෝ ජංගම අංකය';

  @override
  String get visitsDue => 'නියමිත ගර්භණී සායන/නිවාස සංචාර';

  @override
  String get childrenToWeigh => 'කිරා බැලිය යුතු දරුවන්';

  @override
  String get toWatch => 'අවධානයෙන් සිටිය යුතු';

  @override
  String get nothingDue => 'මෙම සතියේ කිසිවක් නියමිත නැත.';

  @override
  String lastSyncAt(String time) {
    return 'අවසන් වරට යැවූයේ $time';
  }

  @override
  String get neverSynced => 'තවම සේවාදායකයට යවා නැත';

  @override
  String pregnantWeeks(int weeks) {
    return 'ගර්භණී · සති $weeks';
  }

  @override
  String dueOn(String date) {
    return 'නියමිත දිනය $date';
  }

  @override
  String childrenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'දරුවන් $count',
      one: 'දරුවන් 1',
      zero: 'දරුවන් නැත',
    );
    return '$_temp0';
  }

  @override
  String ageMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'මාස $count',
      one: 'මාස 1',
      zero: 'අලුත උපන්',
    );
    return '$_temp0';
  }

  @override
  String ageYears(int years, int months) {
    return 'අවු $years මාස $months';
  }

  @override
  String get pregnancyVisits => 'ගර්භණී සංචාර';

  @override
  String get noVisitsYet => 'තවම සංචාර සටහන් කර නැත.';

  @override
  String get noChildrenYet => 'තවම දරුවන් ලියාපදිංචි කර නැත.';

  @override
  String get notSentYet => 'තවම යවා නැත';

  @override
  String nextVisitOn(String date) {
    return 'ඊළඟ සංචාරය $date';
  }

  @override
  String daysLate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'දින $countක් ප්‍රමාදයි',
      one: 'දින 1ක් ප්‍රමාදයි',
    );
    return '$_temp0';
  }

  @override
  String get dueTodayLabel => 'අද නියමිතයි';

  @override
  String dueInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'දින $countකින්',
      one: 'හෙට',
    );
    return '$_temp0';
  }

  @override
  String get neverWeighed => 'තවම කිරා නැත';

  @override
  String get lowBirthWeightShort => 'අඩු උපත් බර';

  @override
  String get highBpShort => 'අධි රුධිර පීඩනය';

  @override
  String get noResults => 'කිසිවෙකු හමු නොවීය.';

  @override
  String weeksShort(int weeks) {
    return 'සති $weeks';
  }

  @override
  String bpValue(int systolic, int diastolic) {
    return 'රු.පී. $systolic/$diastolic';
  }

  @override
  String kgValue(String kg) {
    return 'කි.ග්‍රෑ. $kg';
  }

  @override
  String get loadSampleData => 'නියැදි දත්ත පූරණය කරන්න (පරීක්ෂණ සඳහා පමණි)';

  @override
  String get emptyRegister => 'ඔබේ ප්‍රදේශයේ තවම මව්වරු නැත.';
}
