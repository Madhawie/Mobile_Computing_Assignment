import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'core/auth/auth_controller.dart';
import 'core/auth/secure_store.dart';
import 'core/network/api_client.dart';
import 'core/network/server_settings.dart';
import 'core/storage/app_database.dart';
import 'data/repositories/app_repositories.dart';

/// Entry point: open the local database, build the API client and the
/// sign-in state, then start the app. Nothing here needs a connection, so
/// the app opens in a village with no signal.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = await AppDatabase.open();
  final baseUrl = await ServerSettings(store).baseUrl();

  late final AuthController auth;
  final api = ApiClient(baseUrl: baseUrl, tokenProvider: () => auth.session?.accessToken);
  auth = AuthController(store: store, secure: DeviceSecureStore(), api: api);
  await auth.load();

  runApp(MultiProvider(
    providers: [
      Provider<AppDatabase>.value(value: store),
      Provider<ApiClient>.value(value: api),
      Provider<AppRepositories>.value(value: AppRepositories(store)),
    ],
    child: LittleBloomApp(auth: auth),
  ));
}
