import 'package:drift/drift.dart';
import 'package:komorebi/src/core/services/database.dart';
import 'package:komorebi/src/features/crawlers/crawler_config.dart';
import 'package:komorebi/src/features/local_collection/vault_items_table.dart';

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
    double? progress,
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
                  status == DownloadStatus.failed ||
                  status == DownloadStatus.cancelled)
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

  /// Resets downloads left in pending/downloading status from a previous session to paused
  Future<int> recoverOrphanedDownloads() {
    return transaction(() async {
      return (update(vaultItems)..where(
            (t) =>
                t.status.equals(DownloadStatus.downloading.index) |
                t.status.equals(DownloadStatus.pending.index),
          ))
          .write(
            const VaultItemsCompanion(status: Value(DownloadStatus.paused)),
          );
    });
  }

  /// Finds existing vault items matching the same parsed title metadata or raw title
  Future<List<VaultItem>> findDuplicates({
    required int excludeId,
    CrawlerParsedTitle? parsedTitle,
    required String rawTitle,
  }) async {
    final allItems = await getAllVaultItems();
    final List<VaultItem> duplicates = [];

    for (final item in allItems) {
      if (item.id == excludeId) continue;

      bool isDuplicate = false;
      final itemParsed = item.crawlerParsedTitle;

      if (parsedTitle != null &&
          parsedTitle.title != null &&
          parsedTitle.title!.isNotEmpty &&
          parsedTitle.episode != null &&
          parsedTitle.episode!.isNotEmpty &&
          itemParsed != null &&
          itemParsed.title != null &&
          itemParsed.title!.isNotEmpty &&
          itemParsed.episode != null &&
          itemParsed.episode!.isNotEmpty) {
        final titleMatch =
            parsedTitle.title!.join(" ").toLowerCase().trim() ==
            itemParsed.title!.join(" ").toLowerCase().trim();
        final epMatch =
            parsedTitle.episode!.join(" ").toLowerCase().trim() ==
            itemParsed.episode!.join(" ").toLowerCase().trim();
        final seasonMatch =
            (parsedTitle.season?.join(" ") ?? "").toLowerCase().trim() ==
            (itemParsed.season?.join(" ") ?? "").toLowerCase().trim();

        if (titleMatch && epMatch && seasonMatch) {
          isDuplicate = true;
        }
      } else {
        if (item.title.toLowerCase().trim() == rawTitle.toLowerCase().trim()) {
          isDuplicate = true;
        }
      }

      if (isDuplicate) {
        duplicates.add(item);
      }
    }

    return duplicates;
  }
}
