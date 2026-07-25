import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:komorebi/models/api/crawler_config.dart';
import 'package:komorebi/providers/local_collection_providers.dart';
import 'package:komorebi/themes/theme.dart';
import 'package:komorebi/widgets/chips.dart';

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
                      final item = downloadQueue.keys.elementAt(index);

                      return downloadQueueTile(item, context, ref);
                    },
                  ),
                ),
        ],
      ),
    );
  }
}

Widget downloadQueueTile(
  CrawlerResult item,
  BuildContext context,
  WidgetRef ref,
) {
  return Container(
    margin: .all(4),
    decoration: BoxDecoration(
      borderRadius: .all(.circular(4)),
      border: Border.all(
        color: context.colorScheme.primary.withValues(alpha: 0.5),
      ),
    ),
    child: ListTile(
      title: Text(item.title),
      leading: CircularProgressIndicator(value: 0.6, strokeWidth: 2),
      subtitle: Wrap(
        spacing: 4,
        children: [SimpleChip(label: "1.23 Mbps", icon: Icons.speed_outlined)],
      ),
      trailing: IconButton(
        onPressed: () {
          ref.read(downloadQueueProvider.notifier).removeFromQueue(item);
        },
        icon: Icon(Icons.delete_outline),
      ),
    ),
  );
}
