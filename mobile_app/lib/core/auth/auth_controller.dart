import 'dart:convert';

import 'package:material_ui/material_ui.dart';

import '../constants/app_language.dart';
import '../constants/user_role.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../network/api_models.dart';
import '../storage/meta_store.dart';
import '../storage/schema.dart';
import 'pin_hasher.dart';
import 'secure_store.dart';

/// Which sign-in path the user picked on "Who are you?".
enum SignInPath { mother, staff }

/// Result of typing a PIN on the unlock screen.
sealed class PinResult {
  const PinResult();
}

class PinOk extends PinResult {
  const PinOk();
}

class PinWrong extends PinResult {
  const PinWrong(this.triesLeft);
  final int triesLeft;
}

/// Too many wrong PINs: PIN and session are removed; sign in again by SMS.
class PinLockedOut extends PinResult {
  const PinLockedOut();
}

/// The number signed in as staff on the mother path, or the other way round.
class RoleMismatch implements Exception {
  const RoleMismatch(this.actualRole);
  final UserRole actualRole;
}

/// Everything the app knows about who is using it. The router listens to
/// this and moves between screens when it changes (see app/router.dart).
///
/// Sign-in flow (api.md 9, design canvas C1–C6):
/// language → who are you? → phone → SMS code →
///   mother: home.
///   staff: first time on this phone: set a 4-digit PIN → home.
///          later: PIN unlock (works offline) → home.
class AuthController extends ChangeNotifier {
  AuthController({
    required this.store,
    required this.secure,
    required this.api,
    this.pinHasher = const PinHasher(),
  });

  /// Language and device id are kept here (SQLite `meta` on the phone).
  final MetaStore store;
  final SecureStore secure;
  final ApiClient api;
  final PinHasher pinHasher;

  static const maxPinTries = 5;
  static const _kSession = 'session';
  static const _kPinHash = 'pin_hash';
  static const _kPinFails = 'pin_fails';

  AppLanguage? _language;
  AuthSession? _session;
  bool _hasPin = false;
  bool _unlocked = false;
  SignInPath? _path;
  String? _otpRequestId;
  String? _otpPhone;

  AppLanguage? get language => _language;
  AuthSession? get session => _session;
  SignInPath? get path => _path;
  String? get otpPhone => _otpPhone;
  bool get waitingForCode => _otpRequestId != null;
  bool get hasPin => _hasPin;

  UserRole? get role =>
      _session == null ? null : UserRole.values.asNameMap()[_session!.user.role];

  bool get signedIn => _session != null;
  bool get isStaff => role != null && role != UserRole.mother;

  /// Staff signed in by SMS but has not chosen a PIN yet.
  bool get needsPin => isStaff && !_hasPin;

  /// Staff with a PIN who has not typed it since the app started.
  bool get locked => isStaff && _hasPin && !_unlocked;

  /// Signed in and allowed past the sign-in screens.
  bool get ready => signedIn && !needsPin && !locked;

  /// Reads what was saved last time. Called once at app start.
  Future<void> load() async {
    final code = await store.getMeta(MetaKeys.language);
    _language = code == null ? null : AppLanguage.fromCode(code);
    final saved = await secure.read(_kSession);
    if (saved != null) {
      _session = AuthSession.fromJson(jsonDecode(saved) as Map<String, dynamic>);
    }
    _hasPin = await secure.read(_kPinHash) != null;
    _unlocked = false;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    await store.setMeta(MetaKeys.language, language.code);
    _language = language;
    notifyListeners();
  }

  void choosePath(SignInPath path) {
    _path = path;
    _otpRequestId = null;
    _otpPhone = null;
    notifyListeners();
  }

  /// Step 1: ask the server to send an SMS code. Needs a connection.
  /// Throws [ApiFailure] (e.g. `PHONE_NOT_REGISTERED`, no signal).
  Future<void> requestCode(String phoneE164) async {
    final res = await api.requestOtp(phoneE164);
    _otpRequestId = res.data.otpRequestId;
    _otpPhone = phoneE164;
    notifyListeners();
  }

  /// Step 2: check the code. On success the session is saved.
  /// Throws [ApiFailure] (wrong code, no signal) or [RoleMismatch].
  Future<void> verifyCode(String code) async {
    final id = _otpRequestId;
    if (id == null) throw StateError('Ask for a code first');
    final res = await api.verifyOtp(
      otpRequestId: id,
      code: code,
      deviceId: await store.deviceId(),
    );
    final session = res.data;
    final actual = UserRole.values.asNameMap()[session.user.role];
    if (actual == null) throw HttpFailure(403, 'FORBIDDEN', 'Unknown role ${session.user.role}');
    final wantedStaff = _path == SignInPath.staff;
    if (wantedStaff != (actual != UserRole.mother)) throw RoleMismatch(actual);

    await secure.write(_kSession, jsonEncode(session.toJson()));
    _session = session;
    _otpRequestId = null;
    // A fresh SMS sign-in replaces any old PIN on this phone.
    await secure.delete(_kPinHash);
    await secure.delete(_kPinFails);
    _hasPin = false;
    _unlocked = actual == UserRole.mother;
    notifyListeners();
  }

  /// Staff: save a new 4-digit PIN (hash only) and open the app.
  Future<void> setPin(String pin) async {
    if (!isValidPin(pin)) throw ArgumentError('PIN must be 4 digits');
    await secure.write(_kPinHash, pinHasher.hash(pin));
    await secure.delete(_kPinFails);
    _hasPin = true;
    _unlocked = true;
    notifyListeners();
  }

  /// Staff: open the app with the PIN. Works with no signal.
  Future<PinResult> unlock(String pin) async {
    final stored = await secure.read(_kPinHash);
    if (stored == null) return const PinLockedOut();
    if (pinHasher.verify(pin, stored)) {
      await secure.delete(_kPinFails);
      _unlocked = true;
      notifyListeners();
      return const PinOk();
    }
    final fails = int.parse(await secure.read(_kPinFails) ?? '0') + 1;
    if (fails >= maxPinTries) {
      await signOut();
      return const PinLockedOut();
    }
    await secure.write(_kPinFails, '$fails');
    return PinWrong(maxPinTries - fails);
  }

  Future<bool>? _refreshing;

  /// Swaps the refresh token for new tokens (api.md 9.3) after the access
  /// token expired. Returns true when the caller may try again.
  ///
  /// * Only ONE refresh runs at a time: the server rotates refresh tokens
  ///   (each works once), so two parallel refreshes would make the second
  ///   one fail and sign the PHM out. Callers share the running one.
  /// * The new pair is saved at once, replacing the used refresh token.
  /// * 401 (refresh token expired, revoked or blocked account): the session
  ///   is over; sign out. Records and the outbox stay on the phone and are
  ///   sent after the next SMS sign-in.
  /// * No signal: keep the session; the sync fails and is tried later.
  Future<bool> refreshSession() => _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<bool> _refresh() async {
    final current = _session;
    if (current == null) return false;
    try {
      final res = await api.refresh(refreshToken: current.refreshToken, deviceId: await store.deviceId());
      await secure.write(_kSession, jsonEncode(res.data.toJson()));
      _session = res.data;
      notifyListeners();
      return true;
    } on HttpFailure catch (f) {
      if (f.status == 401) await signOut();
      return false;
    } on NetworkFailure {
      return false;
    }
  }

  /// Back to "Who are you?". Removes tokens and PIN; local records stay.
  Future<void> signOut() async {
    await secure.delete(_kSession);
    await secure.delete(_kPinHash);
    await secure.delete(_kPinFails);
    _session = null;
    _hasPin = false;
    _unlocked = false;
    _path = null;
    _otpRequestId = null;
    _otpPhone = null;
    notifyListeners();
  }

  static bool isValidPin(String pin) => RegExp(r'^\d{4}$').hasMatch(pin);
}
