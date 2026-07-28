import 'package:komorebi/src/core/providers/common_providers.dart';
import 'package:komorebi/src/core/services/download_service.dart';
import 'package:komorebi/src/features/crawlers/crawler_config.dart';
import 'package:komorebi/src/features/local_collection/vault_items_table.dart';
import 'package:quiver/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part "vault_providers.g.dart";

@Riverpod(keepAlive: true)
class DownloadQueue extends _$DownloadQueue {
  @override
  BiMap<CrawlerResult, DownloadService> build() {
    return BiMap();
  }

  Future<bool> addToQueue(CrawlerResult res) async {
    if (state.containsKey(res)) {
      return false;
    }

    final downloadService = DownloadService(res, ref.read(dbProvider));
    state[res] = downloadService;

    await downloadService.startDownload();

    state = BiMap()..addAll(state);

    return true;
  }

  Future<bool> removeFromQueue(CrawlerResult res) async {
    final service = state[res];
    if (service != null) {
      await service.stopDownload();
    }

    final newMap = BiMap<CrawlerResult, DownloadService>();
    for (final entry in state.entries) {
      if (entry.key != res) {
        newMap[entry.key] = entry.value;
      }
    }
    state = newMap;
    return service != null;
  }
}

@riverpod
class VaultItemNotifier extends _$VaultItemNotifier {
  @override
  Stream<List<VaultItem>> build() async* {
    final db = ref.read(dbProvider);

    yield* db.vaultItemsDao
        .watchVaultItemsByStatus(DownloadStatus.completed)
        .map(_deduplicateVaultItems);
  }

  static List<VaultItem> _deduplicateVaultItems(List<VaultItem> items) {
    final Map<String, VaultItem> seen = {};
    for (final item in items) {
      final key = _getDeduplicationKey(item);
      if (!seen.containsKey(key)) {
        seen[key] = item;
      }
    }
    return seen.values.toList();
  }

  static String _getDeduplicationKey(VaultItem item) {
    final parsed = item.crawlerParsedTitle;
    if (parsed != null &&
        parsed.title != null &&
        parsed.title!.isNotEmpty &&
        parsed.episode != null &&
        parsed.episode!.isNotEmpty) {
      final titleStr = parsed.title!.join(" ").toLowerCase().trim();
      final epStr = parsed.episode!.join(" ").toLowerCase().trim();
      final seasonStr = (parsed.season?.join(" ") ?? "").toLowerCase().trim();
      return "$titleStr|s:$seasonStr|e:$epStr";
    }
    return item.title.toLowerCase().trim();
  }
}
