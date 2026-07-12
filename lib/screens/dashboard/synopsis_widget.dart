import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/themes/theme.dart';

class SynopsisWidget extends HookWidget {
  final String? text;
  final TextStyle? textStyle;
  final TextStyle? linkStyle;
  final String? showMoreText;

  const SynopsisWidget({
    super.key,
    required this.text,
    this.textStyle,
    this.linkStyle,
    this.showMoreText,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedShowMoreText = showMoreText ?? S.of(context).showMore;
    final synopsisText = text ?? "";
    final tapRecognizer = useMemoized(() => TapGestureRecognizer());

    // Keeping the closure updated with the latest context
    tapRecognizer.onTap = () {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(S.of(context).synopsis),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(synopsisText, style: context.textTheme.bodyMedium),
          ),
        ),
      );
    };

    useEffect(() {
      return tapRecognizer.dispose;
    }, [tapRecognizer]);

    final defaultTextStyle = context.textTheme.bodySmall?.copyWith(
      fontStyle: FontStyle.italic,
    );
    final resolvedTextStyle = textStyle ?? defaultTextStyle;
    final resolvedLinkStyle =
        linkStyle ??
        resolvedTextStyle?.copyWith(fontWeight: .bold, fontStyle: .normal);

    if (synopsisText.isEmpty) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Center(
            child: Text(
              S.of(context).noSynopsisAvailable,
              textAlign: TextAlign.center,
              style: resolvedTextStyle,
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return _MemoizedSynopsisText(
              text: synopsisText,
              maxWidth: constraints.maxWidth,
              maxHeight: constraints.maxHeight,
              textStyle: resolvedTextStyle,
              linkStyle: resolvedLinkStyle,
              showMoreText: resolvedShowMoreText,
              tapRecognizer: tapRecognizer,
            );
          },
        ),
      ),
    );
  }
}

class _MemoizedSynopsisText extends HookWidget {
  final String text;
  final double maxWidth;
  final double maxHeight;
  final TextStyle? textStyle;
  final TextStyle? linkStyle;
  final String showMoreText;
  final TapGestureRecognizer tapRecognizer;

  const _MemoizedSynopsisText({
    required this.text,
    required this.maxWidth,
    required this.maxHeight,
    required this.textStyle,
    required this.linkStyle,
    required this.showMoreText,
    required this.tapRecognizer,
  });

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final directionality = Directionality.of(context);

    return useMemoized(
      () {
        final span = TextSpan(text: text, style: textStyle);
        final tp = TextPainter(
          text: span,
          textDirection: directionality,
          textScaler: textScaler,
        );

        int maxLines = 3;
        if (!maxHeight.isInfinite) {
          maxLines = (maxHeight / tp.preferredLineHeight).floor();
          if (maxLines < 1) maxLines = 1;
        }

        tp.maxLines = maxLines;
        tp.layout(maxWidth: maxWidth);

        if (!tp.didExceedMaxLines) {
          final result = Text.rich(
            span,
            maxLines: maxLines,
            overflow: TextOverflow.clip,
          );
          tp.dispose();
          return result;
        }

        // Using \u2026 (single character ellipsis) instead of ... is safer for layout math
        final link = TextSpan(
          text: "\u2026 $showMoreText",
          style: linkStyle,
          recognizer: tapRecognizer,
        );

        int start = 0;
        int end = text.length;
        int mid = 0;

        tp.dispose();

        // SAFETY BUFFER: Subtract a few pixels so TextPainter leaves breathing room
        // for the Text.rich widget, preventing fractional pixel wrapping issues.
        final safeMaxWidth = maxWidth > 8.0 ? maxWidth - 8.0 : maxWidth;

        while (start < end) {
          mid = start + ((end - start) / 2).ceil();
          final testSpan = TextSpan(
            children: [
              TextSpan(text: text.substring(0, mid), style: textStyle),
              link,
            ],
          );

          final testPainter = TextPainter(
            text: testSpan,
            maxLines: maxLines,
            textDirection: directionality,
            textScaler: textScaler,
          );

          testPainter.layout(maxWidth: safeMaxWidth);

          if (testPainter.didExceedMaxLines) {
            end = mid - 1;
          } else {
            start = mid;
          }

          testPainter.dispose();
        }

        return Text.rich(
          TextSpan(
            children: [
              TextSpan(text: text.substring(0, start), style: textStyle),
              link,
            ],
          ),
          maxLines: maxLines,
          overflow: TextOverflow.clip,
        );
      },
      [
        text,
        maxWidth,
        maxHeight,
        textStyle,
        linkStyle,
        showMoreText,
        textScaler,
        directionality,
        tapRecognizer,
      ],
    );
  }
}
