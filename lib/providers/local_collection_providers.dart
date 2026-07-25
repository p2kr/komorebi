import 'package:komorebi/models/api/crawler_config.dart';
import 'package:komorebi/models/db/vault_items_table.dart';
import 'package:komorebi/providers/common_providers.dart';
import 'package:komorebi/services/download_service.dart';
import 'package:quiver/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part "local_collection_providers.g.dart";

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

    downloadService.startDownload();

    state = BiMap()..addAll(state);

    return true;
  }

  bool removeFromQueue(CrawlerResult res) {
    state[res]?.stopDownload();

    bool wasInQueue = state.remove(res) != null;
    state = BiMap()..addAll(state);
    return wasInQueue;
  }
}

@riverpod
class VaultItemNotifier extends _$VaultItemNotifier {
  @override
  Stream<List<VaultItem>> build() async* {
    final db = ref.read(dbProvider);

    yield* db.vaultItemsDao.watchAllVaultItems();
  }
}
