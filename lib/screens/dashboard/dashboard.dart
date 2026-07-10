import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class Dashboard extends HookWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final animeOrManga = useState("anime");

    // fetch all currently watching animes/manga from api for current user
    return Column(
      children: [
        // Filter menu
        Row(
          children: [
            DropdownButton(
              items: [
                DropdownMenuItem(value: "anime", child: Text("Anime")),
                DropdownMenuItem(value: "manga", child: Text("Manga")),
              ],
              onChanged: (value) {
                if (value != null) {
                  animeOrManga.value = value;
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
