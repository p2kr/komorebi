import 'package:flutter/material.dart';
import 'package:komorebi/src/features/crawlers/crawler_config.dart';
import 'package:komorebi/src/features/local_collection/download_queue.dart';
import 'package:komorebi/src/features/local_collection/media_player.dart';
import 'package:komorebi/src/features/local_collection/media_vault.dart';
import 'package:komorebi/src/shared/widgets/chips.dart';

class LocalCollection extends StatelessWidget {
  const LocalCollection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        spacing: 4,
        children: [DownloadQueue(), MediaVault(), MediaPlayer()],
      ),
    );
  }
}

Widget downloadQueueTile(CrawlerResult data) {
  return Column(
    children: [
      Row(
        children: [
          Text(data.title),
          SimpleChip(label: "Progress"),
        ],
      ),
    ],
  );
}
