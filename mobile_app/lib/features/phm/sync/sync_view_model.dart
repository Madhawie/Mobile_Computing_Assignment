import 'package:material_ui/material_ui.dart';

import '../../../core/sync/sync_controller.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/app_repositories.dart';

/// One outbox row as the PHM sees it: what kind of record, whose, when.
class PendingItem {
  const PendingItem(this.entry, this.name);
  final OutboxEntry entry;

  /// Mother or child name, so "Growth · Kavin" is clear without ids.
  final String name;
}

/// P9 · Sync. Lists the outbox from the phone's database; the counts,
/// online state and the buttons come from [SyncController].
class SyncViewModel extends ChangeNotifier {
  SyncViewModel(this.repos, this.sync) {
    sync.addListener(_onSync);
  }

  final AppRepositories repos;
  final SyncController sync;

  bool loading = true;
  List<PendingItem> waiting = const [];
  List<PendingItem> refused = const [];
  int _seenRuns = -1;

  Future<void> load() async {
    _seenRuns = sync.runs;
    waiting = await _items(await repos.outbox.pending());
    refused = await _items(await repos.outbox.failed());
    loading = false;
    notifyListeners();
  }

  /// After every finished sync the list changes; reload it.
  void _onSync() {
    if (!sync.syncing && sync.runs != _seenRuns) load();
  }

  Future<List<PendingItem>> _items(List<OutboxEntry> entries) async {
    // Newest first, like the design; the phone still SENDS oldest first.
    final items = [for (final e in entries.reversed) PendingItem(e, await _nameOf(e))];
    return items;
  }

  /// The name stored in the change itself, or looked up from its parent.
  Future<String> _nameOf(OutboxEntry e) async {
    final p = e.payload;
    switch (e.entity) {
      case Mother.entityName:
        return p['fullName'] as String? ?? '';
      case Child.entityName:
        return p['name'] as String? ?? '';
      case MaternalVisit.entityName:
        final id = p['motherId'] as String?;
        return id == null ? '' : (await repos.mothers.getById(id, includeDeleted: true))?.fullName ?? '';
      default: // growth, vaccination
        final id = p['childId'] as String?;
        return id == null ? '' : (await repos.children.getById(id, includeDeleted: true))?.name ?? '';
    }
  }

  @override
  void dispose() {
    sync.removeListener(_onSync);
    super.dispose();
  }
}
