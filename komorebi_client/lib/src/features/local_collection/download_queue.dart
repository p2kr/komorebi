import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:komorebi/src/core/themes/theme.dart';
import 'package:komorebi/src/models/api/crawler_config.dart';
import 'package:komorebi/src/models/db/vault_items_table.dart';
import 'package:komorebi/src/providers/common_providers.dart';
import 'package:komorebi/src/providers/vault_providers.dart';
import 'package:komorebi/src/shared/widgets/chips.dart';
import "package:proper_filesize/proper_filesize.dart";

class DownloadQueue extends HookConsumerWidget {
  const DownloadQueue({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadQueue = ref.watch(downloadQueueProvider);
    final size = MediaQuery.of(context).size;

    return Card(
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          Row(
            spacing: 4,
            children: [
              Icon(Icons.autorenew_outlined, applyTextScaling: true),
              Text(
                "Download Queue",
                style: context.textTheme.titleLarge?.copyWith(
                  fontFamily: context.fontSerif,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          downloadQueue.isEmpty
              ? Container(
                  decoration: BoxDecoration(
                    borderRadius: .all(.circular(2)),
                    border: Border.all(
                      color: context.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Center(child: Text("No active downloads in queue")),
                )
              : ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: size.height * 0.25),
                  child: ListView.builder(
                    physics: ClampingScrollPhysics(),
                    padding: .all(4),
                    // TODO: Check for performance hit. Use sliver list if unacceptable
                    shrinkWrap: true,
                    itemCount: downloadQueue.length,
                    itemBuilder: (context, index) {
                      final cr = downloadQueue.keys.elementAt(index);

                      return downloadQueueTile(cr, context, ref);
                    },
                  ),
                ),
        ],
      ),
    );
  }
}

Widget downloadQueueTile(
  CrawlerResult cr,
  BuildContext context,
  WidgetRef ref,
) {
  final vaultItemId = ref.watch(
    downloadQueueProvider.select((value) => value[cr]!.vaultItem?.id),
  );

  final vaultStream = vaultItemId != null
      ? ref.read(dbProvider).vaultItemsDao.watchVaultItem(vaultItemId)
      : Stream<VaultItem?>.empty();

  return Container(
    margin: .all(4),
    decoration: BoxDecoration(
      borderRadius: .all(.circular(4)),
      border: Border.all(
        color: context.colorScheme.primary.withValues(alpha: 0.5),
      ),
    ),
    child: StreamBuilder<VaultItem?>(
      stream: vaultStream,
      builder: (context, asyncSnapshot) {
        final item = asyncSnapshot.data;

        return ListTile(
          title: Text(cr.title),
          leading: _buildProgressIndicator(item, context),
          subtitle: Row(
            spacing: 2,
            children: [
              ?item?.status == DownloadStatus.completed
                  ? SimpleChip(label: "Completed")
                  : item?.status == DownloadStatus.failed
                  ? SimpleChip(label: "Failed")
                  : item?.progress != null
                  ? SimpleChip(
                      label: "${(item!.progress! * 100).toStringAsFixed(1)}%",
                    )
                  : null,
              if (item?.totalBytes != null)
                SimpleChip(label: getDownloadProgress(item!)),
            ],
          ),
          trailing: IconButton(
            onPressed: () async {
              await ref
                  .read(downloadQueueProvider.notifier)
                  .removeFromQueue(cr);
            },
            icon: Icon(Icons.delete_outline),
          ),
        );
      },
    ),
  );
}

Widget _buildProgressIndicator(VaultItem? item, BuildContext context) {
  if (item == null) {
    return const SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

  switch (item.status) {
    case DownloadStatus.completed:
      return Icon(
        Icons.check_circle_outline,
        color: context.colorScheme.primary,
      );
    case DownloadStatus.failed:
      return Icon(Icons.error_outline, color: context.colorScheme.error);
    case DownloadStatus.cancelled:
      return Icon(Icons.cancel_outlined, color: context.colorScheme.outline);
    case DownloadStatus.pending:
    case DownloadStatus.downloading:
    case DownloadStatus.paused:
      return CircularProgressIndicator(value: item.progress, strokeWidth: 2);
  }
}

String getDownloadProgress(VaultItem item) {
  final downloadedSize = FileSize.fromBytes(
    item.downloadedBytes,
  ).toString(decimals: 2);
  final totalSize = item.totalBytes != null
      ? FileSize.fromBytes(item.totalBytes!).toString(decimals: 2)
      : '0 B';
  return '$downloadedSize / $totalSize';
}
