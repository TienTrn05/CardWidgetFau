import 'package:flutter/material.dart';
import 'package:carwidget/core/ui/car_ui.dart';
import 'package:carwidget/features/catalog/presentation/pages/widgets_page.dart';
import 'package:carwidget/features/startup_sounds/presentation/pages/sounds_page.dart';
import 'package:carwidget/features/cards/presentation/pages/cards_page.dart';
import 'package:carwidget/features/settings/presentation/pages/settings_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;
  bool settings = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 16, 8),
            child: Row(
              children: [
                const Brand(),
                const Spacer(),
                IconButton(
                  tooltip: settings ? 'Close settings' : 'Settings',
                  onPressed: () => setState(() => settings = !settings),
                  icon: Icon(
                    settings ? Icons.close_rounded : Icons.settings_outlined,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: settings ? 3 : tab,
              children: const [
                WidgetsPage(),
                SoundsPage(),
                CardsPage(),
                SettingsPage(),
              ],
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: settings
        ? null
        : NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (index) => setState(() => tab = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.widgets_outlined),
                selectedIcon: Icon(Icons.widgets_rounded),
                label: 'Widget',
              ),
              NavigationDestination(
                icon: Icon(Icons.music_note_outlined),
                selectedIcon: Icon(Icons.music_note_rounded),
                label: 'Sound',
              ),
              NavigationDestination(
                icon: Icon(Icons.style_outlined),
                selectedIcon: Icon(Icons.style_rounded),
                label: 'Card',
              ),
            ],
          ),
  );
}
