import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:komorebi/models/api/crawler_config.dart';
import 'package:komorebi/providers/crawler_providers.dart';
import 'package:komorebi/themes/theme.dart';

class SmartMatcherScreen extends HookConsumerWidget {
  const SmartMatcherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final mediaTitle = useTextEditingController();
    final mediaNumber = useTextEditingController();

    final searchQuery = useState<({String title, String number})?>(null);

    final AsyncValue<CrawlerResponse> crawlerResultsAsync = searchQuery.value ==
        null
        ? const AsyncValue<CrawlerResponse>.data(
        (results: <CrawlerResult>[], isFetching: false))
        : ref.watch(
            getCrawlerResultsProvider(
              searchQuery.value!.title,
              searchQuery.value!.number,
            ),
          );

    return Column(
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
                    controller: mediaTitle,
                    keyboardType: TextInputType.text,
                    validator: (value) =>
                        (value == null || value.isEmpty) ? "Required" : null,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9\s\-_:;!?.,\x27]'),
                      ), // \x27 is for apostrophe ('),
                    ],
                    decoration: InputDecoration(
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
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: "e.g. 1",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      label: Text("RUN PARALLEL CRAWLER"),
                      icon: Icon(Icons.search_outlined),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          searchQuery.value = (
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Ranked Scraping Results",
                  style: context.textTheme.titleLarge?.copyWith(
                    fontFamily: context.fontSerif,
                  ),
                ),
                Expanded(
                  child: switch (crawlerResultsAsync) {
                    AsyncData<CrawlerResponse>(:final value) =>
                    value.results.isNotEmpty || value.isFetching
                          ? ListView.builder(
                      itemCount: value.results.length +
                          (value.isFetching ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == value.results.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(width: 16),
                                          Text("Fetching more..."),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                final item = value.results[index];
                                return ListTile(
                                  title: Text(item.title),
                                  subtitle: Text(item.source),
                                  leading:
                                  item.parsedTitle?.videoResolution != null
                                      ? Text(
                                    item.parsedTitle!.videoResolution!,
                                        )
                                      : null,
                                  trailing: IconButton.filled(
                                    onPressed: () {
                                      // TODO: Initiate download
                                    },
                                    icon: Icon(Icons.download),
                                  ),
                                );
                              },
                            )
                          : Text("No match found"),

                    AsyncError<CrawlerResponse>() =>
                        Icon(
                      Icons.error_outline,
                    ),

                    _ => CircularProgressIndicator(),
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
