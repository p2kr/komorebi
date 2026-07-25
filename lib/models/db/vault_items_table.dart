import 'dart:convert';

import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:komorebi/models/api/crawler_config.dart';

part 'vault_items_table.freezed.dart';

enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

class CrawlerParsedTitleConverter
    extends TypeConverter<CrawlerParsedTitle?, String?> {
  const CrawlerParsedTitleConverter();

  @override
  CrawlerParsedTitle? fromSql(String? fromDb) {
    if (fromDb == null || fromDb.isEmpty) return null;
    try {
      return CrawlerParsedTitle.fromJson(
        jsonDecode(fromDb) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  String? toSql(CrawlerParsedTitle? value) {
    if (value == null) return null;
    return jsonEncode(value.toJson());
  }
}

@UseRowClass(VaultItem)
class VaultItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get tempId => text().nullable()();

  /// Title of the vault item / episode
  TextColumn get title => text()();

  /// Direct download URL or source URI
  TextColumn get url => text()();

  /// Destination file path on the local system
  TextColumn get savePath => text().nullable()();

  /// Current status of the download
  IntColumn get status => intEnum<DownloadStatus>().clientDefault(
    () => DownloadStatus.pending.index,
  )();

  /// Progress fraction between 0.0 and 1.0
  RealColumn get progress => real().withDefault(const Constant(0.0))();

  /// Total file size in bytes
  IntColumn get totalBytes => integer().nullable()();

  /// Number of bytes downloaded so far
  IntColumn get downloadedBytes => integer().withDefault(const Constant(0))();

  /// Serialized CrawlerParsedTitle metadata mapped via TypeConverter
  TextColumn get crawlerParsedTitle =>
      text().map(const CrawlerParsedTitleConverter()).nullable()();

  /// Timestamp when the item was added to the vault
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.timestamp())();

  /// Timestamp when the download finished or failed
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Error message details if status is failed
  TextColumn get errorMessage => text().nullable()();
}

@Freezed(addImplicitFinal: true)
abstract class VaultItem with _$VaultItem {
  const VaultItem._();

  const factory VaultItem({
    required int id,
    String? tempId,
    required String title,
    required String url,
    String? savePath,
    @Default(DownloadStatus.pending) DownloadStatus status,
    @Default(0.0) double progress,
    int? totalBytes,
    @Default(0) int downloadedBytes,
    CrawlerParsedTitle? crawlerParsedTitle,
    required DateTime createdAt,
    DateTime? completedAt,
    String? errorMessage,
  }) = _VaultItem;
}
