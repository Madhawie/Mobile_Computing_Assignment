import 'package:flutter_test/flutter_test.dart';
import 'package:little_bloom/core/dev/sample_data.dart';
import 'package:little_bloom/core/storage/app_database.dart';
import 'package:little_bloom/data/models/models.dart';
import 'package:little_bloom/data/repositories/app_repositories.dart';
import 'package:little_bloom/features/phm/dashboard/today_view_model.dart';
import 'package:little_bloom/features/phm/mother_detail/mother_detail_view_model.dart';
import 'package:little_bloom/features/phm/register/register_view_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The three PHM ViewModels on the synthetic sample area, with a fixed date.
void main() {
  sqfliteFfiInit();
  final today = DateTime(2026, 11, 24, 9);
  DateTime clock() => today;
  late AppDatabase store;
  late AppRepositories repos;

  setUp(() async {
    store = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    repos = AppRepositories(store, clock: clock);
    expect(await loadSampleData(repos, areaId: 'glg-east', today: today), 17);
    // A mother in another area must never show up.
    await repos.mothers.create(Mother(
      id: '', version: 0, updatedAt: today, deviceId: '', fullName: 'Other Area Mother',
      phone: '+94700000199', age: 30, address: 'x', areaId: 'glg-west', isPregnant: true,
    ));
  });
  tearDown(() => store.close());

  group('Today', () {
    test('visits due, oldest first: late, today, in 2 days', () async {
      final vm = TodayViewModel(repos, areaId: 'glg-east', clock: clock);
      await vm.load();
      expect(vm.dueVisits.map((v) => v.mother.fullName), ['Fathima Rizna', 'Malathi Selvaraj', 'Nimali Perera']);
      expect(vm.dueVisits.first.due.daysLate, 3);
      expect(vm.dueVisits[1].due.isToday, isTrue);
    });

    test('children to weigh follow the CHDR schedule', () async {
      final vm = TodayViewModel(repos, areaId: 'glg-east', clock: clock);
      await vm.load();
      // Kavin (monthly, due today), newborn never weighed (in 4 days).
      // Thenuli (3 y, weighed 2 months ago) and Ayaan (weighed 10 days ago) are not due.
      expect(vm.dueWeighings.map((w) => w.child.name), ['Kavin', 'Baby of Kavitha']);
    });

    test('watch list: high BP mother and low birth weight baby', () async {
      final vm = TodayViewModel(repos, areaId: 'glg-east', clock: clock);
      await vm.load();
      expect(vm.watch.map((w) => (w.reason, w.child?.name ?? w.mother.fullName)), [
        (WatchReason.highBloodPressure, 'Fathima Rizna'),
        (WatchReason.lowBirthWeight, 'Baby of Kavitha'),
      ]);
    });

    test('counts changes waiting to send; never synced yet', () async {
      final vm = TodayViewModel(repos, areaId: 'glg-east', clock: clock);
      await vm.load();
      expect(vm.pending, 18); // 17 sample records + 1 other-area mother, all queued
      expect(vm.lastSync, isNull);
    });
  });

  group('Register', () {
    test('only this area, mothers A–Z with child counts', () async {
      final vm = RegisterViewModel(repos, areaId: 'glg-east', clock: clock);
      await vm.load();
      expect(vm.mothers.map((r) => r.mother.fullName), [
        'Dilani Silva', 'Fathima Rizna', 'Kavitha Rajan', 'Malathi Selvaraj', 'Nimali Perera', 'Sanduni Jayasinghe',
      ]);
      expect(vm.mothers.firstWhere((r) => r.mother.fullName == 'Malathi Selvaraj').childCount, 1);
      expect(vm.mothers.every((r) => r.mother.isDirty), isTrue); // not sent yet
    });

    test('search by name, or by a number typed as 07…', () async {
      final vm = RegisterViewModel(repos, areaId: 'glg-east', clock: clock);
      await vm.load();
      vm.search('FATH');
      expect(vm.mothers.single.mother.fullName, 'Fathima Rizna');
      vm.search('070 000 0104');
      expect(vm.mothers.single.mother.fullName, 'Dilani Silva');
      vm.search('nobody');
      expect(vm.mothers, isEmpty);
    });

    test('children tab: A–Z, found by own or mother name', () async {
      final vm = RegisterViewModel(repos, areaId: 'glg-east', clock: clock);
      await vm.load();
      vm.setTab(RegisterTab.children);
      expect(vm.children.map((r) => r.child.name), ['Ayaan', 'Baby of Kavitha', 'Kavin', 'Thenuli']);
      vm.search('dilani');
      expect(vm.children.single.child.name, 'Kavin');
    });
  });

  group('Mother detail', () {
    Future<MotherDetailViewModel> open(String name) async {
      final id = (await repos.mothers.search(name)).single.id;
      final vm = MotherDetailViewModel(repos, motherId: id, clock: clock);
      await vm.load();
      return vm;
    }

    test('visits newest first; last BP high; next visit late', () async {
      final vm = await open('Fathima');
      expect(vm.visits.map((v) => v.gestationWeeks), [31, 29]);
      expect(vm.lastVisit!.highBloodPressure, isTrue);
      expect(vm.nextVisitDue!.daysLate, 3);
      expect(vm.hasUnsent, isTrue);
    });

    test('children with last weight and weighing due', () async {
      final vm = await open('Dilani');
      final kavin = vm.children.single;
      expect(kavin.lastGrowth!.weightKg, 7.4);
      expect(kavin.weighing!.isToday, isTrue);
    });

    test('a deleted or unknown mother shows nothing', () async {
      final vm = MotherDetailViewModel(repos, motherId: 'no-such-id', clock: clock);
      await vm.load();
      expect(vm.mother, isNull);
      expect(vm.error, isNull);
    });
  });
}
