import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/themes/theme.dart';
import 'package:komorebi/utils/talker.dart';
import 'package:komorebi/widgets/chips.dart';
import 'package:talker/talker.dart';

class DiagnosticWindow extends HookWidget {
  const DiagnosticWindow({super.key});

  @override
  Widget build(BuildContext context) {
    final currLevelFilter = useState("all");
    final currCategoryFilter = useState("all");

    final diagnosticsList = useMemoized(
      () => getDiagnosticMessage(
        context,
        level: currLevelFilter.value,
        category: currCategoryFilter.value,
      ),
      [currLevelFilter.value, currCategoryFilter.value],
    );

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

                      // diagnostic window title
                      Text(
                        S.of(context).systemDiagnosticsLoggingVault,
                        style: context.textTheme.headlineSmall,
                      ),

                      Spacer(),

                      // close button
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
                      // LEVEL dropdown
                      _getDropdown(
                        context,
                        _DropdownType.LEVEL,
                        ["all", "info", "warning", "error"],
                        onSelected: (value) =>
                            currLevelFilter.value = value ?? "all",
                      ),

                      // CATEGORY dropdown
                      _getDropdown(
                        context,
                        _DropdownType.CATEGORY,
                        [
                          "all",
                          "system",
                          "riverpod",
                          "http",
                          // "web crawler",
                          // "mal sync",
                          // "file system",
                          // "queue engine",
                        ],
                        onSelected: (value) =>
                            currCategoryFilter.value = value ?? "all",
                      ),
                    ],
                  ),

                  Flexible(
                    child: diagnosticsList.isNotEmpty
                        // Logs screen
                        ? ListView.builder(
                            padding: .symmetric(horizontal: 0, vertical: 2),
                            itemCount: diagnosticsList.length,
                            itemBuilder: (context, index) =>
                                diagnosticsList[index],
                          )
                        // Empty list message
                        : Center(
                            child: Text(
                              S.of(context).noLogEntriesRecorded,
                              style: context.textTheme.bodyMedium?.copyWith(
                                fontStyle: .italic,
                              ),
                            ),
                          ),
                  ),
                  Divider(),

                  // Status bar
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

Widget _diagnosticLogMsgTile(
  BuildContext context,
  TalkerData data, {
  String? level,
  String? category,
}) {
  return Card(
    child: ExpansionTile(
      expandedAlignment: .topLeft,
      childrenPadding: .symmetric(horizontal: 16),
      dense: true,
      // titleTextStyle: context.textTheme.bodySmall,
      title: Row(
        spacing: 8,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              data.displayTime(),
              style: context.textTheme.labelSmall,
            ),
          ),

          // Log level
          SimpleChip(
            label: data.logLevel!.name.toUpperCase(),
            labelStyle: context.textTheme.labelSmall?.copyWith(
              color: data.getFlutterColor(),
              fontWeight: .bold,
            ),
          ),

          // category chip
          SimpleChip(label: getCategoryName(data)),
        ],
      ),
      subtitle: Text(
        data.displayMessage + data.displayError + data.displayException,
        style: context.textTheme.bodyMedium,
      ),
      enabled: data.logLevel?.name == 'error',
      showTrailingIcon: data.logLevel?.name == 'error',
      children: [
        Text(data.generateTextMessage(), style: context.textTheme.labelSmall),
      ],
    ),
  );
}

List<Widget> getDiagnosticMessage(
  BuildContext context, {
  String? level,
  String? category,
}) {
  return talker.history.reversed
      .where((t) {
        if (!kDebugMode && t.logLevel!.name == 'debug') {
          return false; // don't show debug logs
        }
        var cond = true;
        if (level != null && level != "all") {
          cond = cond && (t.logLevel!.name == level);
        }
        if (category != null && category != "all") {
          if (category != "system") {
            cond = cond && (t.title!.contains(category));
          } else {
            cond =
                cond &&
                (['info', 'debug', 'warning', 'error'].contains(t.title));
          }
        }
        return cond;
      })
      .map(
        (data) => _diagnosticLogMsgTile(
          context,
          data,
          level: level,
          category: category,
        ),
      )
      .toList(growable: false);
}

void _onClose(BuildContext context) {
  Navigator.of(context).pop();
}

enum _DropdownType { LEVEL, CATEGORY }

String _getDropdownLabel(BuildContext context, _DropdownType type) {
  switch (type) {
    case _DropdownType.LEVEL:
      return S.of(context).level;
    case _DropdownType.CATEGORY:
      return S.of(context).category;
  }
}

DropdownMenu<String> _getDropdown(
  BuildContext context,
  _DropdownType type,
  List<String> menus, {
  ValueChanged<String?>? onSelected,
}) {
  final menuEntries = menus
      .map(
        (value) => DropdownMenuEntry(
          value: value,
          label: value.toUpperCase(), // how to translate?
          style: ButtonStyle(
            textStyle: WidgetStatePropertyAll(context.textTheme.bodySmall),
          ),
        ),
      )
      .toList();
  return DropdownMenu(
    initialSelection: menus.firstOrNull,
    textStyle: context.textTheme.bodySmall,
    label: Text(
      _getDropdownLabel(context, type),
      style: context.textTheme.bodySmall,
    ),
    dropdownMenuEntries: menuEntries,
    menuStyle: MenuStyle(padding: WidgetStateProperty.all(EdgeInsets.zero)),
    inputDecorationTheme: const InputDecorationTheme(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      constraints: BoxConstraints(maxHeight: 36),
    ),
    selectOnly: true,
    onSelected: onSelected,
  );
}

String getCategoryName(TalkerData data) {
  if (data.logLevel!.name != data.title) {
    return data.title!.toUpperCase();
  } else {
    return "SYSTEM";
  }
}
