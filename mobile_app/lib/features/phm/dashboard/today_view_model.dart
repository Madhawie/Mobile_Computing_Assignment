import 'package:material_ui/material_ui.dart';

import '../../../core/storage/schema.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/app_repositories.dart';
import '../phm_rules.dart';

/// A pregnant mother whose next visit is due within a week (or late).
class VisitDue {
  const VisitDue(this.mother, this.due);
  final Mother mother;
  final Due due;
}

/// A child to weigh within a week (or late).
class WeighingDue {
  const WeighingDue(this.child, this.mother, this.lastWeighed, this.due);
  final Child child;
  final Mother mother;
  final DateTime? lastWeighed;
  final Due due;
}

enum WatchReason { lowBirthWeight, highBloodPressure }

/// Someone the PHM should keep an eye on.
class WatchItem {
  const WatchItem(this.reason, this.mother, {this.child});
  final WatchReason reason;
  final Mother mother;
  final Child? child;
}

/// P1 · Today. Builds the PHM's day from the phone's database only, so it
/// works with no signal. Nothing here talks to the server.
class TodayViewModel extends ChangeNotifier {
  TodayViewModel(this.repos, {required this.areaId, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final AppRepositories repos;
  final String areaId;
  final DateTime Function() _clock;

  bool loading = true;
  Object? error;
  DateTime today = DateTime.now();
  List<VisitDue> dueVisits = const [];
  List<WeighingDue> dueWeighings = const [];
  List<WatchItem> watch = const [];

  /// Changes saved on the phone and not yet sent.
  int pending = 0;

  /// S3 conflicts waiting on "Check a record" (phone's copy).
  int toCheck = 0;
  DateTime? lastSync;

  bool get nothingDue => dueVisits.isEmpty && dueWeighings.isEmpty;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      today = _clock();
      final visits = <VisitDue>[];
      final weighing = <WeighingDue>[];
      final watching = <WatchItem>[];

      // One area is a few hundred mothers, so a query per mother is fine on a
      // phone; a single JOIN would be the next step if it ever got slow.
      for (final mother in await repos.mothers.inArea(areaId)) {
        final lastVisit = (await repos.visits.forMother(mother.id)).firstOrNull; // newest first
        final visit = pregnancyVisitDue(
            isPregnant: mother.isPregnant, nextVisit: lastVisit?.nextVisit, today: today);
        if (visit != null) visits.add(VisitDue(mother, visit));
        if (mother.isPregnant && (lastVisit?.highBloodPressure ?? false)) {
          watching.add(WatchItem(WatchReason.highBloodPressure, mother));
        }

        for (final child in await repos.children.forMother(mother.id)) {
          final last = (await repos.growth.forChild(child.id)).lastOrNull; // oldest first
          final weigh = weighingDue(dob: child.dateOfBirth, lastWeighed: last?.measuredOn, today: today);
          if (weigh != null) weighing.add(WeighingDue(child, mother, last?.measuredOn, weigh));
          if (child.lowBirthWeight && ageInMonths(child.dateOfBirth, today) < 12) {
            watching.add(WatchItem(WatchReason.lowBirthWeight, mother, child: child));
          }
        }
      }

      visits.sort((a, b) => a.due.date.compareTo(b.due.date));
      weighing.sort((a, b) => a.due.date.compareTo(b.due.date));
      dueVisits = visits;
      dueWeighings = weighing;
      watch = watching;
      pending = await repos.outbox.pendingCount();
      toCheck = await repos.conflicts.openCount();
      final last = await repos.store.getMeta(MetaKeys.lastSyncAt);
      lastSync = last == null ? null : DateTime.parse(last).toLocal();
    } catch (e) {
      error = e;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
