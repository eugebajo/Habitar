import 'local_store.dart';

class DriftLocalStore implements LocalStore {
  DriftLocalStore._();

  static Future<DriftLocalStore> open(Object file) {
    throw UnsupportedError(
        'DriftLocalStore is only available on dart:io platforms.');
  }

  static Future<DriftLocalStore> memory() {
    throw UnsupportedError(
        'DriftLocalStore is only available on dart:io platforms.');
  }

  Future<void> close() async {}

  @override
  Future<Map<String, Object?>?> get(String collection, String id) {
    throw UnsupportedError(
        'DriftLocalStore is only available on dart:io platforms.');
  }

  @override
  Future<List<Map<String, Object?>>> list(String collection) {
    throw UnsupportedError(
        'DriftLocalStore is only available on dart:io platforms.');
  }

  @override
  Future<void> put(String collection, String id, Map<String, Object?> value) {
    throw UnsupportedError(
        'DriftLocalStore is only available on dart:io platforms.');
  }
}
