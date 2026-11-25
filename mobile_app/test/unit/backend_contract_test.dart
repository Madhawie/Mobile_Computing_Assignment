import 'package:flutter_test/flutter_test.dart';
import 'package:little_bloom/core/network/api_models.dart';
import 'package:little_bloom/data/models/models.dart';

/// Checks against what the .NET API (backend/, PR #11) really sends, which
/// is not always exactly what the hand-written mock sends.
void main() {
  group('times from the .NET API', () {
    test('a time without a zone is UTC (SQL Server datetime2 keeps no zone)', () {
      final t = parseTimestamp('2026-11-20T08:15:30');
      expect((t.isUtc, t.hour, t.minute), (true, 8, 15));
    });

    test('7 fraction digits (.NET ticks), Z and offsets all work', () {
      expect(parseTimestamp('2026-11-20T08:15:30.1234567').microsecond, 456);
      expect(parseTimestamp('2026-11-20T08:15:30.1234567Z').hour, 8);
      expect(parseTimestamp('2026-11-20T13:45:30+05:30').hour, 8);
      expect(parseTimestamp('2026-11-20T13:45:30+0530').hour, 8);
    });

    test('S1 sending a record back does not move updatedAt', () {
      final pulled = Mother.fromJson(_dotnetMother);
      final sentAgain = Mother.fromJson(pulled.toJson());
      expect(sentAgain.updatedAt, pulled.updatedAt);
      expect(pulled.toJson()['updatedAt'], '2026-11-20T08:15:30.123456Z');
    });
  });

  group('.NET JSON shapes', () {
    test('null fields are left out (WhenWritingNull) and still read', () {
      final m = Mother.fromJson(_dotnetMother);
      expect((m.gestationWeeks, m.dueDate, m.isPregnant), (null, null, false));
      final g = GrowthMeasurement.fromJson({
        'id': '0b1c2d3e-0000-4000-8000-000000000003', 'version': 2, 'updatedAt': '2026-11-20T08:15:30',
        'deviceId': 'emu-1', 'deleted': false, 'childId': '0b1c2d3e-0000-4000-8000-000000000002',
        'measuredOn': '2026-11-20', 'weightKg': 7, // a whole double comes as 7, not 7.0
      });
      expect((g.weightKg, g.heightCm, g.notes), (7.0, null, null));
    });

    test('push answer without error / record / conflictId fields', () {
      final r = PushResponse.fromJson({
        'results': [
          {'operationId': 'a1', 'status': 'applied', 'recordId': 'r1', 'newVersion': 3}
        ],
        'serverTime': '2026-11-20T08:15:31.5550000Z',
        'cursor': 18452,
      });
      final c = r.results.single;
      expect((c.newVersion, c.record, c.errorCode, c.conflictId), (3, null, null, null));
      expect(r.serverTime.isUtc, isTrue);
    });
  });

}

/// A mother exactly as the .NET API writes her: Guid ids, a time with 7
/// fraction digits and no zone, null fields left out. Synthetic data.
const _dotnetMother = <String, dynamic>{
  'id': '0b1c2d3e-0000-4000-8000-000000000001',
  'version': 4,
  'updatedAt': '2026-11-20T08:15:30.1234567',
  'deviceId': 'emu-phm-01',
  'deleted': false,
  'fullName': 'Test Mother',
  'phone': '+94700000701',
  'age': 27,
  'address': 'Clinic Road',
  'areaId': 'glg-east',
  'isPregnant': false,
};
