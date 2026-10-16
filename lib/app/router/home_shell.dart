import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';
import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/core/ui/car_ui.dart';
import 'package:carwidget/features/catalog/presentation/pages/widgets_page.dart';
import 'package:carwidget/features/startup_sounds/presentation/pages/sounds_page.dart';
import 'package:carwidget/features/cards/presentation/pages/my_car_page.dart';
import 'package:carwidget/features/settings/presentation/pages/settings_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final PageController _pageController = PageController();
  int tab = 0;
  bool _settingsRouteOpen = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (index == tab) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _openSettings() async {
    if (_settingsRouteOpen) return;
    _settingsRouteOpen = true;
    try {
      await Navigator.of(context).push<void>(
        _SettingsRoute(
          reduceMotion: MediaQuery.disableAnimationsOf(context),
          builder: (context) => Scaffold(
            body: SafeArea(
              child: SettingsPage(onBack: () => Navigator.of(context).pop()),
            ),
          ),
        ),
      );
    } finally {
      _settingsRouteOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 16, 8),
            child: Row(
              children: [
                if (tab == 0) const Brand(),
                const Spacer(),
                IconButton(
                  tooltip: 'Settings',
                  onPressed: _openSettings,
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => tab = index),
              children: const [
                _KeepAlivePage(child: WidgetsPage()),
                _KeepAlivePage(child: SoundsPage()),
                _KeepAlivePage(child: MyCarPage()),
              ],
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: _BottomTaskbar(
      selectedIndex: tab,
      onDestinationSelected: _selectTab,
    ),
  );
}

class _SettingsRoute extends CupertinoPageRoute<void> {
  _SettingsRoute({required super.builder, required this.reduceMotion});

  final bool reduceMotion;

  @override
  Duration get transitionDuration =>
      reduceMotion ? Duration.zero : const Duration(milliseconds: 650);

  @override
  Duration get reverseTransitionDuration => transitionDuration;
}

class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin<_KeepAlivePage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _BottomTaskbar extends StatelessWidget {
  const _BottomTaskbar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF20282E), Color(0xFF171D22)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 5, 18, 4),
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                Expanded(
                  child: _TaskbarDestination(
                    icon: Icons.widgets_outlined,
                    selectedIcon: Icons.widgets_rounded,
                    label: 'Widget',
                    isSelected: selectedIndex == 0,
                    onTap: () => onDestinationSelected(0),
                  ),
                ),
                Expanded(
                  child: _TaskbarDestination(
                    icon: Icons.music_note_outlined,
                    selectedIcon: Icons.music_note_rounded,
                    label: 'Sound',
                    isSelected: selectedIndex == 1,
                    onTap: () => onDestinationSelected(1),
                  ),
                ),
                Expanded(
                  child: _TaskbarDestination(
                    icon: Icons.directions_car_outlined,
                    selectedIcon: Icons.directions_car_filled_rounded,
                    label: 'My Car',
                    isSelected: selectedIndex == 2,
                    onTap: () => onDestinationSelected(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _TaskbarDestination extends StatelessWidget {
  const _TaskbarDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 46,
              height: 32,
              child: Icon(
                isSelected ? selectedIcon : icon,
                size: 22,
                color: isSelected
                    ? AppColors.green
                    : Colors.white.withValues(alpha: .78),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .78),
                fontSize: 12,
                height: 1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
