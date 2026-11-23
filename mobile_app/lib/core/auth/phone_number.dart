/// Sri Lankan mobile numbers.
class PhoneNumber {
  PhoneNumber._();

  /// `076 482 3310`, `0764823310`, `+94 76 482 3310` → `+94764823310`.
  /// Returns null if it is not a Sri Lankan mobile number (07X + 7 digits).
  static String? normalise(String input) {
    var digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('94')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (digits.length != 9 || !digits.startsWith('7')) return null;
    return '+94$digits';
  }

  /// `+94764823310` → `+94 76 482 3310` (for display).
  static String pretty(String e164) {
    if (!e164.startsWith('+94') || e164.length != 12) return e164;
    final d = e164.substring(3);
    return '+94 ${d.substring(0, 2)} ${d.substring(2, 5)} ${d.substring(5)}';
  }
}
