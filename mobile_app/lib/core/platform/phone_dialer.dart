import 'package:flutter/services.dart';

/// Opens the phone app with a number ready to call (the person still
/// presses call). Used for 1990, the free Suwa Seriya ambulance.
///
/// Android's ACTION_DIAL needs no CALL_PHONE permission and works offline
/// on the mobile network. Done with a small platform channel in
/// MainActivity.kt instead of a plugin, so no extra package is needed.
class PhoneDialer {
  const PhoneDialer();

  static const _channel = MethodChannel('little_bloom/phone');

  /// Suwa Seriya, Sri Lanka's free ambulance service.
  static const ambulance = '1990';

  /// True if the dialler opened.
  Future<bool> dial(String number) async {
    try {
      return await _channel.invokeMethod<bool>('dial', {'number': number}) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false; // tests, or a platform without the channel
    }
  }
}
