import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

enum MediaType { anime, manga }

class Dashboard extends HookWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final animeOrManga = useState(MediaType.anime);

    // fetch all currently watching animes/manga from api for current user
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Filter menu
          Row(
            children: [
              DropdownMenu(
                initialSelection: animeOrManga.value,
                label: Text("Media type"),
                dropdownMenuEntries: [
                  DropdownMenuEntry(value: MediaType.anime, label: "Anime"),
                  DropdownMenuEntry(value: MediaType.manga, label: "Manga"),
                ],
                onSelected: (value) {
                  if (value != null) {
                    animeOrManga.value = value;
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
