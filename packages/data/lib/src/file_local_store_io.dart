import 'dart:convert';
import 'dart:io';

import 'local_store.dart';

class FileLocalStore implements LocalStore {
  FileLocalStore(this.file);

  final File file;

  @override
  Future<Map<String, Object?>?> get(String collection, String id) async {
    final data = await _read();
    return data[collection]?[id];
  }

  @override
  Future<List<Map<String, Object?>>> list(String collection) async {
    final data = await _read();
    final values = data[collection]?.values ??
        const Iterable<Map<String, Object?>>.empty();
    return values.map(Map<String, Object?>.of).toList(growable: false);
  }

  @override
  Future<void> put(
      String collection, String id, Map<String, Object?> value) async {
    final data = await _read();
    final bucket =
        data.putIfAbsent(collection, () => <String, Map<String, Object?>>{});
    bucket[id] = Map<String, Object?>.of(value);
    await _write(data);
  }

  Future<Map<String, Map<String, Map<String, Object?>>>> _read() async {
    if (!await file.exists()) {
      return {};
    }
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return {};
    }
    final decoded = jsonDecode(raw) as Map<String, Object?>;
    return decoded.map((collection, value) {
      final records = (value as Map<String, Object?>).map((id, record) {
        return MapEntry(id, (record as Map).cast<String, Object?>());
      });
      return MapEntry(collection, records);
    });
  }

  Future<void> _write(
      Map<String, Map<String, Map<String, Object?>>> data) async {
    await file.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(data));
  }
}
