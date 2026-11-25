import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:sqflite/sqflite.dart';

import '../network/connectivity_watcher.dart';
import '../storage/schema.dart';
import 'sync_engine.dart';

/// Why a sync started (shown on the sync screen, useful in the demo).
enum SyncTrigger { opened, reconnect, button }

/// Decides WHEN to sync; [SyncEngine] does the syncing.
///
/// Context-aware behaviour (course week 8): the app reacts to the network.
/// * Connection comes back → wait [settle] (a returning signal often drops
///   again within seconds), check it is still there, then sync.
/// * App opened (or unlocked with the PIN) with a connection → sync once.
/// * "Send now" button → sync now, even with automatic sending off.
/// * Signed out or locked → never sync (the server would answer 401).
///
/// Only one sync runs at a time; extra requests while one runs are ignored
/// (the running one already sends everything that is queued).
class SyncController extends ChangeNotifier {
  SyncController({
    required this.engine,
    required this.connectivity,
    required this.canSync,
    this.signIn,
    this.settle = const Duration(seconds: 3),
  });

  /// Notifies when sign-in changes (the AuthController); syncing starts once
  /// [canSync] turns true, e.g. right after the PIN unlock.
  final Listenable? signIn;

  final SyncEngine engine;
  final ConnectivityWatcher connectivity;

  /// False while signed out or locked.
  final bool Function() canSync;

  /// Wait after the signal returns before syncing.
  final Duration settle;

  bool online = false;
  bool autoSync = true;
  bool syncing = false;

  /// Changes saved on the phone and not yet sent (and those refused).
  int pending = 0;
  int failed = 0;
  DateTime? lastSyncAt;

  /// Result of the last run in this session, and what started it.
  SyncResult? lastResult;
  SyncTrigger? lastTrigger;

  /// +1 after every finished run, so screens know to reload.
  int runs = 0;

  StreamSubscription<bool>? _sub;
  Timer? _settleTimer;
  bool _disposed = false;
  bool _couldSync = false;

  Future<void> start() async {
    autoSync = await engine.store.getMeta(MetaKeys.autoSync) != 'off';
    online = await connectivity.isOnline();
    await refresh();
    _sub = connectivity.changes.listen(_onChange);
    signIn?.addListener(_onSignIn);
    _onSignIn();
  }

  void _onSignIn() {
    final can = canSync();
    if (can && !_couldSync && online) unawaited(_auto(SyncTrigger.opened));
    _couldSync = can;
  }

  /// Re-reads the counts (after a form saved a change, for example).
  Future<void> refresh() async {
    final db = engine.store.db;
    Future<int> count(String status) async =>
        Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM ${Tables.outbox} WHERE status = ?', [status])) ??
        0;
    pending = await count('pending');
    failed = await count('failed');
    final last = await engine.store.getMeta(MetaKeys.lastSyncAt);
    lastSyncAt = last == null ? null : DateTime.parse(last).toLocal();
    _notify();
  }

  Future<void> setAutoSync(bool on) async {
    autoSync = on;
    await engine.store.setMeta(MetaKeys.autoSync, on ? 'on' : 'off');
    _notify();
    if (on && online) unawaited(_auto(SyncTrigger.reconnect));
  }

  /// The "Send now" button. Tries even if the phone thinks it is offline:
  /// connectivity can be wrong, and a failed try is only logged.
  Future<SyncResult?> sendNow() => _run(SyncTrigger.button);

  void _onChange(bool now) {
    final cameBack = !online && now;
    online = now;
    _notify();
    _settleTimer?.cancel();
    if (cameBack) {
      _settleTimer = Timer(settle, () {
        if (online) _auto(SyncTrigger.reconnect);
      });
    }
  }

  Future<void> _auto(SyncTrigger trigger) async {
    if (!autoSync) return;
    await _run(trigger);
  }

  Future<SyncResult?> _run(SyncTrigger trigger) async {
    if (syncing || !canSync()) return null;
    syncing = true;
    _notify();
    try {
      final result = await engine.syncNow();
      if (result != null) {
        lastResult = result;
        lastTrigger = trigger;
      }
      return result;
    } finally {
      syncing = false;
      runs++;
      if (!_disposed) await refresh();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _settleTimer?.cancel();
    _sub?.cancel();
    signIn?.removeListener(_onSignIn);
    super.dispose();
  }
}
