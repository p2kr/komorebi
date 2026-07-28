import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:komorebi/src/core/themes/theme.dart';
import 'package:komorebi/src/features/local_collection/vault_providers.dart';

class MediaVault extends ConsumerWidget {
  const MediaVault({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultItemsAsync = ref.watch(vaultItemProvider);

    final size = MediaQuery.of(context).size;

    return Column(
      crossAxisAlignment: .stretch,
      mainAxisSize: .min,
      spacing: 4,
      children: [
        Row(
          children: [
            Icon(Icons.local_movies_outlined),
            Text(
              "Offline Media Vault",
              style: context.textTheme.titleLarge?.copyWith(
                fontFamily: context.fontSerif,
              ),
            ),
          ],
        ),
        vaultItemsAsync.when(
          data: (data) {
            if (data.isEmpty) {
              return Text("No items in vault");
            }
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: size.height * 0.5),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: data.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(data[index].title),
                    subtitle: Text(
                      data[index].savePath ?? data[index].url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            );
          },
          error: (error, stackTrace) =>
              Text("Some error occurred accessing vault"),
          loading: () => CircularProgressIndicator(),
        ),
      ],
    );
  }
}
