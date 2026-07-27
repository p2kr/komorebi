import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/src/providers/common_providers.dart';
import 'package:komorebi/src/features/browser_mode/browser.dart';
import 'package:komorebi/src/features/crawlers/parser_sources.dart';
import 'package:komorebi/src/features/crawlers/selected_sandbox.dart';
import 'package:komorebi/src/features/crawlers/smart_matcher/smart_matcher.dart';
import 'package:komorebi/src/features/dashboard/dashboard.dart';
import 'package:komorebi/src/features/discover/discover.dart';
import 'package:komorebi/src/features/local_collection/local_collection.dart';
import 'package:komorebi/src/features/settings/settings_screen.dart';
import 'package:komorebi/src/core/themes/theme.dart';

// ── Main Navigation Bar Widget ───────────────────────────────────────────────

class NavBar extends HookConsumerWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeScreen = ref.watch(activeScreenProvider);

    final menuTree = useMemoized(
      () => NavItem.roots
          .map((item) => _buildMenuItem(context, item, activeScreen, ref))
          .toList(),
      [
        Localizations.localeOf(context),
        activeScreen,
        // will change on dark/light switch
        context.colorScheme.secondaryContainer,
      ],
      // [context],
    );

    return Row(
      children: [
        Drawer(
          width: 200, // TODO: Needs tweaking.
          child: Column(
            children: [
              Expanded(child: ListView(children: menuTree)),
              _buildMenuItem(context, NavItem.settings, activeScreen, ref),
            ],
          ),
        ),

        // IndexedStack keeps every screen alive — state is never lost on switch.
        Expanded(
          child: IndexedStack(
            index: NavItem.screens.indexOf(activeScreen),
            children: [for (final screen in NavItem.screens) screen.widget!],
          ),
        ),
      ],
    );
  }
}

// ── Menu Data Model ──────────────────────────────────────────────────────────

enum NavItem {
  dashboard(Icons.space_dashboard_outlined, Dashboard()),
  discover(Icons.whatshot_rounded, Discover()),
  crawlers(Icons.smart_toy_outlined, null),
  smartMatcher(Icons.auto_awesome_outlined, SmartMatcherScreen()),
  parserSources(Icons.code_outlined, ParserSourcesScreen()),
  selectedSandbox(Icons.science_outlined, SelectedSandboxScreen()),
  collections(Icons.collections_bookmark_outlined, LocalCollection()),
  browser(Icons.explore_outlined, Browser()),
  settings(Icons.settings_outlined, SettingsScreen());

  const NavItem(this.icon, this.widget);

  final IconData icon;
  final Widget? widget;

  String title(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      NavItem.dashboard => s.dashboard,
      NavItem.discover => s.discover,
      NavItem.crawlers => s.crawlers,
      NavItem.smartMatcher => s.smartMatcher,
      NavItem.parserSources => s.parserSources,
      NavItem.selectedSandbox => s.selectedSandbox,
      NavItem.collections => s.collections,
      NavItem.browser => s.browser,
      NavItem.settings => s.settings,
    };
  }

  List<NavItem> get children {
    return switch (this) {
      NavItem.crawlers => [smartMatcher, parserSources, selectedSandbox],
      _ => const [],
    };
  }

  static const roots = [dashboard, discover, crawlers, collections, browser];

  static final screens = NavItem.values.where((e) => e.widget != null).toList();
}

Widget _buildMenuItem(
  BuildContext context,
  NavItem item,
  NavItem activeScreen,
  WidgetRef ref,
) {
  if (item.children.isNotEmpty) {
    return ExpansionTile(
      leading: Icon(item.icon),
      title: Text(item.title(context)),
      childrenPadding: const EdgeInsets.only(left: 16.0),
      children: item.children
          .map((child) => _buildMenuItem(context, child, activeScreen, ref))
          .toList(),
    );
  }

  final isSelected = item == activeScreen;
  return ListTile(
    leading: Icon(item.icon),
    title: Text(item.title(context)),
    selected: isSelected,
    selectedTileColor: context.colorScheme.secondaryContainer,
    titleTextStyle: isSelected
        ? context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : null,
    onTap: () {
      ref.read(activeScreenProvider.notifier).switchScreen(item);
    },
  );
}
