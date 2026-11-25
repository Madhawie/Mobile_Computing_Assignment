import '../core/constants/user_role.dart';

/// Every screen address in one place, so screens never type paths by hand.
class Routes {
  Routes._();

  // Sign-in (design canvas C1–C6)
  static const language = '/language';
  static const role = '/role';
  static const phone = '/sign-in/phone';
  static const code = '/sign-in/code';
  static const setPin = '/pin/set';
  static const unlock = '/pin/unlock';

  // Homes, one per user
  static const motherHome = '/mother';
  static const phmHome = '/phm';
  static const phmRegister = '/phm/register';
  static String phmMother(String id) => '/phm/mother/$id';
  static const phmAddMother = '/phm/new-mother';
  static String phmAddChild(String motherId) => '/phm/mother/$motherId/add-child';
  static String phmRecordGrowth(String childId) => '/phm/child/$childId/growth';
  static String phmRecordVaccine(String childId) => '/phm/child/$childId/vaccine';
  static String phmRecordVisit(String motherId) => '/phm/mother/$motherId/visit';
  static const mohHome = '/moh';

  /// Screens used before the app is open.
  static const signInScreens = {language, role, phone, code, setPin, unlock};

  static String homeFor(UserRole role) => switch (role) {
        UserRole.mother => motherHome,
        UserRole.phm => phmHome,
        UserRole.supervisor || UserRole.admin => mohHome,
      };
}
