import '../../../data/models/models.dart';
import '../../phm/phm_rules.dart';

/// One dose of one vaccine, as the PHM records it (vaccine name + dose).
class VaccineDose {
  const VaccineDose(this.vaccine, this.dose);
  final String vaccine;
  final int dose;

  String get label => '$vaccine $dose';
}

/// One clinic visit of the schedule: an age and the doses given then.
class ScheduleStep {
  const ScheduleStep(this.months, this.doses);

  /// Age in months when the doses are due (0 = at birth).
  final int months;
  final List<VaccineDose> doses;
}

/// National Immunization Schedule, Sri Lanka (Epidemiology Unit), as in
/// docs/requirements/README.md §2. Dose numbers are those the PHM enters on
/// "Record vaccination". Verify against the latest circular before release.
const nationalSchedule = <ScheduleStep>[
  ScheduleStep(0, [VaccineDose('BCG', 1)]),
  ScheduleStep(2, [VaccineDose('Pentavalent', 1), VaccineDose('OPV', 1), VaccineDose('fIPV', 1)]),
  ScheduleStep(4, [VaccineDose('Pentavalent', 2), VaccineDose('OPV', 2), VaccineDose('fIPV', 2)]),
  ScheduleStep(6, [VaccineDose('Pentavalent', 3), VaccineDose('OPV', 3)]),
  ScheduleStep(9, [VaccineDose('MMR', 1)]),
  ScheduleStep(12, [VaccineDose('Live JE', 1)]),
  ScheduleStep(18, [VaccineDose('DTP', 1), VaccineDose('OPV', 4)]),
  ScheduleStep(36, [VaccineDose('MMR', 2)]),
  ScheduleStep(60, [VaccineDose('DT', 1), VaccineDose('OPV', 5)]),
];

enum StepStatus {
  /// Every dose of the step is recorded.
  given,

  /// The next step not given yet, and its date has not passed.
  due,

  /// Date passed and not (fully) given: the mother should go to the clinic.
  late,

  /// Later in life.
  upcoming,
}

class CardStep {
  const CardStep(this.step, this.dueOn, this.status, this.givenOn, this.missing);

  final ScheduleStep step;

  /// Date of birth + [ScheduleStep.months].
  final DateTime dueOn;
  final StepStatus status;

  /// Latest date a dose of this step was given (null if none).
  final DateTime? givenOn;

  /// Doses of this step not recorded yet.
  final List<VaccineDose> missing;
}

/// The child's vaccination card: every step with its date and state.
class VaccineCard {
  VaccineCard(this.steps);

  final List<CardStep> steps;

  int get givenCount => steps.where((s) => s.status == StepStatus.given).length;

  /// No step is late.
  bool get onTrack => steps.every((s) => s.status != StepStatus.late);

  /// First step still to do (late first, then due), or null when complete.
  CardStep? get next =>
      steps.where((s) => s.status == StepStatus.late).firstOrNull ??
      steps.where((s) => s.status == StepStatus.due).firstOrNull;

  /// Works the card out from the date of birth and what the PHM recorded.
  /// Dates come only from the date of birth, so the card is right offline
  /// and for a child registered late.
  factory VaccineCard.build(DateTime dob, List<Vaccination> given, DateTime today) {
    final recorded = {for (final v in given.where((v) => !v.deleted)) '${v.vaccine} ${v.dose}': v.givenOn};
    var dueFound = false;
    final steps = <CardStep>[];
    for (final step in nationalSchedule) {
      final dueOn = addMonths(dateOnly(dob), step.months);
      final missing = [for (final d in step.doses) if (!recorded.containsKey(d.label)) d];
      final dates = [for (final d in step.doses) ?recorded[d.label]]..sort();
      final StepStatus status;
      if (missing.isEmpty) {
        status = StepStatus.given;
      } else if (dueOn.isBefore(dateOnly(today))) {
        status = StepStatus.late;
      } else if (!dueFound) {
        status = StepStatus.due;
        dueFound = true;
      } else {
        status = StepStatus.upcoming;
      }
      steps.add(CardStep(step, dueOn, status, dates.lastOrNull, missing));
    }
    return VaccineCard(steps);
  }
}
