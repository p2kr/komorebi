import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:komorebi/models/api/crawler_config.dart';
import 'package:komorebi/models/db/vault_items_table.dart';
import 'package:komorebi/services/database.dart';
import 'package:komorebi/utils/constants.dart';
import 'package:komorebi/utils/dio.dart';
import 'package:komorebi/utils/talker.dart';
import 'package:libtorrent_flutter/libtorrent_flutter.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

@immutable
class DownloadService {
  final CrawlerResult resp;
  final AppDatabase db;

  DownloadService(this.resp, this.db)
    : _isTorrent = resp.downloadUrl.startsWith("magnet");

  final _engine = LibtorrentFlutter.instance;
  final _dio = getDioWithLogger();
  final _cancelToken = CancelToken();

  final bool _isTorrent;
  late final int _torrentId;
  late final VaultItem vaultItem;

  Future<VaultItem> startDownload() async {
    if (_isTorrent) {
      return _startTorrentDownload();
    } else {
      return _startHttpDownload();
    }
  }

  Future<VaultItem> _startTorrentDownload() async {
    _torrentId = _engine.addMagnet(resp.downloadUrl);

    vaultItem = await db.vaultItemsDao.insertVaultItem(
      VaultItemsCompanion(
        title: Value(resp.title),
        tempId: Value(_torrentId.toString()),
        url: Value(resp.downloadUrl),
      ),
    );

    _engine.torrentUpdates.listen((event) {
      final t = event[_torrentId]!;
      db.vaultItemsDao.updateProgress(
        vaultItem.id,
        progress: t.progress,
        downloadedBytes: t.totalDone,
        totalBytes: t.totalWanted,
      );
    });

    return vaultItem;
  }

  Future<VaultItem> _startHttpDownload() async {
    final path = join((await getApplicationSupportDirectory()).path, VAULT_LOC);

    vaultItem = await db.vaultItemsDao.insertVaultItem(
      VaultItemsCompanion(
        title: Value(resp.title),
        url: Value(resp.downloadUrl),
      ),
    );

    final r = await _dio.download(
      resp.downloadUrl,
      path,
      cancelToken: _cancelToken,
      onReceiveProgress: (count, total) {
        // update db progress
        db.vaultItemsDao.updateProgress(
          vaultItem.id,
          progress: count / total,
          downloadedBytes: count,
        );
      },
    );

    if (r.statusCode != HttpStatus.ok) {
      talker.error("unable to download ${resp.title}");
    }

    return vaultItem;
  }

  void stopDownload() {
    if (_isTorrent) {
      _engine.disposeTorrent(_torrentId);
    } else {
      _cancelToken.cancel();
    }
  }
}
