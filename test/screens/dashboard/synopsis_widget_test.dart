import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/screens/dashboard/synopsis_widget.dart';

void main() {
  Widget buildTestableWidget(Widget child, {double height = 100.0}) {
    return MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      theme: ThemeData(
        textTheme: const TextTheme(
          bodySmall: TextStyle(fontSize: 12.0, color: Colors.grey),
        ),
      ),
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: height,
          child: Column(children: [child]),
        ),
      ),
    );
  }

  TextStyle? findStyleForText(InlineSpan span, String targetText) {
    if (span is TextSpan) {
      if (span.text != null && span.text!.contains(targetText)) {
        return span.style;
      }
      if (span.children != null) {
        for (final child in span.children!) {
          final style = findStyleForText(child, targetText);
          if (style != null) return style;
        }
      }
    }
    return null;
  }

  group('SynopsisWidget Tests', () {
    testWidgets(
      'Applies defaultTextStyle when textStyle and linkStyle are not provided',
      (WidgetTester tester) async {
        const text = 'Short synopsis text that fits.';

        await tester.pumpWidget(
          buildTestableWidget(const SynopsisWidget(text: text)),
        );
        await tester.pumpAndSettle();

        final richTextFinder = find.byType(RichText);
        expect(richTextFinder, findsOneWidget);
        final richText = tester.widget<RichText>(richTextFinder);
        final textSpan = richText.text as TextSpan;

        final style = findStyleForText(textSpan, text);
        expect(style, isNotNull);
        expect(style!.fontSize, 12.0);
        expect(style.color, Colors.grey);
        expect(style.fontStyle, FontStyle.italic);
      },
    );

    testWidgets('Applies custom textStyle to synopsis text when provided', (
      WidgetTester tester,
    ) async {
      const text = 'Short synopsis text.';
      const customTextStyle = TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          const SynopsisWidget(text: text, textStyle: customTextStyle),
        ),
      );
      await tester.pumpAndSettle();

      final richTextFinder = find.byType(RichText);
      expect(richTextFinder, findsOneWidget);
      final richText = tester.widget<RichText>(richTextFinder);
      final textSpan = richText.text as TextSpan;

      final style = findStyleForText(textSpan, text);
      expect(style, isNotNull);
      expect(style!.fontSize, 16.0);
      expect(style.fontWeight, FontWeight.bold);
      expect(style.color, Colors.blue);
      expect(style.fontStyle, isNot(FontStyle.italic));
    });

    testWidgets(
      'Applies custom textStyle and derives linkStyle (bold/normal) when only textStyle is provided on overflow',
      (WidgetTester tester) async {
        const text =
            'This is a very long synopsis text that will definitely exceed the '
            'height limits of the test widget container. It needs to be long enough '
            'so that the text painter detects it has exceeded the maximum lines constraint.';
        const customTextStyle = TextStyle(fontSize: 14.0, color: Colors.red);

        await tester.pumpWidget(
          buildTestableWidget(
            const SynopsisWidget(text: text, textStyle: customTextStyle),
            height: 40.0, // Force overflow
          ),
        );
        await tester.pumpAndSettle();

        final richTextFinder = find.byType(RichText);
        expect(richTextFinder, findsOneWidget);
        final richText = tester.widget<RichText>(richTextFinder);
        final textSpan = richText.text as TextSpan;

        // Find style of the main text part
        final mainTextStyle = findStyleForText(textSpan, 'This is a very long');
        expect(mainTextStyle, isNotNull);
        expect(mainTextStyle!.color, Colors.red);
        expect(mainTextStyle.fontSize, 14.0);

        // Find style of the link part
        final linkStyle = findStyleForText(textSpan, 'Show More');
        expect(linkStyle, isNotNull);
        expect(linkStyle!.color, Colors.red);
        expect(linkStyle.fontSize, 14.0);
        expect(linkStyle.fontWeight, FontWeight.bold);
        expect(linkStyle.fontStyle, FontStyle.normal);
      },
    );

    testWidgets(
      'Applies separate textStyle and linkStyle when both are provided on overflow',
      (WidgetTester tester) async {
        const text =
            'This is a very long synopsis text that will definitely exceed the '
            'height limits of the test widget container. It needs to be long enough '
            'so that the text painter detects it has exceeded the maximum lines constraint.';
        const customTextStyle = TextStyle(fontSize: 14.0, color: Colors.green);
        const customLinkStyle = TextStyle(
          fontSize: 15.0,
          color: Colors.orange,
          fontWeight: FontWeight.bold,
        );

        await tester.pumpWidget(
          buildTestableWidget(
            const SynopsisWidget(
              text: text,
              textStyle: customTextStyle,
              linkStyle: customLinkStyle,
            ),
            height: 40.0, // Force overflow
          ),
        );
        await tester.pumpAndSettle();

        final richTextFinder = find.byType(RichText);
        expect(richTextFinder, findsOneWidget);
        final richText = tester.widget<RichText>(richTextFinder);
        final textSpan = richText.text as TextSpan;

        // Find style of the main text part
        final mainTextStyle = findStyleForText(textSpan, 'This is a very long');
        expect(mainTextStyle, isNotNull);
        expect(mainTextStyle!.color, Colors.green);
        expect(mainTextStyle.fontSize, 14.0);

        // Find style of the link part
        final linkStyle = findStyleForText(textSpan, 'Show More');
        expect(linkStyle, isNotNull);
        expect(linkStyle!.color, Colors.orange);
        expect(linkStyle.fontSize, 15.0);
        expect(linkStyle.fontWeight, FontWeight.bold);
      },
    );

    testWidgets(
      'Applies custom textStyle to "[NO SYNOPSIS AVAILABLE]" text when text is null or empty',
      (WidgetTester tester) async {
        const customTextStyle = TextStyle(fontSize: 18.0, color: Colors.purple);

        await tester.pumpWidget(
          buildTestableWidget(
            const SynopsisWidget(text: null, textStyle: customTextStyle),
          ),
        );
        await tester.pumpAndSettle();

        final textWidgetFinder = find.text('[NO SYNOPSIS AVAILABLE]');
        expect(textWidgetFinder, findsOneWidget);
        final textWidget = tester.widget<Text>(textWidgetFinder);

        expect(textWidget.style?.fontSize, 18.0);
        expect(textWidget.style?.color, Colors.purple);
      },
    );

    testWidgets('Applies custom showMoreText on overflow', (
      WidgetTester tester,
    ) async {
      const text =
          'This is a very long synopsis text that will definitely exceed the '
          'height limits of the test widget container. It needs to be long enough '
          'so that the text painter detects it has exceeded the maximum lines constraint.';

      await tester.pumpWidget(
        buildTestableWidget(
          const SynopsisWidget(text: text, showMoreText: 'CLICK FOR MORE'),
          height: 40.0, // Force overflow
        ),
      );
      await tester.pumpAndSettle();

      final richTextFinder = find.byType(RichText);
      expect(richTextFinder, findsOneWidget);
      final richText = tester.widget<RichText>(richTextFinder);
      final textSpan = richText.text as TextSpan;

      // Find the link part by checking for custom showMoreText
      final linkStyle = findStyleForText(textSpan, 'CLICK FOR MORE');
      expect(linkStyle, isNotNull);
    });
  });
}
