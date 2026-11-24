import '../constants/app_constants.dart';
import '../storage/app_database.dart';
import '../storage/schema.dart';

/// Which API address the app talks to.
///
/// Order: address saved on the phone → `--dart-define=API_BASE_URL` →
/// `http://10.0.2.2:5000`. Needed because the API may run on the Mac (same
/// machine as the emulator, 10.0.2.2) or on the partner's Windows PC (its
/// Wi-Fi address).
class ServerSettings {
  ServerSettings(this._store);

  final AppDatabase _store;

  Future<String> baseUrl() async =>
      await _store.getMeta(MetaKeys.apiBaseUrl) ?? AppConstants.apiBaseUrl;

  /// Saves [url] after checking it. Returns the cleaned address.
  /// Throws [FormatException] for anything that is not http(s)://host[:port].
  Future<String> save(String url) async {
    final clean = normalise(url);
    await _store.setMeta(MetaKeys.apiBaseUrl, clean);
    return clean;
  }

  /// Back to the built-in address.
  Future<void> reset() => _store.setMeta(MetaKeys.apiBaseUrl, null);

  /// `192.168.1.20:5000/` → `http://192.168.1.20:5000`.
  static String normalise(String input) {
    var text = input.trim();
    if (!text.contains('://')) text = 'http://$text';
    final uri = Uri.tryParse(text);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) {
      throw FormatException('Not a server address: $input');
    }
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }
}
