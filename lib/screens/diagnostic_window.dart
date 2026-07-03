import 'package:flutter/material.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/themes/theme.dart';
import 'package:komorebi/utils/talker.dart';
import 'package:talker_flutter/talker_flutter.dart';

class DiagnosticWindow extends StatelessWidget {
  const DiagnosticWindow({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return CallbackShortcuts(
      bindings: {LogicalKeySet(.escape): () => _onClose(context)},
      child: Focus(
        autofocus: true,
        child: Dialog(
          child: SizedBox(
            width: size.width * 0.9,
            height: size.height * 0.75,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                spacing: 8,
                children: [
                  Row(
                    spacing: 8,
                    children: [
                      Icon(Icons.monitor_heart_outlined),
                      Text(
                        S.of(context).systemDiagnosticsLoggingVault,
                        style: context.textTheme.titleLarge,
                      ),
                      Spacer(),
                      TextButton(
                        onPressed: () => _onClose(context),
                        child: Text(
                          "${S.of(context).close} [X]",
                          style: context.textTheme.labelMedium,
                        ),
                      ),
                    ],
                  ),
                  Divider(),
                  Row(
                    spacing: 8,
                    children: [
                      _getDropdown(context, _DropdownType.LEVEL, [
                        "all",
                        "info",
                        "warning",
                        "error",
                      ]),
                      _getDropdown(context, _DropdownType.CATEGORY, [
                        "all",
                        // "web crawler",
                        // "mal sync",
                        // "file system",
                        // "queue engine",
                      ]),
                    ],
                  ),
                  Flexible(
                    child: ListView.builder(
                      padding: .symmetric(horizontal: 0, vertical: 2),
                      // padding: .zero,
                      itemCount: talker.history.length,
                      itemBuilder: (context, index) =>
                          _diagnosticLogMsgTile(context, index),
                    ),
                  ),
                  Divider(),
                  Row(
                    children: [
                      Text(
                        "${S.of(context).system}: ${S.of(context).online}",
                        style: context.textTheme.labelMedium,
                      ),
                      Spacer(),
                      Text(
                        "${S.of(context).bufferCapacity}: ${talker.history.length}/${talker.settings.maxHistoryItems} ${S.of(context).entries}",
                        style: context.textTheme.labelMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _diagnosticLogMsgTile(BuildContext context, int index) {
  TalkerData data = _getDiagnosticMessage()[index];

  return Card(
    child: ListTile(
      dense: true,
      titleTextStyle: context.textTheme.bodySmall,
      title: Row(
        spacing: 8,
        children: [
          Text(data.displayTime()),
          Container(
            padding: .symmetric(horizontal: 2, vertical: 1),
            decoration: BoxDecoration(
              border: Border.all(
                color: context.colorScheme.surface, //TODO: surface/onSurface ??
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              data.logLevel!.name.toUpperCase(),
              style: context.textTheme.bodySmall?.copyWith(
                color: data.getFlutterColor(TalkerScreenTheme()),
                fontWeight: .bold,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(data.displayMessage, style: context.textTheme.bodyMedium),
    ),
  );
}

List<TalkerData> _getDiagnosticMessage({String? level, String? category}) {
  return talker.history.reversed
      .where((t) {
        var cond = true;
        if (level != null) {
          cond = cond && (t.logLevel.toString() == level);
        }
        if (category != null) {
          cond = cond && (t.title.toString() == category);
        }
        return cond;
      })
      .toList(growable: false);
}

void _onClose(BuildContext context) {
  Navigator.of(context).pop();
}

enum _DropdownType { LEVEL, CATEGORY }

DropdownMenu<String> _getDropdown(
  BuildContext context,
  _DropdownType type,
  List<String> menus,
) {
  final menuEntries = menus
      .map(
        (value) => DropdownMenuEntry(
          value: value,
          label: value.toUpperCase(),
          style: ButtonStyle(
            textStyle: WidgetStatePropertyAll(context.textTheme.bodySmall),
          ),
        ),
      )
      .toList();
  return DropdownMenu(
    initialSelection: menus.firstOrNull,
    textStyle: context.textTheme.bodySmall,
    label: Text(type.name, style: context.textTheme.bodySmall),
    dropdownMenuEntries: menuEntries,
    menuStyle: MenuStyle(padding: WidgetStateProperty.all(EdgeInsets.zero)),
    inputDecorationTheme: const InputDecorationTheme(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      constraints: BoxConstraints(maxHeight: 36),
    ),
  );
}
