import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

class ResponsiveScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  const ResponsiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < DesignTokens.breakpointCompact) {
      // Phone layout with modern Material 3 NavigationBar
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onDestinationSelected,
          elevation: 2,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'Schedule',
            ),
            NavigationDestination(
              icon: Icon(Icons.volunteer_activism_outlined),
              selectedIcon: Icon(Icons.volunteer_activism),
              label: 'Solicitations',
            ),
            NavigationDestination(
              icon: Icon(Icons.share_outlined),
              selectedIcon: Icon(Icons.share),
              label: 'Share',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      );
    } else if (width < DesignTokens.breakpointMedium) {
      // Tablet layout with NavigationRail
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.calendar_today_outlined),
                  selectedIcon: Icon(Icons.calendar_today),
                  label: Text('Schedule'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.volunteer_activism_outlined),
                  selectedIcon: Icon(Icons.volunteer_activism),
                  label: Text('Solicitations'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.share_outlined),
                  selectedIcon: Icon(Icons.share),
                  label: Text('Share'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: body),
          ],
        ),
      );
    } else {
      // Desktop / Expanded layout with persistent Sidebar
      return Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: 240,
              child: Drawer(
                elevation: 0,
                child: ListView(
                  children: [
                    DrawerHeader(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.eco, size: 36, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: DesignTokens.spaceSm),
                          const Text(
                            'SchedSolicit',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Schedule'),
                      selected: currentIndex == 0,
                      onTap: () => onDestinationSelected(0),
                    ),
                    ListTile(
                      leading: const Icon(Icons.volunteer_activism),
                      title: const Text('Solicitations'),
                      selected: currentIndex == 1,
                      onTap: () => onDestinationSelected(1),
                    ),
                    ListTile(
                      leading: const Icon(Icons.share),
                      title: const Text('Share Links'),
                      selected: currentIndex == 2,
                      onTap: () => onDestinationSelected(2),
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Settings'),
                      selected: currentIndex == 3,
                      onTap: () => onDestinationSelected(3),
                    ),
                  ],
                ),
              ),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }
  }
}
