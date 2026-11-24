import 'package:flutter_test/flutter_test.dart';
import 'package:little_bloom/app/router.dart';
import 'package:little_bloom/app/routes.dart';
import 'package:little_bloom/core/auth/auth_controller.dart';
import 'package:little_bloom/core/auth/phone_number.dart';
import 'package:little_bloom/core/auth/pin_hasher.dart';
import 'package:little_bloom/core/auth/secure_store.dart';
import 'package:little_bloom/core/constants/app_language.dart';
import 'package:little_bloom/core/constants/user_role.dart';
import 'package:little_bloom/core/network/api_exception.dart';
import 'package:little_bloom/core/storage/meta_store.dart';

import '../helpers/fake_auth_api.dart';

Future<void> signIn(AuthController auth, SignInPath path, String phone) async {
  await auth.setLanguage(AppLanguage.english);
  auth.choosePath(path);
  await auth.requestCode(phone);
  await auth.verifyCode(fakeCode);
}

void main() {
  group('PinHasher', () {
    const h = PinHasher(iterations: 500);

    test('stores no plain PIN and checks it', () {
      final stored = h.hash('4321');
      expect(stored, isNot(contains('4321')));
      expect(stored, startsWith('pbkdf2-sha256\$500\$'));
      expect(h.verify('4321', stored), isTrue);
      expect(h.verify('1234', stored), isFalse);
    });

    test('same PIN gives a different hash each time (random salt)', () {
      expect(h.hash('0000'), isNot(h.hash('0000')));
    });

    test('a damaged hash never matches', () {
      expect(h.verify('4321', 'not-a-hash'), isFalse);
      expect(h.verify('4321', 'pbkdf2-sha256\$x\$AA==\$AA=='), isFalse);
    });
  });

  group('PhoneNumber', () {
    test('accepts the usual ways of writing a Sri Lankan mobile', () {
      for (final input in ['076 482 3310', '0764823310', '+94 76 482 3310', '94764823310', '76-482-3310']) {
        expect(PhoneNumber.normalise(input), '+94764823310', reason: input);
      }
    });

    test('rejects landlines and wrong lengths', () {
      expect(PhoneNumber.normalise('011 234 5678'), isNull); // Colombo landline
      expect(PhoneNumber.normalise('0764823'), isNull);
      expect(PhoneNumber.normalise(''), isNull);
    });

    test('pretty format for display', () {
      expect(PhoneNumber.pretty('+94764823310'), '+94 76 482 3310');
    });
  });

  group('AuthController', () {
    test('mother: SMS sign-in opens the app, no PIN needed', () async {
      final auth = makeAuth();
      await signIn(auth, SignInPath.mother, '+94771234567');
      expect(auth.role, UserRole.mother);
      expect(auth.ready, isTrue);
      expect(auth.needsPin, isFalse);
    });

    test('staff: after SMS must set a PIN, then the app opens', () async {
      final auth = makeAuth();
      await signIn(auth, SignInPath.staff, '+94700000002');
      expect(auth.role, UserRole.phm);
      expect(auth.needsPin, isTrue);
      expect(auth.ready, isFalse);
      await auth.setPin('1357');
      expect(auth.ready, isTrue);
    });

    test('reopening the app: session kept, staff must unlock with PIN (offline)', () async {
      final server = FakeAuthServer();
      final meta = MemoryMetaStore();
      final secure = MemorySecureStore();
      final first = makeAuth(server: server, meta: meta, secure: secure);
      await signIn(first, SignInPath.staff, '+94700000002');
      await first.setPin('1357');

      server.offline = true; // no signal in the village
      final reopened = makeAuth(server: server, meta: meta, secure: secure);
      await reopened.load();
      expect(reopened.language, AppLanguage.english);
      expect(reopened.locked, isTrue);
      expect(await reopened.unlock('1357'), isA<PinOk>());
      expect(reopened.ready, isTrue);
    });

    test('wrong PIN counts down, fifth wrong try signs out', () async {
      final auth = makeAuth();
      await signIn(auth, SignInPath.staff, '+94700000002');
      await auth.setPin('1357');
      for (var left = 4; left >= 1; left--) {
        final r = await auth.unlock('0000');
        expect(r, isA<PinWrong>().having((w) => w.triesLeft, 'triesLeft', left));
      }
      expect(await auth.unlock('0000'), isA<PinLockedOut>());
      expect(auth.signedIn, isFalse);
      expect(auth.hasPin, isFalse);
    });

    test('a right PIN resets the wrong-try counter', () async {
      final auth = makeAuth();
      await signIn(auth, SignInPath.staff, '+94700000002');
      await auth.setPin('1357');
      await auth.unlock('0000');
      await auth.unlock('1357');
      expect(await auth.unlock('0000'), isA<PinWrong>().having((w) => w.triesLeft, 'left', 4));
    });

    test('PIN and tokens never go to the settings table', () async {
      final meta = MemoryMetaStore();
      final secure = MemorySecureStore();
      final auth = makeAuth(meta: meta, secure: secure);
      await signIn(auth, SignInPath.staff, '+94700000002');
      await auth.setPin('1357');
      expect(meta.values.values.join(), isNot(contains('access-phm')));
      expect(secure.values.values.join(), isNot(contains('1357')));
      expect(secure.values['session'], contains('access-phm'));
    });

    test('staff number on the mother path is refused and not saved', () async {
      final auth = makeAuth();
      await expectLater(signIn(auth, SignInPath.mother, '+94700000002'), throwsA(isA<RoleMismatch>()));
      expect(auth.signedIn, isFalse);
    });

    test('unknown number and wrong code come back as server errors', () async {
      final auth = makeAuth();
      auth.choosePath(SignInPath.mother);
      await expectLater(auth.requestCode('+94711111111'),
          throwsA(isA<HttpFailure>().having((f) => f.code, 'code', 'PHONE_NOT_REGISTERED')));
      await auth.requestCode('+94771234567');
      await expectLater(auth.verifyCode('123456'), throwsA(isA<HttpFailure>()));
      expect(auth.signedIn, isFalse);
    });

    test('no signal while asking for a code is a network failure', () async {
      final server = FakeAuthServer()..offline = true;
      final auth = makeAuth(server: server)..choosePath(SignInPath.mother);
      await expectLater(auth.requestCode('+94771234567'), throwsA(isA<NetworkFailure>()));
    });

    test('a new SMS sign-in replaces the old PIN', () async {
      final auth = makeAuth();
      await signIn(auth, SignInPath.staff, '+94700000002');
      await auth.setPin('1357');
      auth.choosePath(SignInPath.staff);
      await auth.requestCode('+94700000002');
      await auth.verifyCode(fakeCode);
      expect(auth.needsPin, isTrue);
    });
  });

  group('authRedirect', () {
    test('first start: everything goes to the language screen', () {
      final auth = makeAuth();
      expect(authRedirect(auth, Routes.role), Routes.language);
      expect(authRedirect(auth, Routes.phmHome), Routes.language);
      expect(authRedirect(auth, Routes.language), isNull);
    });

    test('signed out: only sign-in screens, code only after asking for one', () async {
      final auth = makeAuth();
      await auth.setLanguage(AppLanguage.sinhala);
      expect(authRedirect(auth, Routes.role), isNull);
      expect(authRedirect(auth, Routes.phmHome), Routes.role);
      expect(authRedirect(auth, Routes.phone), Routes.role); // no path picked yet
      auth.choosePath(SignInPath.mother);
      expect(authRedirect(auth, Routes.phone), isNull);
      expect(authRedirect(auth, Routes.code), Routes.phone);
      await auth.requestCode('+94771234567');
      expect(authRedirect(auth, Routes.code), isNull);
    });

    test('staff: set PIN, then locked after restart, then own home only', () async {
      final meta = MemoryMetaStore();
      final secure = MemorySecureStore();
      final auth = makeAuth(meta: meta, secure: secure);
      await signIn(auth, SignInPath.staff, '+94700000002');
      expect(authRedirect(auth, Routes.phmHome), Routes.setPin);
      await auth.setPin('1357');
      expect(authRedirect(auth, Routes.code), Routes.phmHome);
      expect(authRedirect(auth, Routes.motherHome), Routes.phmHome); // not another role's home
      expect(authRedirect(auth, Routes.phmHome), isNull);

      final reopened = makeAuth(meta: meta, secure: secure);
      await reopened.load();
      expect(authRedirect(reopened, Routes.phmHome), Routes.unlock);
    });

    test('admin and supervisor go to the MOH home', () async {
      final auth = makeAuth();
      await signIn(auth, SignInPath.staff, '+94700000001');
      await auth.setPin('2468');
      expect(authRedirect(auth, Routes.language), Routes.mohHome);
    });
  });
}
