import 'package:flutter/material.dart';
import 'package:komorebi/themes/theme.dart';

class SimpleChip extends StatelessWidget {
  const SimpleChip({
    super.key,
    required this.label,
    this.icon,
    this.labelStyle,
  });

  final String label;
  final IconData? icon;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = labelStyle ?? context.textTheme.labelSmall;
    final iconSize = resolvedStyle?.fontSize != null
        ? resolvedStyle!.fontSize! * 1.2
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            if (icon != null)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 2.0),
                  child: Icon(
                    icon,
                    size: iconSize,
                    applyTextScaling: true,
                    color: resolvedStyle?.color,
                  ),
                ),
              ),
            TextSpan(text: label),
          ],
        ),
        style: resolvedStyle,
      ),
    );
  }
}
