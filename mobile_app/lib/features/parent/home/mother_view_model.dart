import 'package:material_ui/material_ui.dart';

import '../../../core/sync/sync_controller.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/app_repositories.dart';
import '../../phm/phm_rules.dart';
import '../vaccines/vaccine_schedule.dart';

/// One child as the mother sees it: records, vaccine card, next weighing.
class ChildSummary {
  const ChildSummary(this.child, this.growth, this.card, this.nextWeighing, this.ageMonths);

  final Child child;

  /// Oldest first (chart order).
  final List<GrowthMeasurement> growth;
  final VaccineCard card;
  final Due? nextWeighing;
  final int ageMonths;

  GrowthMeasurement? get latest => growth.lastOrNull;
}

enum UpcomingKind { vaccine, weighing, antenatal }

/// A row of "Coming up" on the home screen.
class Upcoming {
  const Upcoming(this.kind, this.date, {this.child, this.doses = const []});
  final UpcomingKind kind;
  final DateTime date;
  final Child? child;
  final List<VaccineDose> doses;
}

/// The mother's own records (P1–P6). Read from the phone only: the server
/// sends a mother just her own record, visits and children (PullService,
/// mother scope), so everything here works offline once synced.
///
/// One view model is shared by the mother's tabs, so the child chosen on
/// one tab stays chosen on the others.
class MotherViewModel extends ChangeNotifier {
  MotherViewModel(this.repos, {required this.motherId, this.sync, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    sync?.addListener(_onSync);
  }

  final AppRepositories repos;

  /// From the token (`motherId` claim); null if the account is not linked.
  final String? motherId;
  final SyncController? sync;
  final DateTime Function() _clock;

  bool loading = true;
  DateTime today = DateTime.now();
  Mother? mother;
  List<ChildSummary> children = const [];

  /// Newest first.
  List<MaternalVisit> visits = const [];
  String? _selectedId;
  int _seenRuns = -1;

  ChildSummary? get selected =>
      children.where((c) => c.child.id == _selectedId).firstOrNull ?? children.firstOrNull;

  void select(String childId) {
    _selectedId = childId;
    notifyListeners();
  }

  /// Next antenatal visit the PHM set, if she is pregnant. (Unlike the
  /// PHM's Today list, a mother sees her next date however far away it is.)
  Due? get nextAntenatal {
    final next = visits.firstOrNull?.nextVisit;
    return (mother?.isPregnant ?? false) && next != null ? Due(next, today) : null;
  }

  /// Weeks pregnant today: from the due date (40 weeks), else from the last
  /// visit plus the weeks since then.
  int? get weeksPregnantNow {
    final m = mother;
    if (m == null || !m.isPregnant) return null;
    if (m.dueDate != null) return 40 - (dateOnly(m.dueDate!).difference(dateOnly(today)).inDays / 7).ceil();
    final last = visits.firstOrNull;
    if (last != null) return last.gestationWeeks + dateOnly(today).difference(dateOnly(last.visitDate)).inDays ~/ 7;
    return m.gestationWeeks;
  }

  /// Vaccines, weighings and antenatal visits, soonest first.
  List<Upcoming> get comingUp {
    final items = <Upcoming>[
      for (final c in children) ...[
        if (c.card.next case final n?) Upcoming(UpcomingKind.vaccine, n.dueOn, child: c.child, doses: n.missing),
        if (c.nextWeighing case final w?) Upcoming(UpcomingKind.weighing, w.date, child: c.child),
      ],
      if (nextAntenatal case final a?) Upcoming(UpcomingKind.antenatal, a.date),
    ]..sort((a, b) => a.date.compareTo(b.date));
    return items;
  }

  Future<void> load() async {
    _seenRuns = sync?.runs ?? 0;
    today = _clock();
    final id = motherId;
    if (id == null) {
      loading = false;
      notifyListeners();
      return;
    }
    mother = await repos.mothers.getById(id);
    visits = await repos.visits.forMother(id);
    children = [
      for (final child in await repos.children.forMother(id))
        await _summary(child),
    ];
    loading = false;
    notifyListeners();
  }

  Future<ChildSummary> _summary(Child child) async {
    final growth = await repos.growth.forChild(child.id);
    final card = VaccineCard.build(child.dateOfBirth, await repos.vaccinations.forChild(child.id), today);
    final age = ageInMonths(child.dateOfBirth, today);
    // Next weighing: monthly under 2 years, every 3 months to 5 years
    // (same rule as the PHM's list, without its one-week window).
    final from = growth.lastOrNull?.measuredOn ?? child.dateOfBirth;
    final weigh = age < childFollowUpMonths
        ? Due(addMonths(from, weighingIntervalMonths(ageInMonths(child.dateOfBirth, from))), today)
        : null;
    return ChildSummary(child, growth, card, weigh, age);
  }

  /// Pull to refresh: sync (a mother only downloads), then read again.
  Future<void> refresh() async {
    await sync?.sendNow();
    await load();
  }

  void _onSync() {
    if (sync != null && !sync!.syncing && sync!.runs != _seenRuns) load();
  }

  @override
  void dispose() {
    sync?.removeListener(_onSync);
    super.dispose();
  }
}
