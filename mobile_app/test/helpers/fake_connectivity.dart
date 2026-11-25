import 'dart:async';

import 'package:little_bloom/core/network/connectivity_watcher.dart';

/// A "signal" the test switches on and off.
class FakeConnectivity implements ConnectivityWatcher {
  FakeConnectivity({this.online = false});

  bool online;
  final _changes = StreamController<bool>.broadcast();

  void set(bool value) {
    online = value;
    _changes.add(value);
  }

  @override
  Future<bool> isOnline() async => online;

  @override
  Stream<bool> get changes => _changes.stream;
}
