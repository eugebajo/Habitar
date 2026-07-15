import 'local_store.dart';

class FileLocalStore implements LocalStore {
  FileLocalStore(Object file);

  @override
  Future<Map<String, Object?>?> get(String collection, String id) {
    throw UnsupportedError(
        'FileLocalStore is only available on dart:io platforms.');
  }

  @override
  Future<List<Map<String, Object?>>> list(String collection) {
    throw UnsupportedError(
        'FileLocalStore is only available on dart:io platforms.');
  }

  @override
  Future<void> put(String collection, String id, Map<String, Object?> value) {
    throw UnsupportedError(
        'FileLocalStore is only available on dart:io platforms.');
  }
}
