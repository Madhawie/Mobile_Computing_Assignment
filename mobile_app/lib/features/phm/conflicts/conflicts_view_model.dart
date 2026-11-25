import 'package:material_ui/material_ui.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_models.dart';
import '../../../core/storage/schema.dart';
import '../../../core/sync/sync_store.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/app_repositories.dart';

/// A conflict with the name of the record it is about.
class ConflictItem {
  const ConflictItem(this.conflict, this.recordLabel);
  final Conflict conflict;

  /// Mother's or child's name, or the date of a visit / weighing.
  final String recordLabel;
}

/// P8 · Check a record. Shows the S3 conflicts the server flagged, from the
/// phone's copy first (works offline), then refreshed from the server.
/// Deciding needs signal: the server writes the chosen value as a new
/// version, which every phone then gets in its next pull.
class ConflictsViewModel extends ChangeNotifier {
  ConflictsViewModel(this.repos, this.api, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AppRepositories repos;
  final ApiClient api;
  final DateTime Function() _clock;

  bool loading = true;

  /// True when the list on screen is the phone's copy (no signal).
  bool offline = false;
  String? deviceId;
  List<ConflictItem> items = const [];

  /// Conflict being decided right now (its buttons show a spinner).
  String? deciding;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    deviceId = await repos.store.deviceId();
    await _show();
    loading = false;
    notifyListeners();
    await refresh();
  }

  /// Gets the open list from the server; keeps the phone's copy if offline.
  Future<void> refresh() async {
    try {
      final res = await api.conflicts();
      await repos.conflicts.replaceOpen(res.data);
      offline = false;
    } on ApiFailure {
      offline = true;
    }
    await _show();
    notifyListeners();
  }

  /// "Keep as it is" ([keepCurrent] true) or "Use the other value".
  /// Throws [ApiFailure] when there is no signal.
  Future<void> decide(Conflict c, {required bool keepCurrent}) async {
    deciding = c.id;
    notifyListeners();
    try {
      final res = await api.resolveConflict(c.id, keep: keepCurrent ? 'current' : 'previous');
      // Same rules as a pull: the phone's unsent edits are never overwritten.
      await SyncStore(repos.store).applyPulled([PulledChange(c.entity, res.data.record)]);
      await repos.conflicts.markResolved(c.id, res.data.resolution, _clock());
      await _show();
    } finally {
      deciding = null;
      notifyListeners();
    }
  }

  Future<void> _show() async {
    final list = <ConflictItem>[];
    for (final c in await repos.conflicts.open()) {
      list.add(ConflictItem(c, await _label(c)));
    }
    items = list;
  }

  /// A readable name for the record, from the phone's database.
  Future<String> _label(Conflict c) async {
    final table = Tables.byEntity[c.entity];
    if (table == null) return c.entity;
    final rows = await repos.store.db.query(table, where: 'id = ?', whereArgs: [c.recordId], limit: 1);
    if (rows.isEmpty) return c.entity;
    final r = rows.first;
    return switch (c.entity) {
      'mother' => r['full_name'] as String,
      'child' => r['name'] as String,
      'maternalVisit' => 'Visit ${r['visit_date']}',
      'growthMeasurement' => 'Weight ${r['measured_on']}',
      'vaccination' => '${r['vaccine']} ${r['given_on']}',
      _ => c.entity,
    };
  }
}
