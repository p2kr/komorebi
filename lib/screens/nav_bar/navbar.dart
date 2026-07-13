import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/screens/browser_mode/browser.dart';
import 'package:komorebi/screens/crawlers/parser_sources.dart';
import 'package:komorebi/screens/crawlers/selected_sandbox.dart';
import 'package:komorebi/screens/crawlers/smart_matcher/smart_matcher.dart';
import 'package:komorebi/screens/dashboard/dashboard.dart';
import 'package:komorebi/screens/discover/discover.dart';
import 'package:komorebi/screens/local_collection/collections.dart';
import 'package:komorebi/screens/nav_bar/lang_switcher.dart';
import 'package:komorebi/screens/nav_bar/settings_button.dart';
import 'package:komorebi/screens/nav_bar/theme_switcher.dart';
import 'package:komorebi/themes/theme.dart';
import 'package:komorebi/utils/talker.dart';

// ── Main Navigation Bar Widget ───────────────────────────────────────────────

class NavBar extends HookConsumerWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeScreen = useState(NavItem.dashboard);

    final menuTree = useMemoized(
      () => NavItem.roots
          .map((item) => _buildMenuItem(context, item, activeScreen))
          .toList(),
      [
        Localizations.localeOf(context),
        activeScreen.value,
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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    ThemeSwitcher(),
                    SettingsButton(),
                    LangSwitcher(),
                  ],
                ),
              ),
            ],
          ),
        ),

        // IndexedStack keeps every screen alive — state is never lost on switch.
        Expanded(
          child: IndexedStack(
            index: NavItem.screens.indexOf(activeScreen.value),
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
  collections(Icons.collections_bookmark_outlined, Collections()),
  browser(Icons.explore_outlined, Browser());

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
  ValueNotifier<NavItem> activeScreen,
) {
  if (item.children.isNotEmpty) {
    return ExpansionTile(
      leading: Icon(item.icon),
      title: Text(item.title(context)),
      childrenPadding: const EdgeInsets.only(left: 16.0),
      children: item.children
          .map((child) => _buildMenuItem(context, child, activeScreen))
          .toList(),
    );
  }

  final isSelected = item == activeScreen.value;
  return ListTile(
    leading: Icon(item.icon),
    title: Text(item.title(context)),
    selected: isSelected,
    selectedTileColor: context.colorScheme.secondaryContainer,
    titleTextStyle: isSelected
        ? context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : null,
    onTap: () {
      activeScreen.value = item;
      talker.debug('Nav → $item');
    },
  );
}
