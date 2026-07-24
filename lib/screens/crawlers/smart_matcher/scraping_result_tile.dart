import 'package:flutter/material.dart';
import 'package:komorebi/models/api/crawler_config.dart';
import 'package:komorebi/themes/theme.dart';
import 'package:komorebi/widgets/chips.dart';

class ScrapingResultTile extends StatelessWidget {
  final CrawlerResult crawlerResult;

  const ScrapingResultTile({super.key, required this.crawlerResult});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: .symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: .circular(4),
        border: BoxBorder.all(color: context.colorScheme.surfaceBright),
      ),
      child: ListTile(
        title: Text(crawlerResult.title),
        subtitle: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            SimpleChip(label: crawlerResult.source),
            SimpleChip(
              label: crawlerResult.popularity % 1 == 0
                  ? crawlerResult.popularity.toInt().toString()
                  : crawlerResult.popularity.toString(),
              icon: Icons.person,
            ),
            if (crawlerResult.size != null && crawlerResult.size!.isNotEmpty)
              SimpleChip(label: crawlerResult.size!),
          ],
        ),
        leading:
            crawlerResult.parsedTitle?.videoResolution !=
                null //TODO: Fix
            ? Text(crawlerResult.parsedTitle!.videoResolution!.first)
            : null,
        trailing: IconButton.filled(
          onPressed: () {
            // TODO: Initiate download
          },
          icon: const Icon(Icons.download_outlined),
        ),
      ),
    );
  }
}
