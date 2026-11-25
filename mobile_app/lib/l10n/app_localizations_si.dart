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

  @override
  String get addMother => 'මවක් එක් කරන්න';

  @override
  String get saveMother => 'මව සුරකින්න';

  @override
  String get saveAndAddChild => 'සුරකා දරුවෙකු එක් කරන්න';

  @override
  String get fullName => 'සම්පූර්ණ නම';

  @override
  String get ageLabel => 'වයස';

  @override
  String get addressLabel => 'ලිපිනය';

  @override
  String get pregnantNow => 'දැන් ගර්භණීද?';

  @override
  String get yes => 'ඔව්';

  @override
  String get no => 'නැත';

  @override
  String get weeksPregnant => 'ගර්භණී සති';

  @override
  String get dueDateLabel => 'අපේක්ෂිත දරු ප්‍රසූත දිනය';

  @override
  String get phoneAlreadyRegistered =>
      'මෙම ජංගම අංකය දැනටමත් ලියාපදිංචි කර ඇත.';

  @override
  String get requiredField => 'කරුණාකර මෙය පුරවන්න';

  @override
  String numberBetween(String min, String max) {
    return '$min සිට $max දක්වා අංකයක් ඇතුළත් කරන්න';
  }

  @override
  String get dateInFuture => 'දිනය අනාගත දිනයක් විය නොහැක.';

  @override
  String get addChild => 'දරුවෙකු එක් කරන්න';

  @override
  String get childName => 'දරුවාගේ නම';

  @override
  String get boyOrGirl => 'පිරිමි ළමයෙක්ද ගැහැණු ළමයෙක්ද';

  @override
  String get sexChartHint => 'නිල් හෝ රෝස CHDR වර්ධන සටහන තීරණය කරයි';

  @override
  String get dateOfBirth => 'උපන් දිනය';

  @override
  String get birthWeightKg => 'උපත් බර (කි.ග්‍රෑ.)';

  @override
  String get lowBirthWeightWatch =>
      'අඩු උපත් බර (කි.ග්‍රෑ. 2.5ට අඩු). මෙම බිළිඳා ඔබේ අවධාන ලැයිස්තුවට එක් වේ.';

  @override
  String get olderThanFive => 'දරුවන් අවුරුදු 5 දක්වා පමණක් අධීක්ෂණය කෙරේ.';

  @override
  String get saveChild => 'දරුවා සුරකින්න';

  @override
  String get recordGrowth => 'වර්ධනය සටහන් කරන්න';

  @override
  String get weightKgLabel => 'බර (කි.ග්‍රෑ.)';

  @override
  String get heightCmLabel => 'උස (සෙ.මී.), අවශ්‍ය නම්';

  @override
  String get dateLabel => 'දිනය';

  @override
  String get zoneNormal => 'කොළ කලාපය · වයසට සරිලන බර';

  @override
  String get zoneModerate =>
      'තැඹිලි කලාපය · බර අඩුයි. පෝෂණ උපදෙස් දී සති 2කින් නැවත කිරන්න.';

  @override
  String get zoneSevere =>
      'රතු කලාපය · බර ඉතා අඩුයි. සෞ.වෛ.නි. සායනයට යොමු කරන්න.';

  @override
  String get zoneOverweight => 'කොළ කලාපයට ඉහළින් · වයසට බර වැඩියි';

  @override
  String get zoneUnavailable =>
      'වර්ධන කලාපය පෙන්වා නැත: WHO වර්ධන වගුව තවම එක් කර නැත.';

  @override
  String get recordVisit => 'ගර්භණී සංචාරය සටහන් කරන්න';

  @override
  String get motherWeightKg => 'මවගේ බර (කි.ග්‍රෑ.)';

  @override
  String get bpTop => 'රු.පී. ඉහළ අගය';

  @override
  String get bpBottom => 'රු.පී. පහළ අගය';

  @override
  String get bpOrder => 'ඉහළ අගය පහළ අගයට වඩා වැඩි විය යුතුය.';

  @override
  String get nextVisitLabel => 'ඊළඟ සංචාරය';

  @override
  String get notesOptional => 'සටහන් (අවශ්‍ය නම්)';

  @override
  String get nextVisitAfter => 'ඊළඟ සංචාරය මෙම සංචාරයට පසු විය යුතුය.';

  @override
  String get beforeBirth => 'දිනය උපන් දිනයට පෙර විය නොහැක.';

  @override
  String get recordVaccine => 'එන්නත සටහන් කරන්න';

  @override
  String get vaccineLabel => 'එන්නත';

  @override
  String get doseLabel => 'මාත්‍රාව';

  @override
  String get givenOnLabel => 'ලබා දුන් දිනය';

  @override
  String get batchOptional => 'කාණ්ඩ අංකය (අවශ්‍ය නම්)';

  @override
  String get savedOnPhone =>
      'මෙම දුරකථනයේ සුරැකිණි. සංඥා ලැබුණු විට යවනු ලැබේ.';

  @override
  String get checkRecords => 'වාර්තාවක් පරීක්ෂා කරන්න';

  @override
  String recordsToCheck(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'පරීක්ෂා කළ යුතු වාර්තා $count',
      one: 'පරීක්ෂා කළ යුතු වාර්තා 1',
    );
    return '$_temp0';
  }

  @override
  String get conflictSameField =>
      'දුරකථන දෙකක එකම වේලාවේ වෙනස් කර ඇත. අලුත් අගය තබා ඇත; අනෙක සුරැකී ඇත.';

  @override
  String get conflictDeleteVsUpdate =>
      'එක් දුරකථනයක මකා, තවත් එකක වෙනස් කර ඇත. වාර්තාව තබා ඇත.';

  @override
  String valueNow(String value) {
    return 'දැන්: $value';
  }

  @override
  String otherValueFrom(String source, String value) {
    return 'අනෙක් අගය ($source): $value';
  }

  @override
  String get fromYourPhone => 'ඔබේ දුරකථනය';

  @override
  String get fromOtherDevice => 'වෙනත් දුරකථනයක්';

  @override
  String get keepCurrent => 'එලෙසම තබන්න';

  @override
  String get useOtherValue => 'අනෙක් අගය භාවිත කරන්න';

  @override
  String get nothingToCheck =>
      'පරීක්ෂා කිරීමට කිසිවක් නැත. සියලු වාර්තා එකඟයි.';

  @override
  String get needSignalToDecide =>
      'තීරණය කිරීමට සංඥා අවශ්‍යයි. සංඥා ලැබුණු විට නැවත උත්සාහ කරන්න.';

  @override
  String get shownFromPhone =>
      'මෙම දුරකථනයෙන් පෙන්වයි. සංඥා ඇති විට යාවත්කාලීන කිරීමට පහළට අදින්න.';

  @override
  String get decisionSaved =>
      'සුරැකිණි. අනෙක් දුරකථනවලට ඊළඟ සමමුහුර්තයේදී ලැබේ.';

  @override
  String get deletedLabel => 'මකා ඇත';

  @override
  String get emptyValue => '(හිස්)';

  @override
  String get syncTab => 'සමමුහුර්තය';

  @override
  String get syncSubtitle => 'වාර්තා මුලින්ම මෙම දුරකථනයේ සුරැකේ';

  @override
  String get youAreOffline => 'ඔබ නොබැඳි ය';

  @override
  String get youAreOnline => 'සංඥා ඇත';

  @override
  String get sending => 'යවමින්…';

  @override
  String get waitingToSend => 'යැවීමට ඉතිරිව ඇත';

  @override
  String get notAccepted => 'සේවාදායකය පිළිගත්තේ නැත';

  @override
  String get notAcceptedHelp => 'මෙම වාර්තා පරීක්ෂා කර නැවත සුරකින්න.';

  @override
  String get sendAutomatically => 'ස්වයංක්‍රීයව යවන්න';

  @override
  String get sendAutomaticallyHelp => 'සංඥා ලැබුණු විගසම';

  @override
  String syncDoneSummary(int sent, int received) {
    return 'යැවූ $sent, ලැබුණු $received.';
  }

  @override
  String get syncFailed =>
      'සේවාදායකයට සම්බන්ධ විය නොහැක. ඔබේ වෙනස්කම් මෙම දුරකථනයේ ආරක්ෂිතව ඇති අතර ඊළඟ වර යැවේ.';

  @override
  String get kindMother => 'මව';

  @override
  String get kindVisit => 'ගර්භණී සායන පැමිණීම';

  @override
  String get kindChild => 'දරුවා';

  @override
  String get kindGrowth => 'වර්ධනය';

  @override
  String get kindVaccine => 'එන්නත';

  @override
  String get tabHome => 'මුල් පිටුව';

  @override
  String get tabGrowth => 'වර්ධනය';

  @override
  String get tabVaccines => 'එන්නත්';

  @override
  String get tabAdvice => 'උපදෙස්';

  @override
  String get myChildren => 'මගේ දරුවන්';

  @override
  String get comingUp => 'ඉදිරියට';

  @override
  String get myPregnancy => 'මගේ ගර්භණීභාවය';

  @override
  String weeksPregnantNow(int weeks) {
    return 'සති $weeks ගර්භණී';
  }

  @override
  String tipFor(String name) {
    return '$name සඳහා උපදෙසක්';
  }

  @override
  String get call1990 => '1990 අමතන්න · සුව සැරිය ගිලන් රථය';

  @override
  String get dialFailed => 'දුරකථන යෙදුම විවෘත කළ නොහැක. කරුණාකර 1990 අමතන්න.';

  @override
  String get noRecordsYet =>
      'ඔබේ පවුල් සෞඛ්‍ය සේවා නිලධාරිනිය (PHM) ඔබව ලියාපදිංචි කර දුරකථනය සමමුහුර්ත වූ පසු වාර්තා මෙහි පෙන්වයි. සමමුහුර්ත කිරීමට පහළට අදින්න.';

  @override
  String get notLinked =>
      'මෙම අංකය තවම මවකගේ වාර්තාවකට සම්බන්ධ කර නැත. කරුණාකර ඔබේ PHM ගෙන් අසන්න.';

  @override
  String get weightCheck => 'බර මැනීම';

  @override
  String get antenatalClinic => 'ගර්භණී සායනය';

  @override
  String get childRecord => 'ළමා වාර්තාව';

  @override
  String bornOn(String date) {
    return 'උපත $date';
  }

  @override
  String get chdrNumberLabel => 'CHDR අංකය';

  @override
  String get growthChart => 'වර්ධන සටහන';

  @override
  String get weightForAge => 'වයසට සරිලන බර';

  @override
  String latestWeight(String weight, String date) {
    return 'අවසන් $weight · $date';
  }

  @override
  String get noMeasurements => 'තවම බර සටහන් කර නැත.';

  @override
  String get measurements => 'මිනුම්';

  @override
  String get legendNormal => 'සාමාන්‍ය';

  @override
  String get legendBelow2 => '−2 SD ට අඩු';

  @override
  String get legendBelow3 => '−3 SD ට අඩු';

  @override
  String get legendAbove2 => '+2 SD ට වැඩි';

  @override
  String get motherZoneNormal => 'සාමාන්‍ය පරාසය තුළ ය.';

  @override
  String get motherZoneModerate =>
      'සාමාන්‍ය පරාසයට වඩා අඩු ය. ඔබේ PHM ආහාර උපදෙස් ලබා දී ඉක්මනින් නැවත බර මනිනු ඇත.';

  @override
  String get motherZoneSevere =>
      'සාමාන්‍ය පරාසයට වඩා බොහෝ අඩු ය. කරුණාකර ඉක්මනින් MOH සායනයට යන්න හෝ ඔබේ PHM හමුවන්න.';

  @override
  String get motherZoneOverweight =>
      'සාමාන්‍ය පරාසයට වඩා වැඩි ය. සෞඛ්‍ය සම්පන්න ආහාර හා ක්‍රීඩා ගැන ඔබේ PHM ගෙන් අසන්න.';

  @override
  String vaccinesGivenOf(int given, int total) {
    return 'වාර $total න් $given ක් සම්පූර්ණයි';
  }

  @override
  String get onTrack => 'නියමිත පරිදි';

  @override
  String get vaccinesLate => 'සමහර එන්නත් ප්‍රමාද වී ඇත. කරුණාකර සායනයට යන්න.';

  @override
  String nextVaccine(String doses, String date) {
    return 'ඊළඟ: $doses · $date';
  }

  @override
  String get allVaccinesGiven => 'කාලසටහනේ සියලු එන්නත් ලබා දී ඇත.';

  @override
  String get atBirth => 'උපතේදී';

  @override
  String atMonths(int months) {
    return 'මාස $months';
  }

  @override
  String atYears(int years) {
    return 'අවුරුදු $years';
  }

  @override
  String givenOn(String date) {
    return 'ලබා දුන්නේ $date';
  }

  @override
  String lateSince(String date) {
    return 'ප්‍රමාදයි · නියමිත වූයේ $date';
  }

  @override
  String get scheduleSource => 'ජාතික ප්‍රතිශක්තිකරණ කාලසටහන, ශ්‍රී ලංකාව';

  @override
  String adviceFor(String name, String age) {
    return '$name සඳහා · $age';
  }

  @override
  String get clinicVisits => 'සායන පැමිණීම්';

  @override
  String get notPregnant => 'ගර්භණීභාවයක් සටහන් කර නැත.';

  @override
  String get lateChip => 'ප්‍රමාදයි';

  @override
  String birthWeightValue(String weight) {
    return 'උපත් බර $weight';
  }
}
