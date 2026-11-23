import '../../../core/auth/auth_controller.dart';
import '../../../core/network/api_exception.dart';
import '../../../l10n/l10n.dart';

/// Turns any sign-in error into one plain sentence for the user.
String signInMessage(Object error, AppLocalizations t, SignInPath? path) => switch (error) {
      NetworkFailure() => t.noSignal,
      HttpFailure(errorCode: 'PHONE_NOT_REGISTERED') =>
        path == SignInPath.staff ? t.phoneNotRegisteredStaff : t.phoneNotRegisteredMother,
      HttpFailure(status: 400 || 401) => t.wrongCode,
      HttpFailure(retryable: true) => t.noSignal,
      RoleMismatch() => path == SignInPath.staff ? t.wrongRoleStaff : t.wrongRoleMother,
      _ => t.somethingWrong,
    };
