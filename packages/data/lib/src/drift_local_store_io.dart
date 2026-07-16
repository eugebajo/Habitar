import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'local_store.dart';

class DriftLocalStore implements LocalStore {
  DriftLocalStore._(this._executor);

  final QueryExecutor _executor;

  static Future<DriftLocalStore> open(File file) async {
    await file.parent.create(recursive: true);
    final store = DriftLocalStore._(NativeDatabase(file));
    await store._ensureSchema();
    return store;
  }

  static Future<DriftLocalStore> memory() async {
    final store = DriftLocalStore._(NativeDatabase.memory());
    await store._ensureSchema();
    return store;
  }

  Future<void> close() => _executor.close();

  @override
  Future<Map<String, Object?>?> get(String collection, String id) async {
    final result = await _executor.runSelect(
      'SELECT payload_json FROM local_records WHERE collection = ? AND id = ? LIMIT 1',
      [collection, id],
    );
    if (result.isEmpty) {
      return null;
    }
    return _decodePayload(result.single['payload_json'] as String);
  }

  @override
  Future<List<Map<String, Object?>>> list(String collection) async {
    final result = await _executor.runSelect(
      'SELECT payload_json FROM local_records WHERE collection = ? ORDER BY updated_at ASC',
      [collection],
    );
    return result
        .map((row) => _decodePayload(row['payload_json'] as String))
        .toList(growable: false);
  }

  @override
  Future<void> put(
      String collection, String id, Map<String, Object?> value) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _executor.runCustom(
      '''
      INSERT INTO local_records (collection, id, payload_json, updated_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(collection, id)
      DO UPDATE SET payload_json = excluded.payload_json, updated_at = excluded.updated_at
      ''',
      [collection, id, jsonEncode(value), now],
    );
  }

  Future<void> _ensureSchema() async {
    await _executor.ensureOpen(const _DriftLocalStoreExecutorUser());
    await _executor.runCustom('''
      CREATE TABLE IF NOT EXISTS local_records (
        collection TEXT NOT NULL,
        id TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        PRIMARY KEY (collection, id)
      )
    ''');
    await _executor.runCustom(
      'CREATE INDEX IF NOT EXISTS local_records_collection_idx ON local_records(collection)',
    );
  }

  Map<String, Object?> _decodePayload(String raw) {
    return (jsonDecode(raw) as Map).cast<String, Object?>();
  }
}

class _DriftLocalStoreExecutorUser implements QueryExecutorUser {
  const _DriftLocalStoreExecutorUser();

  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(
      QueryExecutor executor, OpeningDetails details) async {}
}
