import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'breakpoints.dart';

class AdaptiveDestination {
  const AdaptiveDestination({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

class AppAdaptiveScaffold extends StatelessWidget {
  const AppAdaptiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
    required this.body,
  });

  final int selectedIndex;
  final List<AdaptiveDestination> destinations;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final windowClass = AppBreakpoints.fromWidth(MediaQuery.sizeOf(context).width);

    if (windowClass == WindowClass.compact) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: [
            for (final destination in destinations)
              NavigationDestination(
                icon: Icon(destination.icon),
                label: destination.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final destination in destinations)
                NavigationRailDestination(
                  icon: Icon(destination.icon),
                  label: Text(destination.label),
                ),
            ],
          ),
          VerticalDivider(
            width: 1,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.lineDark
                : AppColors.lineLight,
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
