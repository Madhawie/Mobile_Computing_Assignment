import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_controller.dart';
import '../features/common/auth/code_screen.dart';
import '../features/common/auth/language_screen.dart';
import '../features/common/auth/phone_screen.dart';
import '../features/common/auth/role_screen.dart';
import '../features/common/auth/set_pin_screen.dart';
import '../features/common/auth/unlock_screen.dart';
import '../data/repositories/app_repositories.dart';
import '../core/network/api_client.dart';
import '../features/common/home_placeholder.dart';
import '../features/phm/conflicts/conflicts_screen.dart';
import '../features/phm/conflicts/conflicts_view_model.dart';
import '../features/phm/dashboard/today_screen.dart';
import '../features/phm/dashboard/today_view_model.dart';
import '../features/phm/add_mother/add_mother_screen.dart';
import '../features/phm/growth_record/record_growth_screen.dart';
import '../features/phm/home_visit/antenatal_visit_screen.dart';
import '../features/phm/vaccine_record/record_vaccine_screen.dart';
import '../features/phm/mother_detail/mother_detail_screen.dart';
import '../features/phm/newborn/add_child_screen.dart';
import '../features/phm/mother_detail/mother_detail_view_model.dart';
import '../features/phm/phm_shell.dart';
import '../features/phm/register/register_screen.dart';
import '../features/phm/register/register_view_model.dart';
import '../features/phm/register/sample_data_button.dart';
import '../core/sync/sync_controller.dart';
import '../features/phm/sync/sync_screen.dart';
import '../features/phm/sync/sync_view_model.dart';
import '../features/parent/child_profile/child_record_screen.dart';
import '../features/parent/home/mother_home_screen.dart';
import '../features/parent/home/mother_view_model.dart';
import '../features/parent/mother_shell.dart';
import '../features/parent/pregnancy/pregnancy_screen.dart';
import 'routes.dart';

/// The app's screens. go_router asks [authRedirect] before every move and
/// again whenever [AuthController] changes, so screens never decide
/// "where next" after sign-in themselves.
GoRouter createRouter(AuthController auth) => GoRouter(
      initialLocation: Routes.language,
      refreshListenable: auth,
      redirect: (context, state) => authRedirect(auth, state.matchedLocation),
      routes: [
        GoRoute(path: Routes.language, builder: (_, _) => const LanguageScreen()),
        GoRoute(path: Routes.role, builder: (_, _) => const RoleScreen()),
        GoRoute(path: Routes.phone, builder: (_, _) => const PhoneScreen()),
        GoRoute(path: Routes.code, builder: (_, _) => const CodeScreen()),
        GoRoute(path: Routes.setPin, builder: (_, _) => const SetPinScreen()),
        GoRoute(path: Routes.unlock, builder: (_, _) => const UnlockScreen()),
        // PHM: tabs share one frame with the bottom menu.
        ShellRoute(
          builder: (context, state, child) => PhmShell(location: state.uri.path, child: child),
          routes: [
            GoRoute(
              path: Routes.phmHome,
              builder: (context, _) => ChangeNotifierProvider(
                create: (c) => TodayViewModel(c.read<AppRepositories>(), areaId: _areaOf(auth))..load(),
                child: const TodayScreen(),
              ),
            ),
            GoRoute(
              path: Routes.phmRegister,
              builder: (context, _) => ChangeNotifierProvider(
                create: (c) => RegisterViewModel(c.read<AppRepositories>(), areaId: _areaOf(auth))..load(),
                // Sample data button only in debug builds, never in a release.
                child: const RegisterScreen(emptyAction: kDebugMode ? SampleDataButton() : null),
              ),
            ),
            GoRoute(
              path: Routes.phmSync,
              builder: (context, _) => ChangeNotifierProvider(
                create: (c) {
                  final sync = c.read<SyncController>()..refresh();
                  return SyncViewModel(c.read<AppRepositories>(), sync)..load();
                },
                child: const SyncScreen(),
              ),
            ),
          ],
        ),
        // PHM full-screen pages (no bottom menu), opened from the tabs.
        // Forms save offline; each returns true when something was saved.
        GoRoute(path: Routes.phmAddMother, builder: (_, _) => const AddMotherScreen()),
        GoRoute(
          path: '/phm/mother/:id/add-child',
          builder: (_, state) => AddChildScreen(motherId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/phm/child/:id/growth',
          builder: (_, state) => RecordGrowthScreen(childId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/phm/child/:id/vaccine',
          builder: (_, state) => RecordVaccineScreen(childId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/phm/mother/:id/visit',
          builder: (_, state) => AntenatalVisitScreen(motherId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: Routes.phmConflicts,
          builder: (context, _) => ChangeNotifierProvider(
            create: (c) => ConflictsViewModel(c.read<AppRepositories>(), c.read<ApiClient>())..load(),
            child: const ConflictsScreen(),
          ),
        ),
        GoRoute(
          path: '/phm/mother/:id',
          builder: (context, state) => ChangeNotifierProvider(
            create: (c) => MotherDetailViewModel(c.read<AppRepositories>(),
                motherId: state.pathParameters['id']!)..load(),
            child: const MotherDetailScreen(),
          ),
        ),
        // Mother: one view model for all her screens, so the chosen child
        // stays chosen between tabs. Reads the phone's database only.
        ShellRoute(
          builder: (context, state, child) => ChangeNotifierProvider(
            create: (c) => MotherViewModel(c.read<AppRepositories>(),
                motherId: auth.session?.user.motherId, sync: _syncOf(c))..load(),
            child: MotherShell(location: state.uri.path, child: child),
          ),
          routes: [
            GoRoute(path: Routes.motherHome, builder: (_, _) => const MotherHomeScreen()),
            GoRoute(path: Routes.motherPregnancy, builder: (_, _) => const PregnancyScreen()),
            GoRoute(
              path: '/mother/child/:id',
              builder: (_, state) => ChildRecordScreen(childId: state.pathParameters['id']!),
            ),
          ],
        ),
        // MOH home: real screens on Day 17.
        GoRoute(path: Routes.mohHome, builder: (_, _) => const HomePlaceholder()),
      ],
    );

/// The sync controller, if the app has one (widget tests may not).
SyncController? _syncOf(BuildContext context) {
  try {
    return context.read<SyncController>();
  } on ProviderNotFoundException {
    return null;
  }
}

/// The PHM's area from the token (`glg-east`); her register shows only it.
String _areaOf(AuthController auth) => auth.session?.user.areaId ?? '';

/// Where the user may be, given the sign-in state. Returns the screen to go
/// to instead, or null to stay on [location]. Kept free of Flutter widgets so
/// it can be unit-tested.
///
/// 1. No language yet          → language screen.
/// 2. Not signed in            → language / role / phone / code only
///                               (code only after a code was requested).
/// 3. Staff without a PIN      → set PIN.
/// 4. Staff with a PIN, locked → unlock.
/// 5. Signed in                → own home; sign-in screens and other
///                               roles' homes are not reachable.
String? authRedirect(AuthController auth, String location) {
  if (auth.language == null) return location == Routes.language ? null : Routes.language;

  if (!auth.signedIn) {
    if (location == Routes.code && !auth.waitingForCode) return Routes.phone;
    if (location == Routes.phone && auth.path == null) return Routes.role;
    const open = {Routes.language, Routes.role, Routes.phone, Routes.code};
    return open.contains(location) ? null : Routes.role;
  }

  if (auth.needsPin) return location == Routes.setPin ? null : Routes.setPin;
  if (auth.locked) return location == Routes.unlock ? null : Routes.unlock;

  final home = Routes.homeFor(auth.role!);
  if (Routes.signInScreens.contains(location)) return home;
  const homes = [Routes.motherHome, Routes.phmHome, Routes.mohHome];
  final otherHome = homes.any((h) => h != home && (location == h || location.startsWith('$h/')));
  return otherHome ? home : null;
}
