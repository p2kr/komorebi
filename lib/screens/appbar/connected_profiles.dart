import 'package:flutter/material.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/themes/theme.dart';

class ConnectedProfiles extends StatelessWidget {
  const ConnectedProfiles({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        leading: CircleAvatar(child: Icon(Icons.person)),
        title: Text(
          "Profile Name $index",
          style: context.textTheme.headlineSmall?.copyWith(
            fontSize: context.textTheme.titleMedium?.fontSize,
          ),
        ),
        subtitle: Row(
          spacing: 4,
          children: [
            Icon(Icons.person_add_alt, size: 12, applyTextScaling: true),
            Text(S.of(context).sandbox, style: context.textTheme.labelSmall),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline),
          onPressed: () {
            // Handle delete event
          },
        ),
        onTap: () {
          // Handle tap event
        },
      ),
    );
  }
}
