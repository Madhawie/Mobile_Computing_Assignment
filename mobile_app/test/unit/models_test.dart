import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:little_bloom/data/models/models.dart';

// Synthetic test data only.
final _updated = DateTime.utc(2026, 11, 20, 8, 15, 30);

Mother _mother({bool dirty = true}) => Mother(
      id: 'm-1', version: 2, updatedAt: _updated, deviceId: 'emu-phm-01',
      isDirty: dirty, fullName: 'Test Mother', phone: '+94700000001', age: 24,
      address: '1, Test Road', areaId: 'glg-east', isPregnant: true,
      gestationWeeks: 18, dueDate: DateTime(2027, 4, 10),
    );

MaternalVisit _visit() => MaternalVisit(
      id: 'v-1', version: 1, updatedAt: _updated, deviceId: 'emu-phm-01',
      isDirty: true, motherId: 'm-1', visitDate: DateTime(2026, 11, 20),
      gestationWeeks: 18, weightKg: 58.5, bpSystolic: 142, bpDiastolic: 88,
    );

Child _child() => Child(
      id: 'c-1', version: 1, updatedAt: _updated, deviceId: 'emu-phm-01',
      motherId: 'm-1', name: 'Test Baby', sex: Sex.girl,
      dateOfBirth: DateTime(2026, 11, 10), birthWeightKg: 2.4,
      bornAt: 'Test Hospital', chdrNumber: 'TST-0001',
    );

GrowthMeasurement _growth() => GrowthMeasurement(
      id: 'g-1', version: 3, updatedAt: _updated, deviceId: 'emu-phm-01',
      isDirty: true, childId: 'c-1', measuredOn: DateTime(2026, 11, 20),
      weightKg: 7.4, notes: 'ate well',
    );

Vaccination _vaccine() => Vaccination(
      id: 'x-1', version: 1, updatedAt: _updated, deviceId: 'emu-phm-01',
      deleted: true, childId: 'c-1', vaccine: 'Pentavalent', dose: 2,
      givenOn: DateTime(2026, 11, 20), batchNo: 'B-77',
    );

/// Round trip through JSON text, like a real HTTP body.
Map<String, dynamic> _viaJsonText(Map<String, dynamic> m) =>
    jsonDecode(jsonEncode(m)) as Map<String, dynamic>;

void main() {
  group('common record fields', () {
    test('toJson uses camelCase and never sends isDirty', () {
      final j = _mother().toJson();
      expect(j['updatedAt'], '2026-11-20T08:15:30.000Z');
      expect(j['deviceId'], 'emu-phm-01');
      expect(j['deleted'], false);
      expect(j.containsKey('isDirty'), isFalse);
      expect(j.containsKey('is_dirty'), isFalse);
    });

    test('toMap uses snake_case and stores bools as 0/1', () {
      final m = _mother().toMap();
      expect(m['updated_at'], '2026-11-20T08:15:30.000Z');
      expect(m['device_id'], 'emu-phm-01');
      expect(m['deleted'], 0);
      expect(m['is_dirty'], 1);
      expect(m['is_pregnant'], 1);
    });

    test('records from the server are never dirty', () {
      final back = Mother.fromJson(_viaJsonText(_mother(dirty: true).toJson()));
      expect(back.isDirty, isFalse);
    });

    test('dates without time are sent as YYYY-MM-DD', () {
      expect(_mother().toJson()['dueDate'], '2027-04-10');
      expect(_child().toMap()['date_of_birth'], '2026-11-10');
    });

    test('tombstone survives both round trips', () {
      final v = _vaccine();
      expect(Vaccination.fromJson(_viaJsonText(v.toJson())).deleted, isTrue);
      expect(Vaccination.fromMap(v.toMap()).deleted, isTrue);
    });
  });

  group('round trips keep every field', () {
    // Comparing toMap() output checks all fields at once.
    test('Mother', () {
      final r = _mother();
      expect(Mother.fromMap(r.toMap()).toMap(), r.toMap());
      expect(Mother.fromJson(_viaJsonText(r.toJson())).toJson(), r.toJson());
    });

    test('MaternalVisit', () {
      final r = _visit();
      expect(MaternalVisit.fromMap(r.toMap()).toMap(), r.toMap());
      expect(MaternalVisit.fromJson(_viaJsonText(r.toJson())).toJson(), r.toJson());
    });

    test('Child', () {
      final r = _child();
      expect(Child.fromMap(r.toMap()).toMap(), r.toMap());
      expect(Child.fromJson(_viaJsonText(r.toJson())).toJson(), r.toJson());
    });

    test('GrowthMeasurement', () {
      final r = _growth();
      expect(GrowthMeasurement.fromMap(r.toMap()).toMap(), r.toMap());
      expect(GrowthMeasurement.fromJson(_viaJsonText(r.toJson())).toJson(), r.toJson());
    });

    test('Vaccination', () {
      final r = _vaccine();
      expect(Vaccination.fromMap(r.toMap()).toMap(), r.toMap());
      expect(Vaccination.fromJson(_viaJsonText(r.toJson())).toJson(), r.toJson());
    });
  });

  group('parsing server values', () {
    test('whole-number weight (7) is read as a double', () {
      final j = _growth().toJson()..['weightKg'] = 7;
      expect(GrowthMeasurement.fromJson(j).weightKg, 7.0);
    });

    test('optional fields may be null or missing', () {
      final j = _growth().toJson()
        ..remove('heightCm')
        ..['notes'] = null;
      final g = GrowthMeasurement.fromJson(j);
      expect(g.heightCm, isNull);
      expect(g.notes, isNull);
    });

    test('recordFromJson picks the class from entity', () {
      expect(recordFromJson('child', _child().toJson()), isA<Child>());
      expect(recordFromJson('maternalVisit', _visit().toJson()), isA<MaternalVisit>());
      expect(() => recordFromJson('pet', {}), throwsArgumentError);
    });
  });

  group('health flags', () {
    test('birth weight under 2.5 kg is low birth weight', () {
      expect(_child().lowBirthWeight, isTrue);
    });

    test('BP 140/90 or higher is flagged', () {
      expect(_visit().highBloodPressure, isTrue);
    });
  });

  group('OutboxEntry', () {
    final entry = OutboxEntry(
      id: 5,
      operationId: 'op-123',
      entity: GrowthMeasurement.entityName,
      op: OutboxOp.upsert,
      recordId: 'g-1',
      baseVersion: 3,
      changedFields: const ['weightKg', 'notes'],
      payload: _growth().toJson(),
      createdAt: _updated,
    );

    test('builds a push change in the api.md shape', () {
      final c = entry.toChangeJson();
      expect(c['operationId'], 'op-123');
      expect(c['entity'], 'growthMeasurement');
      expect(c['op'], 'upsert');
      expect(c['baseVersion'], 3);
      expect(c['changedFields'], ['weightKg', 'notes']);
      expect((c['data'] as Map)['weightKg'], 7.4);
    });

    test('SQLite round trip keeps operationId, fields and payload', () {
      final m = entry.toMap();
      expect(m['changed_fields'], isA<String>()); // stored as JSON text
      final back = OutboxEntry.fromMap(m);
      expect(back.operationId, 'op-123');
      expect(back.changedFields, ['weightKg', 'notes']);
      expect(back.payload, entry.payload);
      expect(back.status, OutboxStatus.pending);
      expect(back.toMap(), m);
    });
  });

  group('SyncLog', () {
    final log = SyncLog(
      strategy: 'S3', startedAt: _updated, durationMs: 1840, recordCount: 1000,
      changedCount: 100, bytesSent: 52000, bytesReceived: 8100,
      networkProfile: '3G', success: true, conflicts: 2, duplicates: 1, retries: 1,
      runLabel: 'E1-1000-run1',
    );

    test('SQLite round trip', () {
      expect(SyncLog.fromMap(log.toMap()).toMap(), log.toMap());
    });

    test('CSV row matches the header', () {
      final row = log.toCsvRow();
      expect(row.length, SyncLog.csvHeader.length);
      expect(row[SyncLog.csvHeader.indexOf('strategy')], 'S3');
      expect(row[SyncLog.csvHeader.indexOf('success')], 1);
      expect(row[SyncLog.csvHeader.indexOf('error_code')], '');
    });
  });
}
