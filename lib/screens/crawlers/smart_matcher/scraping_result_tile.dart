import 'package:flutter/material.dart';
import 'package:komorebi/models/api/crawler_config.dart';
import 'package:komorebi/themes/theme.dart';

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
        subtitle: Text(crawlerResult.source),
        leading: crawlerResult.parsedTitle?.videoResolution != null
            ? Text(crawlerResult.parsedTitle!.videoResolution!)
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
