import 'package:material_ui/material_ui.dart';

import '../../../data/models/models.dart';
import '../../../data/repositories/app_repositories.dart';
import '../phm_rules.dart';

/// A child with its most recent weight, for the mother's page.
class ChildSummary {
  const ChildSummary(this.child, this.lastGrowth, this.weighing);
  final Child child;
  final GrowthMeasurement? lastGrowth;

  /// Next weighing if due within a week (or late), else null.
  final Due? weighing;
}

/// P5 · Mother detail: one mother, her pregnancy visits and her children.
/// Everything comes from the phone, so it opens with no signal.
class MotherDetailViewModel extends ChangeNotifier {
  MotherDetailViewModel(this.repos, {required this.motherId, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final AppRepositories repos;
  final String motherId;
  final DateTime Function() _clock;

  bool loading = true;
  Object? error;
  DateTime today = DateTime.now();
  Mother? mother;

  /// Newest first.
  List<MaternalVisit> visits = const [];
  List<ChildSummary> children = const [];

  MaternalVisit? get lastVisit => visits.firstOrNull;

  Due? get nextVisitDue => mother == null
      ? null
      : pregnancyVisitDue(isPregnant: mother!.isPregnant, nextVisit: lastVisit?.nextVisit, today: today);

  /// Anything about this mother still waiting on the phone to be sent.
  bool get hasUnsent =>
      (mother?.isDirty ?? false) || visits.any((v) => v.isDirty) || children.any((c) => c.child.isDirty);

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      today = _clock();
      mother = await repos.mothers.getById(motherId);
      if (mother != null) {
        visits = await repos.visits.forMother(motherId);
        final list = <ChildSummary>[];
        for (final c in await repos.children.forMother(motherId)) {
          final last = (await repos.growth.forChild(c.id)).lastOrNull;
          list.add(ChildSummary(c, last, weighingDue(dob: c.dateOfBirth, lastWeighed: last?.measuredOn, today: today)));
        }
        children = list;
      }
    } catch (e) {
      error = e;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
