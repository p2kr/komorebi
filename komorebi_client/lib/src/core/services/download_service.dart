import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:komorebi/src/core/services/database.dart';
import 'package:komorebi/src/core/utils/constants.dart';
import 'package:komorebi/src/core/utils/dio.dart';
import 'package:komorebi/src/core/utils/talker.dart';
import 'package:komorebi/src/models/api/crawler_config.dart';
import 'package:komorebi/src/models/db/vault_items_table.dart';
import 'package:libtorrent_flutter/libtorrent_flutter.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

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
  VaultItem? _vaultItem;
  StreamSubscription? _torrentListener;

  DateTime? _lastProgressDbUpdate;
  double _lastProgressValue = 0.0;

  VaultItem? get vaultItem => _vaultItem;

  bool _shouldUpdateProgressDb(double currentProgress) {
    if (_vaultItem?.status == DownloadStatus.completed ||
        _vaultItem?.status == DownloadStatus.cancelled ||
        _vaultItem?.status == DownloadStatus.failed) {
      return false;
    }

    final now = DateTime.now();
    if (_lastProgressDbUpdate == null) {
      _lastProgressDbUpdate = now;
      _lastProgressValue = currentProgress;
      return true;
    }

    if (currentProgress >= 1.0 && _lastProgressValue < 1.0) {
      _lastProgressDbUpdate = now;
      _lastProgressValue = currentProgress;
      return true;
    }

    if (now.difference(_lastProgressDbUpdate!) >=
            const Duration(milliseconds: 500) ||
        (currentProgress - _lastProgressValue).abs() >= 0.01) {
      _lastProgressDbUpdate = now;
      _lastProgressValue = currentProgress;
      return true;
    }
    return false;
  }

  Future<void> _cleanupPartialFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        talker.debug("Cleaned up partial download file at $filePath");
      }
    } catch (e) {
      talker.warning("Failed to cleanup partial file at $filePath: $e");
    }
  }

  Future<void> _handleDownloadCompletion(
    String partPath,
    String finalPath,
  ) async {
    if (_vaultItem == null) return;

    // 1. Find and cleanup old duplicate items in DB and disk
    final duplicates = await db.vaultItemsDao.findDuplicates(
      excludeId: _vaultItem!.id,
      parsedTitle: _vaultItem!.crawlerParsedTitle,
      rawTitle: _vaultItem!.title,
    );

    for (final oldItem in duplicates) {
      if (oldItem.savePath != null && oldItem.savePath != finalPath) {
        await _cleanupPartialFile(oldItem.savePath);
      }
      await db.vaultItemsDao.deleteVaultItem(oldItem.id);
      talker.debug(
        "Overwrote duplicate vault item #${oldItem.id} (${oldItem.title})",
      );
    }

    // 2. Rename .part file to finalPath if part file was used
    if (partPath != finalPath) {
      final finalFile = File(finalPath);
      if (await finalFile.exists()) {
        await finalFile.delete();
      }

      final partFile = File(partPath);
      if (await partFile.exists()) {
        await partFile.rename(finalPath);
      }
    }

    // 3. Update status in DB to completed
    await db.vaultItemsDao.updateStatus(
      _vaultItem!.id,
      DownloadStatus.completed,
      savePath: finalPath,
    );
    _vaultItem = _vaultItem!.copyWith(
      progress: 1.0,
      status: DownloadStatus.completed,
      savePath: finalPath,
    );
  }

  Future<VaultItem> startDownload() async {
    if (_isTorrent) {
      return _startTorrentDownload();
    } else {
      return _startHttpDownload();
    }
  }

  Future<VaultItem> _startTorrentDownload() async {
    try {
      final baseDir = join(
        (await getApplicationSupportDirectory()).path,
        VAULT_LOC,
      );
      await Directory(baseDir).create(recursive: true);

      final safeFilename = resp.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final filePath = join(baseDir, safeFilename);

      _torrentId = _engine.addMagnet(resp.downloadUrl);

      _vaultItem = await db.vaultItemsDao.insertVaultItem(
        VaultItemsCompanion(
          title: Value(resp.title),
          tempId: Value(_torrentId.toString()),
          url: Value(resp.downloadUrl),
          savePath: Value(filePath),
          status: Value(DownloadStatus.downloading),
          crawlerParsedTitle: Value(resp.parsedTitle),
        ),
      );

      _torrentListener = _engine.torrentUpdates.listen((event) async {
        if (_vaultItem != null && event.containsKey(_torrentId)) {
          final t = event[_torrentId]!;

          if (t.progress >= 1.0 &&
              _vaultItem!.status != DownloadStatus.completed) {
            await db.vaultItemsDao.updateProgress(
              _vaultItem!.id,
              progress: 1.0,
              downloadedBytes: t.totalDone,
              totalBytes: t.totalWanted,
            );
            await _handleDownloadCompletion(filePath, filePath);
            await _torrentListener?.cancel();
            _torrentListener = null;
          } else if (_shouldUpdateProgressDb(t.progress)) {
            await db.vaultItemsDao.updateProgress(
              _vaultItem!.id,
              progress: t.progress,
              downloadedBytes: t.totalDone,
              totalBytes: t.totalWanted,
            );
            _vaultItem = _vaultItem!.copyWith(
              progress: t.progress,
              downloadedBytes: t.totalDone,
              totalBytes: t.totalWanted,
            );
          }
        }
      });
    } catch (e) {
      talker.error("Failed to start torrent download: $e");
      if (_vaultItem != null) {
        await db.vaultItemsDao.updateStatus(
          _vaultItem!.id,
          DownloadStatus.failed,
          errorMessage: e.toString(),
        );
        _vaultItem = _vaultItem!.copyWith(
          status: DownloadStatus.failed,
          errorMessage: e.toString(),
        );
      }
      rethrow;
    }

    return _vaultItem!;
  }

  Future<VaultItem> _startHttpDownload() async {
    final baseDir = join(
      (await getApplicationSupportDirectory()).path,
      VAULT_LOC,
    );
    await Directory(baseDir).create(recursive: true);

    final safeFilename = resp.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final finalFilePath = join(baseDir, safeFilename);
    final partFilePath = "$finalFilePath.part";

    _vaultItem = await db.vaultItemsDao.insertVaultItem(
      VaultItemsCompanion(
        title: Value(resp.title),
        url: Value(resp.downloadUrl),
        savePath: Value(finalFilePath),
        status: Value(DownloadStatus.downloading),
        crawlerParsedTitle: Value(resp.parsedTitle),
      ),
    );

    try {
      final r = await _dio.download(
        resp.downloadUrl,
        partFilePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (count, total) {
          final item = _vaultItem;
          if (item != null && total > 0) {
            final progressVal = count / total;
            if (_shouldUpdateProgressDb(progressVal)) {
              db.vaultItemsDao.updateProgress(
                item.id,
                progress: progressVal,
                downloadedBytes: count,
                totalBytes: total,
              );
              _vaultItem = _vaultItem?.copyWith(
                progress: progressVal,
                downloadedBytes: count,
                totalBytes: total,
              );
            }
          }
        },
      );

      if (r.statusCode == HttpStatus.ok) {
        await _handleDownloadCompletion(partFilePath, finalFilePath);
      } else {
        talker.error("Unable to download ${resp.title}: HTTP ${r.statusCode}");
        await db.vaultItemsDao.updateStatus(
          _vaultItem!.id,
          DownloadStatus.failed,
          errorMessage: "HTTP ${r.statusCode}",
        );
        _vaultItem = _vaultItem?.copyWith(
          status: DownloadStatus.failed,
          errorMessage: "HTTP ${r.statusCode}",
        );
        await _cleanupPartialFile(partFilePath);
      }
    } catch (e) {
      if (_vaultItem != null) {
        final isCancelled = e is DioException && CancelToken.isCancel(e);
        final status = isCancelled
            ? DownloadStatus.cancelled
            : DownloadStatus.failed;
        await db.vaultItemsDao.updateStatus(
          _vaultItem!.id,
          status,
          errorMessage: e.toString(),
        );
        _vaultItem = _vaultItem?.copyWith(
          status: status,
          errorMessage: e.toString(),
        );
      }
      await _cleanupPartialFile(partFilePath);
      if (e is! DioException || !CancelToken.isCancel(e)) {
        talker.error("Error downloading ${resp.title}: $e");
      }
    }

    return _vaultItem!;
  }

  Future<void> stopDownload() async {
    if (_isTorrent) {
      _engine.disposeTorrent(_torrentId);
      await _torrentListener?.cancel();
    } else {
      _cancelToken.cancel();
    }

    if (_vaultItem != null) {
      await db.vaultItemsDao.updateStatus(
        _vaultItem!.id,
        DownloadStatus.cancelled,
      );
      if (_vaultItem!.savePath != null) {
        await _cleanupPartialFile("${_vaultItem!.savePath!}.part");
      }
      _vaultItem = _vaultItem?.copyWith(status: DownloadStatus.cancelled);
    }
  }
}
