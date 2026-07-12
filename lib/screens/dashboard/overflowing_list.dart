import 'package:flutter/material.dart';
import 'package:komorebi/models/mal_models.dart';
import 'package:komorebi/themes/theme.dart';
import 'package:komorebi/widgets/chips.dart';
import 'package:overflow_view/overflow_view.dart';

class OverflowingGenreList extends StatelessWidget {
  const OverflowingGenreList({super.key, required this.genres});

  final List<MalNamedNode> genres;

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.bodyMedium?.copyWith(
      color: context.colorScheme.onSurfaceVariant,
    );
    final iconSize = context.textTheme.bodyMedium?.fontSize ?? 14.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Icon(Icons.label, size: iconSize),
        Flexible(
          child: OverflowView.flexible(
            spacing: 4,
            children: [
              for (int i = 0; i < genres.length; i++)
                Text(
                  genres[i].name + (i < genres.length - 1 ? ',' : ''),
                  style: style,
                ),
            ],
            builder: (context, remainingCount) {
              return Tooltip(
                message: genres
                    .skip(genres.length - remainingCount)
                    .map((g) => g.name)
                    .join('\n'),
                child: Text("+$remainingCount", style: style),
              );
            },
          ),
        ),
      ],
    );
  }
}

class OverflowingStatisticsList extends StatelessWidget {
  const OverflowingStatisticsList({super.key, required this.statistics});

  final List<SimpleChip> statistics;

  @override
  Widget build(BuildContext context) {
    return OverflowView.flexible(
      spacing: 2,
      children: statistics,
      builder: (context, remainingCount) {
        return Tooltip(
          message: statistics
              .skip(statistics.length - remainingCount)
              .map((chip) => chip.label)
              .join('\n'),
          child: SimpleChip(label: "+$remainingCount"),
        );
      },
    );
  }
}
