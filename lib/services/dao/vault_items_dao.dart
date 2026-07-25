import 'package:drift/drift.dart';
import 'package:komorebi/models/db/vault_items_table.dart';
import 'package:komorebi/services/database.dart';

part 'vault_items_dao.g.dart';

@DriftAccessor(tables: [VaultItems])
class VaultItemsDao extends DatabaseAccessor<AppDatabase>
    with _$VaultItemsDaoMixin {
  VaultItemsDao(super.attachedDatabase);

  /// Fetch all vault items ordered by newest first
  Future<List<VaultItem>> getAllVaultItems() {
    return (select(vaultItems)..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ]))
        .get();
  }

  /// Stream all vault items ordered by newest first
  Stream<List<VaultItem>> watchAllVaultItems() {
    return (select(vaultItems)..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  /// Stream vault items filtered by status
  Stream<List<VaultItem>> watchVaultItemsByStatus(DownloadStatus status) {
    return (select(vaultItems)
          ..where((t) => t.status.equals(status.index))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Fetch vault item by ID
  Future<VaultItem?> getVaultItem(int id) {
    return (select(
      vaultItems,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Stream vault item by ID
  Stream<VaultItem?> watchVaultItem(int id) {
    return (select(
      vaultItems,
    )..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  /// Insert a new item into the vault
  Future<VaultItem> insertVaultItem(VaultItemsCompanion item) {
    return transaction(() => into(vaultItems).insertReturning(item));
  }

  /// Update an existing vault item
  Future<bool> updateVaultItem(VaultItem item) {
    return transaction(() async {
      final rows =
          await (update(vaultItems)..where((t) => t.id.equals(item.id))).write(
            VaultItemsCompanion(
              title: Value(item.title),
              url: Value(item.url),
              savePath: Value(item.savePath),
              status: Value(item.status),
              progress: Value(item.progress),
              totalBytes: Value(item.totalBytes),
              downloadedBytes: Value(item.downloadedBytes),
              crawlerParsedTitle: Value(item.crawlerParsedTitle),
              createdAt: Value(item.createdAt),
              completedAt: Value(item.completedAt),
              errorMessage: Value(item.errorMessage),
            ),
          );
      return rows > 0;
    });
  }

  /// Update download progress
  Future<int> updateProgress(
    int id, {
    required double progress,
    required int downloadedBytes,
    int? totalBytes,
  }) {
    return transaction(() async {
      return (update(vaultItems)..where((t) => t.id.equals(id))).write(
        VaultItemsCompanion(
          progress: Value(progress),
          downloadedBytes: Value(downloadedBytes),
          totalBytes: totalBytes != null
              ? Value(totalBytes)
              : const Value.absent(),
        ),
      );
    });
  }

  /// Update status of a download task
  Future<int> updateStatus(
    int id,
    DownloadStatus status, {
    String? savePath,
    String? errorMessage,
  }) {
    return transaction(() async {
      return (update(vaultItems)..where((t) => t.id.equals(id))).write(
        VaultItemsCompanion(
          status: Value(status),
          savePath: savePath != null ? Value(savePath) : const Value.absent(),
          errorMessage: errorMessage != null
              ? Value(errorMessage)
              : const Value.absent(),
          completedAt:
              (status == DownloadStatus.completed ||
                  status == DownloadStatus.failed)
              ? Value(DateTime.timestamp())
              : const Value.absent(),
        ),
      );
    });
  }

  /// Delete a vault item by ID
  Future<int> deleteVaultItem(int id) {
    return transaction(
      () => (delete(vaultItems)..where((t) => t.id.equals(id))).go(),
    );
  }
}
