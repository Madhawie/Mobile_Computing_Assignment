import 'package:uuid/uuid.dart';

/// The small settings table (`meta`): language, device id, pull cursor …
/// AppDatabase implements it with SQLite; tests use [MemoryMetaStore].
abstract class MetaStore {
  Future<String?> getMeta(String key);
  Future<void> setMeta(String key, String? value);

  /// This phone's id, made once and then kept.
  Future<String> deviceId();
}

class MemoryMetaStore implements MetaStore {
  final values = <String, String?>{};

  @override
  Future<String?> getMeta(String key) async => values[key];

  @override
  Future<void> setMeta(String key, String? value) async => values[key] = value;

  @override
  Future<String> deviceId() async => values['device_id'] ??= const Uuid().v4();
}
