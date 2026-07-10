import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/screens/browser_mode/browser.dart';
import 'package:komorebi/screens/crawlers/parser_sources.dart';
import 'package:komorebi/screens/crawlers/selected_sandbox.dart';
import 'package:komorebi/screens/crawlers/smart_matcher.dart';
import 'package:komorebi/screens/local_collection/collections.dart';
import 'package:komorebi/screens/dashboard/dashboard.dart';
import 'package:komorebi/screens/nav_bar/lang_switcher.dart';
import 'package:komorebi/screens/nav_bar/theme_switcher.dart';
import 'package:komorebi/themes/theme.dart';
import 'package:komorebi/utils/talker.dart';

typedef _Node = TreeNode<MenuItem>;

// ── Main Navigation Bar Widget ───────────────────────────────────────────────

class NavBar extends HookConsumerWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeScreen = useState(NavScreen.dashboard);
    final oldTreeRef = useRef<_Node?>(null);

    // Rebuild tree only when locale changes.
    final tree = useMemoized(() {
      final newTree = _buildTree(context, oldTreeRef.value);
      oldTreeRef.value = newTree;
      return newTree;
    }, [Localizations.localeOf(context)]);

    return Row(
      children: [
        Drawer(
          width: 200,
          child: Column(
            children: [
              Expanded(
                child: TreeView.simpleTyped<MenuItem, _Node>(
                  showRootNode: false,
                  tree: tree,
                  builder: (context, node) {
                    final item = node.data!;

                    final isSelected =
                        item.screen != null &&
                        item.screen == activeScreen.value;

                    return ListTile(
                      leading: Icon(item.icon),
                      title: Text(item.title),
                      selected: isSelected,
                      titleTextStyle: isSelected
                          ? context.textTheme.titleMedium?.copyWith(
                              fontWeight: .bold,
                            )
                          : null,
                      // selectedTileColor: Colors.blue,// todo: not working
                    );
                  },
                  onItemTap: (node) {
                    final screen = node.data!.screen;
                    if (screen == null) return; // expand-only parent
                    activeScreen.value = screen;
                    talker.debug('Nav → $screen');
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [ThemeSwitcher(), LangSwitcher()],
                ),
              ),
            ],
          ),
        ),

        // IndexedStack keeps every screen alive — state is never lost on switch.
        Expanded(
          child: IndexedStack(
            index: activeScreen.value.index,
            children: [for (final screen in NavScreen.values) screen.widget],
          ),
        ),
      ],
    );
  }
}

// ── Screen registry ──────────────────────────────────────────────────────────
// Declaration order == IndexedStack index (via .index). Add new screens here.

enum NavScreen {
  dashboard(Dashboard()),
  smartMatcher(SmartMatcherScreen()),
  parserSources(ParserSourcesScreen()),
  selectedSandbox(SelectedSandboxScreen()),
  collections(Collections()),
  browser(Browser());

  const NavScreen(this.widget);
  final Widget widget;
}

// ── Menu Data Model ──────────────────────────────────────────────────────────

class MenuItem {
  const MenuItem({
    required this.title,
    required this.icon,
    this.screen, // null = expand-only parent node
    this.children = const [],
  });

  final String title;
  final IconData icon;
  final NavScreen? screen;
  final List<MenuItem> children;
}

// ── Helper functions ─────────────────────────────────────────────────────────

_Node _buildTree(BuildContext context, _Node? oldRoot) {
  final root = _Node.root();
  final menuItems = _buildMenuItems(context);
  final stack = <(MenuItem, _Node)>[
    for (final item in menuItems.reversed) (item, root),
  ];

  while (stack.isNotEmpty) {
    final (item, parent) = stack.removeLast();

    // Use the icon's codePoint as the key to ensure uniqueness
    // when language changes or widget rebuilds
    final node = _Node(key: item.icon.codePoint.toString(), data: item);

    parent.add(node);
    for (final child in item.children.reversed) {
      stack.add((child, node));
    }
  }

  if (oldRoot != null) {
    _restoreExpansionState(oldRoot, root);
  }

  return root;
}

void _restoreExpansionState(_Node oldNode, _Node newNode) {
  newNode.expansionNotifier.value = oldNode.expansionNotifier.value;
  for (final newChild in newNode.childrenAsList) {
    for (final oldChild in oldNode.childrenAsList) {
      if (oldChild.key == newChild.key) {
        _restoreExpansionState(oldChild as _Node, newChild as _Node);
        break;
      }
    }
  }
}

List<MenuItem> _buildMenuItems(BuildContext context) {
  final s = S.of(context);
  return [
    MenuItem(
      title: s.dashboard,
      icon: Icons.space_dashboard_outlined,
      screen: NavScreen.dashboard,
    ),
    MenuItem(
      title: s.crawlers,
      icon: Icons.smart_toy_outlined,
      children: [
        MenuItem(
          title: s.smartMatcher,
          icon: Icons.auto_awesome_outlined,
          screen: NavScreen.smartMatcher,
        ),
        MenuItem(
          title: s.parserSources,
          icon: Icons.code_outlined,
          screen: NavScreen.parserSources,
        ),
        MenuItem(
          title: s.selectedSandbox,
          icon: Icons.science_outlined,
          screen: NavScreen.selectedSandbox,
        ),
      ],
    ),
    MenuItem(
      title: s.collections,
      icon: Icons.collections_bookmark_outlined,
      screen: NavScreen.collections,
    ),
    MenuItem(
      title: s.browser,
      icon: Icons.explore_outlined,
      screen: NavScreen.browser,
    ),
  ];
}
