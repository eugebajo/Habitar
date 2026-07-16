import 'repositories.dart';

class SyncService {
  const SyncService(this.repository);

  final SyncQueueRepository repository;

  Future<SyncQueueItem> recordLocalChange({
    required String collection,
    required String entityId,
    required SyncOperation operation,
    required Map<String, Object?> payload,
  }) {
    return repository.enqueue(
      collection: collection,
      entityId: entityId,
      operation: operation,
      payload: payload,
    );
  }

  Future<List<SyncQueueItem>> pendingChanges() => repository.pending();

  Future<void> markPushed(String itemId) => repository.markPushed(itemId);

  Future<void> markFailed(String itemId, String error) =>
      repository.markFailed(itemId, error);
}
