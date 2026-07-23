import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:komorebi/providers/crawler_providers.dart';
import 'package:komorebi/screens/crawlers/smart_matcher/scraping_result_tile.dart';
import 'package:komorebi/themes/theme.dart';

class SmartMatcherScreen extends HookConsumerWidget {
  const SmartMatcherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final mediaTitle = useTextEditingController();
    final mediaNumber = useTextEditingController(text: "1");

    final crawlerResults = ref.watch(getCrawlerResultsProvider);

    return Column(
      mainAxisSize: .min,
      children: [
        Form(
          key: formKey,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    "Smart Parser Search",
                    style: context.textTheme.titleLarge?.copyWith(
                      fontFamily: context.fontSerif,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text("ANIME NAME", style: context.textTheme.labelLarge),
                  TextFormField(
                    autofocus: true,
                    controller: mediaTitle,
                    keyboardType: TextInputType.text,
                    validator: (value) =>
                        (value == null || value.isEmpty) ? "Required" : null,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9\s\-_:;!?.,\x27]'),
                      ), // \x27 is for apostrophe ('),
                    ],
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: "e.g. Attack on Titan",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text("EPISODE TARGET", style: context.textTheme.labelLarge),
                  TextFormField(
                    controller: mediaNumber,
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        (value == null || value.isEmpty) ? "Required" : null,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d*'), // allows decimals
                      ),
                    ],
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: "e.g. 1",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      label: const Text("RUN PARALLEL CRAWLER"),
                      icon: const Icon(Icons.search_outlined),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          ref
                              .read(getCrawlerResultsProvider.notifier)
                              .fetch(
                                title: mediaTitle.text,
                                number: mediaNumber.text,
                              );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: .stretch,
                children: [
                  Row(
                    mainAxisAlignment: .spaceBetween,
                    crossAxisAlignment: .end,
                    children: [
                      Text(
                        "Ranked Scraping Results",
                        style: context.textTheme.titleLarge?.copyWith(
                          fontFamily: context.fontSerif,
                        ),
                      ),
                      Text(
                        "Count: ${crawlerResults.results.length}",
                        style: context.textTheme.labelLarge,
                      ),
                    ],
                  ),
                  Expanded(
                    child:
                        crawlerResults.results.isNotEmpty ||
                            crawlerResults.isFetching
                        ? ListView.builder(
                            itemCount:
                                crawlerResults.results.length +
                                (crawlerResults.isFetching ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == crawlerResults.results.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: ListTile(
                                      title: Text("Fetching ..."),
                                      leading: CircularProgressIndicator(),
                                    ),
                                  ),
                                );
                              }
                              final item = crawlerResults.results[index];
                              return ScrapingResultTile(crawlerResult: item);
                            },
                          )
                        : Center(
                            child: Text(
                              !crawlerResults.hasSearched
                                  ? "Enter details above and run search"
                                  : "No match found",
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
