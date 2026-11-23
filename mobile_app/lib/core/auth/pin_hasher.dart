import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Turns a 4-digit PIN into a salted, slow hash, and checks a PIN against it.
///
/// The PIN never leaves the phone and is never stored as text (api.md 9.4).
/// A 4-digit PIN has only 10 000 values, so the hash alone cannot stop a
/// determined attacker with the file; it is one layer, together with the
/// secure store (Android Keystore) and the 5-attempt limit.
///
/// Algorithm: PBKDF2-HMAC-SHA256, 16-byte random salt.
/// Stored as `pbkdf2-sha256$<iterations>$<salt base64>$<hash base64>`.
class PinHasher {
  const PinHasher({this.iterations = 20000});

  final int iterations;

  static final _random = Random.secure();

  String hash(String pin) {
    final salt = Uint8List.fromList(List.generate(16, (_) => _random.nextInt(256)));
    final key = _pbkdf2(utf8.encode(pin), salt, iterations);
    return 'pbkdf2-sha256\$$iterations\$${base64.encode(salt)}\$${base64.encode(key)}';
  }

  bool verify(String pin, String stored) {
    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != 'pbkdf2-sha256') return false;
    final rounds = int.tryParse(parts[1]);
    if (rounds == null) return false;
    final expected = base64.decode(parts[3]);
    final actual = _pbkdf2(utf8.encode(pin), base64.decode(parts[2]), rounds);
    return _sameBytes(actual, expected);
  }

  /// PBKDF2 (RFC 8018) with HMAC-SHA256, one 32-byte block.
  static List<int> _pbkdf2(List<int> password, List<int> salt, int rounds) {
    final hmac = Hmac(sha256, password);
    var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final out = List<int>.of(u);
    for (var i = 1; i < rounds; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < out.length; j++) {
        out[j] ^= u[j];
      }
    }
    return out;
  }

  /// Compares every byte, so the time taken does not reveal where they differ.
  static bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
