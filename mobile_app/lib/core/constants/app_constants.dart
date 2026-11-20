/// App-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'Little Bloom';

  /// The Android emulator reaches the Mac host at 10.0.2.2.
  /// Port is a placeholder until the API contract (docs/architecture/api.md)
  /// is agreed with the backend.
  static const String apiBaseUrl = 'http://10.0.2.2:5000';

  /// Sync strategies compared in the experiments.
  static const List<String> syncStrategies = ['S1', 'S2', 'S3'];
}
