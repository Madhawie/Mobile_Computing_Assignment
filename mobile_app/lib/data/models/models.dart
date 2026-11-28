/// Import this one file to get every model.
library;

export 'child.dart';
export 'conflict.dart';
export 'growth_measurement.dart';
export 'maternal_visit.dart';
export 'model_utils.dart';
export 'mother.dart';
export 'outbox_entry.dart';
export 'sync_log.dart';
export 'sync_record.dart';
export 'vaccination.dart';

import 'child.dart';
import 'growth_measurement.dart';
import 'maternal_visit.dart';
import 'mother.dart';
import 'sync_record.dart';
import 'vaccination.dart';

/// Builds the right model from a pulled change (`entity` + `record`).
SyncRecord recordFromJson(String entity, Map<String, dynamic> json) =>
    switch (entity) {
      Mother.entityName => Mother.fromJson(json),
      MaternalVisit.entityName => MaternalVisit.fromJson(json),
      Child.entityName => Child.fromJson(json),
      GrowthMeasurement.entityName => GrowthMeasurement.fromJson(json),
      Vaccination.entityName => Vaccination.fromJson(json),
      _ => throw ArgumentError.value(entity, 'entity', 'Unknown entity'),
    };

/// Builds the right model from a local SQLite row (used by S1, which sends
/// every record, not only the outbox).
SyncRecord recordFromMap(String entity, Map<String, dynamic> row) =>
    switch (entity) {
      Mother.entityName => Mother.fromMap(row),
      MaternalVisit.entityName => MaternalVisit.fromMap(row),
      Child.entityName => Child.fromMap(row),
      GrowthMeasurement.entityName => GrowthMeasurement.fromMap(row),
      Vaccination.entityName => Vaccination.fromMap(row),
      _ => throw ArgumentError.value(entity, 'entity', 'Unknown entity'),
    };
