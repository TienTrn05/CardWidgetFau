import 'dart:async';
import 'dart:math' as math;

import 'package:carwidget/features/cards/presentation/pages/driving_contacts_page.dart';
import 'package:carwidget/features/cards/presentation/widgets/driving_map_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DrivingModePage extends StatefulWidget {
  const DrivingModePage({super.key});

  @override
  State<DrivingModePage> createState() => _DrivingModePageState();
}

class _DrivingModePageState extends State<DrivingModePage> {
  static const _drivingAppsChannel = MethodChannel('carwidget/driving_apps');

  final _dashboardController = ScrollController();
  final _musicKey = GlobalKey();
  final _mapKey = GlobalKey();
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  bool _mapExpanded = false;
  bool _appsOpen = false;
  bool _contactsOpen = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _dashboardController.dispose();
    super.dispose();
  }

  void _showMusic() {
    setState(() {
      _appsOpen = false;
      _contactsOpen = false;
      _mapExpanded = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final musicContext = _musicKey.currentContext;
      if (musicContext == null) return;
      Scrollable.ensureVisible(
        musicContext,
        alignment: .5,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _showDashboard() {
    setState(() {
      _appsOpen = false;
      _contactsOpen = false;
      _mapExpanded = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_dashboardController.hasClients) return;
      _dashboardController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _openDrivingApp(_DrivingApp app) async {
    if (app == _DrivingApp.contacts) {
      _showContacts();
      return;
    }

    try {
      await _drivingAppsChannel.invokeMethod<void>('open', app.name);
    } on PlatformException catch (error) {
      if (!mounted) return;
      final message = error.code == 'app_unavailable'
          ? '${app.label} is not available on this iPhone.'
          : 'Could not open ${app.label}.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Opening iPhone apps is only available on iOS.'),
          ),
        );
    }
  }

  void _showContacts() {
    setState(() {
      _contactsOpen = true;
      _appsOpen = false;
      _mapExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      backgroundColor: const Color(0xFF09182D),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF08132B), Color(0xFF08464C), Color(0xFF082B42)],
            stops: [0, .62, 1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final gap = (width * .044).clamp(12.0, 20.0);
                    final iconSize = (width / 5.1).clamp(52.0, 76.0);
                    final textScale = math.max(
                      1.0,
                      MediaQuery.textScalerOf(context).scale(16) / 16,
                    );
                    final musicHeight =
                        (width * .378).clamp(128.0, 208.0) * textScale;
                    final infoHeight =
                        (width * .44).clamp(152.0, 240.0) * textScale;
                    final minMapHeight = (width * .66).clamp(200.0, 350.0);

                    return Column(
                      children: [
                        SizedBox(
                          height: 44,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              tooltip: _contactsOpen
                                  ? 'Close Contacts'
                                  : _mapExpanded
                                  ? 'Close map'
                                  : 'Close Driving Mode',
                              onPressed: () {
                                if (_contactsOpen) {
                                  setState(() => _contactsOpen = false);
                                } else if (_mapExpanded) {
                                  setState(() => _mapExpanded = false);
                                } else {
                                  Navigator.of(context).maybePop();
                                }
                              },
                              icon: const Icon(
                                CupertinoIcons.xmark,
                                color: Colors.white,
                                size: 23,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        SizedBox(height: _appsOpen ? 0 : 8),
                        Expanded(
                          child: _contactsOpen
                              ? const DrivingContactsPage()
                              : _appsOpen
                              ? _AppsPanel(onAppTap: _openDrivingApp)
                              : _mapExpanded
                              ? DrivingMapView(
                                  key: _mapKey,
                                  expanded: true,
                                  onToggleExpanded: () =>
                                      setState(() => _mapExpanded = false),
                                )
                              : LayoutBuilder(
                                  builder: (context, contentConstraints) {
                                    final minHeight =
                                        minMapHeight +
                                        musicHeight +
                                        infoHeight +
                                        gap * 2;
                                    return SingleChildScrollView(
                                      controller: _dashboardController,
                                      child: SizedBox(
                                        height: math.max(
                                          contentConstraints.maxHeight,
                                          minHeight,
                                        ),
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: DrivingMapView(
                                                key: _mapKey,
                                                expanded: false,
                                                onToggleExpanded: () =>
                                                    setState(
                                                      () => _mapExpanded = true,
                                                    ),
                                              ),
                                            ),
                                            SizedBox(height: gap),
                                            SizedBox(
                                              key: _musicKey,
                                              height: musicHeight,
                                              child: _MusicPanel(
                                                isPlaying: _isPlaying,
                                                onTogglePlayback: () =>
                                                    setState(
                                                      () => _isPlaying =
                                                          !_isPlaying,
                                                    ),
                                              ),
                                            ),
                                            SizedBox(height: gap),
                                            SizedBox(
                                              height: infoHeight,
                                              child: _InfoPanels(
                                                now: _now,
                                                gap: gap,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        SizedBox(height: _appsOpen ? 16 : 8),
                        _DrivingDock(
                          appsOpen: _appsOpen,
                          iconSize: iconSize,
                          onMapTap: _showDashboard,
                          onMusicTap: _showMusic,
                          onPhoneTap: _showContacts,
                          onAppsTap: () => setState(() {
                            _mapExpanded = false;
                            _contactsOpen = false;
                            _appsOpen = !_appsOpen;
                          }),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _MusicPanel extends StatelessWidget {
  const _MusicPanel({required this.isPlaying, required this.onTogglePlayback});

  final bool isPlaying;
  final VoidCallback onTogglePlayback;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('driving-music'),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xD907303B),
      borderRadius: BorderRadius.circular(22),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final artworkSize = math.min(
          constraints.maxHeight,
          constraints.maxWidth * .3,
        );
        return Row(
          children: [
            Container(
              width: artworkSize,
              height: artworkSize,
              decoration: BoxDecoration(
                color: const Color(0xFF34515F),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                CupertinoIcons.music_note,
                color: Colors.white,
                size: artworkSize * .46,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isPlaying ? 'Playing' : 'Not Playing',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'The Artist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF90A4AD),
                      fontSize: 15,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _PlaybackButton(
                        tooltip: 'Previous track',
                        icon: CupertinoIcons.backward_fill,
                        onPressed: () {},
                      ),
                      _PlaybackButton(
                        tooltip: isPlaying ? 'Pause' : 'Play',
                        icon: isPlaying
                            ? CupertinoIcons.pause_fill
                            : CupertinoIcons.play_fill,
                        onPressed: onTogglePlayback,
                        size: 30,
                      ),
                      _PlaybackButton(
                        tooltip: 'Next track',
                        icon: CupertinoIcons.forward_fill,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _PlaybackButton extends StatelessWidget {
  const _PlaybackButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.size = 25,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 44,
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      icon: Icon(icon, color: Colors.white, size: size),
    ),
  );
}

class _InfoPanels extends StatelessWidget {
  const _InfoPanels({required this.now, required this.gap});

  final DateTime now;
  final double gap;

  @override
  Widget build(BuildContext context) => Row(
    key: const ValueKey('driving-info'),
    children: [
      const Expanded(child: _InfoCard(child: _WeatherPanel())),
      SizedBox(width: gap),
      Expanded(
        child: _InfoCard(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${_weekday(now.weekday)}, ${now.day} ${_month(now.month)}',
                  style: const TextStyle(
                    color: Color(0xFF90A4AD),
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  static String _weekday(int day) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1];

  static String _month(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}

class _WeatherPanel extends StatelessWidget {
  const _WeatherPanel();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '82°F',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            _PartlyCloudyIcon(
              size: (constraints.maxWidth * .4).clamp(42.0, 68.0),
            ),
          ],
        ),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    'P. Hai Van',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  CupertinoIcons.location_fill,
                  color: Colors.white,
                  size: 10,
                ),
              ],
            ),
            SizedBox(height: 2),
            Text(
              '68°/82°',
              style: TextStyle(color: Color(0xFF90A4AD), fontSize: 14),
            ),
          ],
        ),
        const Row(
          children: [
            Icon(CupertinoIcons.cloud, color: Colors.white, size: 17),
            SizedBox(width: 4),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Weather',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PartlyCloudyIcon extends StatelessWidget {
  const _PartlyCloudyIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Stack(
      children: [
        Positioned(
          top: 0,
          right: 0,
          child: Icon(
            Icons.wb_sunny_rounded,
            color: const Color(0xFFFFCF00),
            size: size * .83,
          ),
        ),
        Positioned(
          left: 0,
          bottom: 0,
          child: Icon(
            Icons.cloud_rounded,
            color: Colors.white,
            size: size * .82,
          ),
        ),
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xC907303B),
      borderRadius: BorderRadius.circular(22),
    ),
    child: child,
  );
}

class _DrivingDock extends StatelessWidget {
  const _DrivingDock({
    required this.appsOpen,
    required this.iconSize,
    required this.onMapTap,
    required this.onMusicTap,
    required this.onPhoneTap,
    required this.onAppsTap,
  });

  final bool appsOpen;
  final double iconSize;
  final VoidCallback onMapTap;
  final VoidCallback onMusicTap;
  final VoidCallback onPhoneTap;
  final VoidCallback onAppsTap;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('driving-dock'),
    height: iconSize + 10,
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: const Color(0xD9082638),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        Expanded(
          child: _DockImageButton(
            asset: 'assets/images/map.png',
            tooltip: 'Maps',
            size: iconSize,
            imageScale: 1.11,
            onPressed: onMapTap,
          ),
        ),
        Expanded(
          child: _DockImageButton(
            asset: 'assets/images/music.png',
            tooltip: 'Music',
            size: iconSize,
            imageScale: 1.13,
            onPressed: onMusicTap,
          ),
        ),
        Expanded(
          child: _DockImageButton(
            asset: 'assets/images/phone.png',
            tooltip: 'Phone',
            size: iconSize,
            imageScale: 1.03,
            onPressed: onPhoneTap,
          ),
        ),
        Expanded(
          child: Center(
            child: SizedBox.square(
              dimension: iconSize * .9,
              child: Material(
                color: const Color(0xFF34515F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(iconSize * .9 * .23),
                  side: appsOpen
                      ? const BorderSide(color: Colors.white, width: 1.5)
                      : BorderSide.none,
                ),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  tooltip: appsOpen ? 'Close apps' : 'Apps',
                  onPressed: onAppsTap,
                  padding: EdgeInsets.zero,
                  icon: _AppsGridIcon(size: iconSize * .9 * .5),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _AppsGridIcon extends StatelessWidget {
  const _AppsGridIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size * .625,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        2,
        (_) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            3,
            (_) => Container(
              width: size * .25,
              height: size * .25,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(size * .04),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _AppsPanel extends StatelessWidget {
  const _AppsPanel({required this.onAppTap});

  final ValueChanged<_DrivingApp> onAppTap;

  static const _apps = [
    _DrivingApp.calendar,
    _DrivingApp.maps,
    _DrivingApp.findMy,
    _DrivingApp.contacts,
    _DrivingApp.messages,
    _DrivingApp.music,
    _DrivingApp.weather,
    _DrivingApp.settings,
  ];

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xD8071C2B),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: .035)),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final iconSize = (constraints.maxWidth * .245).clamp(64.0, 104.0);
        final labelGap = math.max(8.0, iconSize * .1);
        final labelFontSize = (constraints.maxWidth * .0445).clamp(14.0, 18.0);
        final labelHeight =
            (MediaQuery.textScalerOf(context).scale(labelFontSize) * 1.25)
                .ceilToDouble();
        final tileHeight = iconSize + labelGap + labelHeight;
        final rowCount = (_apps.length / 2).ceil();
        // The outer vertical spaces are three times the gaps between rows.
        final spaceCount = rowCount - 1 + 6;
        final contentHeight = math.max(
          constraints.maxHeight,
          tileHeight * rowCount + spaceCount * 8,
        );
        final rowGap = (contentHeight - tileHeight * rowCount) / spaceCount;

        return GridView.builder(
          primary: false,
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth * .12,
            vertical: rowGap * 3,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 0,
            mainAxisSpacing: rowGap,
            mainAxisExtent: tileHeight,
          ),
          itemCount: _apps.length,
          itemBuilder: (context, index) => _AppGridTile(
            app: _apps[index],
            iconSize: iconSize,
            labelGap: labelGap,
            labelFontSize: labelFontSize,
            onTap: () => onAppTap(_apps[index]),
          ),
        );
      },
    ),
  );
}

enum _DrivingApp {
  calendar,
  maps,
  findMy,
  contacts,
  messages,
  music,
  weather,
  settings,
}

extension on _DrivingApp {
  String get label => switch (this) {
    _DrivingApp.calendar => 'Calendar',
    _DrivingApp.maps => 'Maps',
    _DrivingApp.findMy => 'Find My',
    _DrivingApp.contacts => 'Contacts',
    _DrivingApp.messages => 'Messages',
    _DrivingApp.music => 'Music',
    _DrivingApp.weather => 'Weather',
    _DrivingApp.settings => 'Settings',
  };
}

class _AppGridTile extends StatelessWidget {
  const _AppGridTile({
    required this.app,
    required this.iconSize,
    required this.labelGap,
    required this.labelFontSize,
    required this.onTap,
  });

  final _DrivingApp app;
  final double iconSize;
  final double labelGap;
  final double labelFontSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    enabled: onTap != null,
    label: app.label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: iconSize,
            child: FittedBox(
              child: SizedBox.square(dimension: 64, child: _AppIcon(app: app)),
            ),
          ),
          SizedBox(height: labelGap),
          Text(
            app.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: labelFontSize,
              height: 1.25,
            ),
          ),
        ],
      ),
    ),
  );
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.app});

  final _DrivingApp app;

  @override
  Widget build(BuildContext context) {
    switch (app) {
      case _DrivingApp.maps:
        return _assetIcon('assets/images/map.png', 1.23);
      case _DrivingApp.music:
        return _assetIcon('assets/images/music.png', 1.25);
      case _DrivingApp.calendar:
        return _assetIcon('assets/images/cadidate.png', 1.30);
      case _DrivingApp.findMy:
        return _assetIcon('assets/images/fing.png', 1.19);
      case _DrivingApp.contacts:
        return _assetIcon('assets/images/contact.png', 1.24);
      case _DrivingApp.messages:
        return _assetIcon('assets/images/chat.png', 1.26);
      case _DrivingApp.weather:
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2387E9), Color(0xFF4FC5F1)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(child: _PartlyCloudyIcon(size: 49)),
        );
      case _DrivingApp.settings:
        return _assetIcon('assets/images/setting.png', 1.20);
    }
  }

  Widget _assetIcon(String asset, double scale) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: Transform.scale(
      scale: scale,
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      ),
    ),
  );
}

class _DockImageButton extends StatelessWidget {
  const _DockImageButton({
    required this.asset,
    required this.tooltip,
    required this.size,
    required this.imageScale,
    required this.onPressed,
  });

  final String asset;
  final String tooltip;
  final double size;
  // Compensates for transparent padding in the source image.
  final double imageScale;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox.square(
      dimension: size,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: ClipRRect(
          borderRadius: BorderRadius.circular(size * .23),
          child: Transform.scale(
            scale: imageScale,
            child: Image.asset(
              asset,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    ),
  );
}
