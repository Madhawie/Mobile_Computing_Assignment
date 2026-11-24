/// App-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'Little Bloom';

  /// Default API address. 10.0.2.2 is the Mac the emulator runs on; the
  /// .NET API listens on port 5000 (HTTP) and 5001 (HTTPS), see api.md.
  ///
  /// Change it without editing code:
  /// * at build time: `flutter run --dart-define=API_BASE_URL=http://192.168.1.20:5000`
  ///   (e.g. the partner's Windows PC on the same Wi-Fi), or
  /// * on the phone: saved in `meta` by ServerSettings (tester screen, Day 18).
  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:5000');

  /// Sync strategies compared in the experiments.
  static const List<String> syncStrategies = ['S1', 'S2', 'S3'];
}
