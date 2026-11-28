import 'package:connectivity_plus/connectivity_plus.dart';

/// Tells the app when the phone gets or loses a network.
///
/// An interface so tests (and experiments) can switch the "signal" on and
/// off without a real phone.
abstract class ConnectivityWatcher {
  /// True if the phone has Wi-Fi, mobile data or another network now.
  Future<bool> isOnline();

  /// Emits a value every time the phone goes online (true) or offline (false).
  Stream<bool> get changes;
}

/// The real phone, using connectivity_plus (Android's network callbacks).
///
/// Note: "online" here means a network is connected, not that the server
/// can be reached (a Wi-Fi with no internet, or a captive portal, still
/// counts as online). The sync itself finds that out and is logged as a
/// failed run; nothing is lost because the outbox keeps every change.
class DeviceConnectivity implements ConnectivityWatcher {
  DeviceConnectivity([Connectivity? connectivity]) : _c = connectivity ?? Connectivity();

  final Connectivity _c;

  static bool _online(List<ConnectivityResult> r) => r.any((x) => x != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async => _online(await _c.checkConnectivity());

  @override
  Stream<bool> get changes => _c.onConnectivityChanged.map(_online).distinct();
}
