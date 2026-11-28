import '../../core/storage/app_database.dart';
import 'conflict_repository.dart';
import 'repositories.dart';

/// All repositories, made once in main.dart and shared with Provider.
/// ViewModels take this instead of the database, so they never write SQL.
class AppRepositories {
  AppRepositories(this.store, {DateTime Function()? clock})
      : mothers = MotherRepository(store, clock: clock),
        visits = MaternalVisitRepository(store, clock: clock),
        children = ChildRepository(store, clock: clock),
        growth = GrowthRepository(store, clock: clock),
        vaccinations = VaccinationRepository(store, clock: clock),
        outbox = OutboxRepository(store),
        conflicts = ConflictRepository(store);

  final AppDatabase store;
  final MotherRepository mothers;
  final MaternalVisitRepository visits;
  final ChildRepository children;
  final GrowthRepository growth;
  final VaccinationRepository vaccinations;
  final OutboxRepository outbox;
  final ConflictRepository conflicts;
}
