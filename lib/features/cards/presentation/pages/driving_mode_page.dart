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

class _DrivingModePageState extends State<DrivingModePage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const _drivingAppsChannel = MethodChannel('carwidget/driving_apps');
  static const _musicPlayerChannel = MethodChannel('carwidget/music_player_v1');

  final _dashboardController = ScrollController();
  final _musicKey = GlobalKey();
  final _mapKey = GlobalKey();
  late final AnimationController _contentTransitionController;
  late final Animation<double> _contentAnimation;
  double _contentDirection = 1;
  Timer? _clockTimer;
  Timer? _musicRefreshTimer;
  DateTime _now = DateTime.now();
  _NowPlayingInfo _nowPlaying = _NowPlayingInfo.empty;
  bool _mapExpanded = false;
  bool _appsOpen = false;
  bool _contactsOpen = false;
  bool _musicScreenOpen = false;
  bool _musicRequested = false;
  bool _mediaLibraryAuthorized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _contentTransitionController = AnimationController(
      vsync: this,
      value: 1,
      duration: const Duration(milliseconds: 650),
    );
    _contentAnimation = _contentTransitionController.drive(
      CurveTween(curve: Curves.easeOutCubic),
    );
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    _musicRefreshTimer?.cancel();
    _contentTransitionController.dispose();
    _dashboardController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _musicRequested) {
      _startMusicRefresh();
      _refreshMusicInfo();
      if (!_musicScreenOpen) _scrollToMusicCard();
    } else {
      _musicRefreshTimer?.cancel();
      _musicRefreshTimer = null;
    }
  }

  Future<void> _showMusic() async {
    final contentChanged =
        _appsOpen || _contactsOpen || _mapExpanded || _musicScreenOpen;
    setState(() {
      _appsOpen = false;
      _contactsOpen = false;
      _mapExpanded = false;
      _musicScreenOpen = false;
      _musicRequested = true;
    });
    if (contentChanged) _animateContent(returning: true);
    _startMusicRefresh();
    try {
      final result = await _musicPlayerChannel.invokeMapMethod<String, Object?>(
        'openAppleMusic',
      );
      if (result?['opened'] != true && mounted) {
        _showMusicMessage('Apple Music is not available on this iPhone.');
      }
    } on MissingPluginException {
      if (mounted) {
        _showMusicMessage('Apple Music controls are available on iPhone.');
      }
    } on PlatformException catch (error) {
      if (mounted) {
        _showMusicMessage(error.message ?? 'Could not open Apple Music.');
      }
    }
  }

  Future<void> _openSpotify() async {
    try {
      await _musicPlayerChannel.invokeMethod<bool>('openSpotify');
    } on PlatformException {
      // Spotify is optional; keep the source switch quiet if it cannot open.
    } on MissingPluginException {
      // Spotify can only be opened through the iOS native bridge.
    }
  }

  void _startMusicRefresh() {
    _musicRefreshTimer ??= Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refreshMusicInfo(),
    );
    _refreshMusicInfo();
  }

  Future<void> _refreshMusicInfo() async {
    try {
      final result = await _musicPlayerChannel.invokeMapMethod<String, Object?>(
        'getNowPlaying',
      );
      if (!mounted || result == null) return;
      setState(() {
        _mediaLibraryAuthorized = result['authorized'] as bool? ?? false;
        _nowPlaying = _NowPlayingInfo.fromMap(result);
        _isPlaying = _nowPlaying.isPlaying;
      });
    } on PlatformException {
      // Keep the last available playback state if the system player is busy.
    } on MissingPluginException {
      // The Apple Music player bridge only exists on iOS.
    }
  }

  Future<void> _controlMusic(String method, [double? position]) async {
    try {
      await _musicPlayerChannel.invokeMethod<void>(method, position);
      await _refreshMusicInfo();
    } on PlatformException catch (error) {
      if (mounted) {
        _showMusicMessage(error.message ?? 'Could not control playback.');
      }
    } on MissingPluginException {
      if (mounted) {
        _showMusicMessage('Apple Music controls are available on iPhone.');
      }
    }
  }

  void _showMusicMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _animateContent({bool returning = false}) {
    _contentDirection = returning ? -1 : 1;
    if (MediaQuery.disableAnimationsOf(context)) {
      _contentTransitionController.value = 1;
      return;
    }
    _contentTransitionController.forward(from: 0);
  }

  void _showDashboard() {
    final contentChanged =
        _appsOpen || _contactsOpen || _mapExpanded || _musicScreenOpen;
    setState(() {
      _appsOpen = false;
      _contactsOpen = false;
      _mapExpanded = false;
      _musicScreenOpen = false;
      _musicRequested = false;
    });
    if (contentChanged) _animateContent(returning: true);
    _musicRefreshTimer?.cancel();
    _musicRefreshTimer = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_dashboardController.hasClients) return;
      _dashboardController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _openNowPlayingScreen() {
    setState(() {
      _musicScreenOpen = true;
      _appsOpen = false;
      _contactsOpen = false;
      _mapExpanded = false;
    });
    _animateContent();
    if (_musicRequested) _startMusicRefresh();
  }

  void _closeNowPlayingScreen() {
    setState(() => _musicScreenOpen = false);
    _animateContent(returning: true);
    _scrollToMusicCard();
  }

  void _scrollToMusicCard() {
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

  Future<void> _openDrivingApp(_DrivingApp app) async {
    if (app == _DrivingApp.music) {
      await _showMusic();
      return;
    }
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
    final contentChanged = !_contactsOpen;
    setState(() {
      _contactsOpen = true;
      _appsOpen = false;
      _mapExpanded = false;
      _musicScreenOpen = false;
      _musicRequested = false;
    });
    if (contentChanged) _animateContent();
    _musicRefreshTimer?.cancel();
    _musicRefreshTimer = null;
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
                    final mapHeight = (width * .8).clamp(240.0, 420.0);

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
                                  _animateContent(returning: true);
                                } else if (_musicScreenOpen) {
                                  _closeNowPlayingScreen();
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
                          child: FadeTransition(
                            opacity: _contentAnimation,
                            child: SlideTransition(
                              position: _contentAnimation.drive(
                                Tween<Offset>(
                                  begin: Offset(.06 * _contentDirection, 0),
                                  end: Offset.zero,
                                ),
                              ),
                              child: _contactsOpen
                                  ? const DrivingContactsPage()
                                  : _appsOpen
                                  ? _AppsPanel(onAppTap: _openDrivingApp)
                                  : _musicScreenOpen
                                  ? _NowPlayingScreen(
                                      info: _nowPlaying,
                                      mediaLibraryAuthorized:
                                          _mediaLibraryAuthorized,
                                      onSpotifyTap: _openSpotify,
                                      onPrevious: _mediaLibraryAuthorized
                                          ? () => _controlMusic('previous')
                                          : null,
                                      onTogglePlayback: _mediaLibraryAuthorized
                                          ? () => _controlMusic(
                                              _isPlaying ? 'pause' : 'play',
                                            )
                                          : null,
                                      onNext: _mediaLibraryAuthorized
                                          ? () => _controlMusic('next')
                                          : null,
                                      onSeek: (position) =>
                                          _controlMusic('seek', position),
                                    )
                                  : _mapExpanded
                                  ? DrivingMapView(
                                      key: _mapKey,
                                      expanded: true,
                                      onToggleExpanded: () =>
                                          setState(() => _mapExpanded = false),
                                    )
                                  : ListView(
                                      key: const ValueKey(
                                        'driving-dashboard-list',
                                      ),
                                      controller: _dashboardController,
                                      physics: const BouncingScrollPhysics(
                                        parent: AlwaysScrollableScrollPhysics(),
                                      ),
                                      padding: EdgeInsets.only(bottom: gap),
                                      // Keep the native map and music card mounted while scrolling.
                                      cacheExtent:
                                          mapHeight +
                                          musicHeight +
                                          infoHeight +
                                          gap * 3,
                                      children: [
                                        SizedBox(
                                          height: mapHeight,
                                          child: DrivingMapView(
                                            key: _mapKey,
                                            expanded: false,
                                            onToggleExpanded: () => setState(
                                              () => _mapExpanded = true,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: gap),
                                        SizedBox(
                                          key: _musicKey,
                                          height: musicHeight,
                                          child: _MusicPanel(
                                            info: _nowPlaying,
                                            mediaLibraryAuthorized:
                                                _mediaLibraryAuthorized,
                                            onOpen: _openNowPlayingScreen,
                                            onPrevious: _mediaLibraryAuthorized
                                                ? () =>
                                                      _controlMusic('previous')
                                                : null,
                                            onTogglePlayback:
                                                _mediaLibraryAuthorized
                                                ? () => _controlMusic(
                                                    _isPlaying
                                                        ? 'pause'
                                                        : 'play',
                                                  )
                                                : null,
                                            onNext: _mediaLibraryAuthorized
                                                ? () => _controlMusic('next')
                                                : null,
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
                          ),
                        ),
                        SizedBox(height: _appsOpen ? 16 : 8),
                        _DrivingDock(
                          appsOpen: _appsOpen,
                          iconSize: iconSize,
                          onMapTap: _showDashboard,
                          onMusicTap: _showMusic,
                          onPhoneTap: _showContacts,
                          onAppsTap: () {
                            setState(() {
                              _mapExpanded = false;
                              _contactsOpen = false;
                              _appsOpen = !_appsOpen;
                              _musicScreenOpen = false;
                              _musicRequested = false;
                            });
                            _animateContent(returning: !_appsOpen);
                            _musicRefreshTimer?.cancel();
                            _musicRefreshTimer = null;
                          },
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

class _NowPlayingInfo {
  const _NowPlayingInfo({
    required this.title,
    required this.artist,
    required this.isPlaying,
    required this.duration,
    required this.position,
    this.artwork,
  });

  static const empty = _NowPlayingInfo(
    title: '',
    artist: '',
    isPlaying: false,
    duration: 0,
    position: 0,
  );

  final String title;
  final String artist;
  final bool isPlaying;
  final double duration;
  final double position;
  final Uint8List? artwork;

  factory _NowPlayingInfo.fromMap(Map<String, Object?> values) =>
      _NowPlayingInfo(
        title: values['title'] as String? ?? '',
        artist: values['artist'] as String? ?? '',
        isPlaying: values['isPlaying'] as bool? ?? false,
        duration: (values['duration'] as num?)?.toDouble() ?? 0,
        position: (values['position'] as num?)?.toDouble() ?? 0,
        artwork: values['artwork'] as Uint8List?,
      );
}

class _NowPlayingScreen extends StatelessWidget {
  const _NowPlayingScreen({
    required this.info,
    required this.mediaLibraryAuthorized,
    required this.onSpotifyTap,
    required this.onPrevious,
    required this.onTogglePlayback,
    required this.onNext,
    required this.onSeek,
  });

  final _NowPlayingInfo info;
  final bool mediaLibraryAuthorized;
  final VoidCallback onSpotifyTap;
  final VoidCallback? onPrevious;
  final VoidCallback? onTogglePlayback;
  final VoidCallback? onNext;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('now-playing-screen'),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xD9071827),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: .08)),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final artworkSize = math
            .min(
              constraints.maxWidth * .68,
              math.max(96.0, constraints.maxHeight * .36),
            )
            .toDouble();
        final duration = math.max(0.0, info.duration).toDouble();
        final position = info.position.clamp(0.0, duration).toDouble();
        final title = info.title.isEmpty
            ? mediaLibraryAuthorized
                  ? 'Not Playing'
                  : 'Apple Music'
            : info.title;
        final artist = info.artist.isEmpty
            ? mediaLibraryAuthorized
                  ? 'Play a song in Apple Music'
                  : 'Allow media access to show song details'
            : info.artist;

        return Column(
          children: [
            _MusicSourceSwitcher(onSpotifyTap: onSpotifyTap),
            if (!mediaLibraryAuthorized)
              const Padding(
                padding: EdgeInsets.only(top: 5),
                child: Text(
                  'Allow Media & Apple Music access in Settings to show and control the current song.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF90A4AD), fontSize: 11),
                ),
              ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox.square(
                    dimension: artworkSize,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: info.artwork == null
                          ? const ColoredBox(
                              color: Color(0xFF18354B),
                              child: Icon(
                                CupertinoIcons.music_note,
                                color: Colors.white,
                                size: 64,
                              ),
                            )
                          : Image.memory(info.artwork!, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF90A4AD),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PlaybackButton(
                        tooltip: 'Previous track',
                        icon: CupertinoIcons.backward_fill,
                        onPressed: onPrevious,
                        size: 27,
                      ),
                      const SizedBox(width: 20),
                      _PlaybackButton(
                        tooltip: info.isPlaying ? 'Pause' : 'Play',
                        icon: info.isPlaying
                            ? CupertinoIcons.pause_fill
                            : CupertinoIcons.play_fill,
                        onPressed: onTogglePlayback,
                        size: 34,
                      ),
                      const SizedBox(width: 20),
                      _PlaybackButton(
                        tooltip: 'Next track',
                        icon: CupertinoIcons.forward_fill,
                        onPressed: onNext,
                        size: 27,
                      ),
                    ],
                  ),
                  Slider(
                    value: position,
                    max: duration > 0 ? duration : 1.0,
                    onChanged: duration > 0 ? onSeek : null,
                    activeColor: const Color(0xFF8BC9C5),
                    inactiveColor: Colors.white24,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatMusicTime(position),
                        style: const TextStyle(
                          color: Color(0xFF90A4AD),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatMusicTime(duration),
                        style: const TextStyle(
                          color: Color(0xFF90A4AD),
                          fontSize: 12,
                        ),
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

  String _formatMusicTime(double seconds) {
    final total = seconds.floor();
    final minutes = total ~/ 60;
    final remainder = total % 60;
    return '$minutes:${remainder.toString().padLeft(2, '0')}';
  }
}

class _MusicSourceSwitcher extends StatefulWidget {
  const _MusicSourceSwitcher({required this.onSpotifyTap});

  final VoidCallback onSpotifyTap;

  @override
  State<_MusicSourceSwitcher> createState() => _MusicSourceSwitcherState();
}

class _MusicSourceSwitcherState extends State<_MusicSourceSwitcher> {
  bool _spotifySelected = false;

  @override
  Widget build(BuildContext context) => Container(
    height: 40,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: const Color(0xFF080E18),
      borderRadius: BorderRadius.circular(14),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOutCubic,
            top: 0,
            bottom: 0,
            left: _spotifySelected ? constraints.maxWidth / 2 : 0,
            width: constraints.maxWidth / 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _MusicSourceButton(
                  label: 'Apple Music',
                  selected: !_spotifySelected,
                  onTap: () => setState(() => _spotifySelected = false),
                ),
              ),
              Expanded(
                child: _MusicSourceButton(
                  label: 'Spotify',
                  selected: _spotifySelected,
                  onTap: () {
                    setState(() => _spotifySelected = true);
                    widget.onSpotifyTap();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _MusicSourceButton extends StatelessWidget {
  const _MusicSourceButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          style: TextStyle(
            color: selected ? const Color(0xFF111318) : const Color(0xFF78808C),
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
          child: Text(label),
        ),
      ),
    ),
  );
}

class _MusicPanel extends StatelessWidget {
  const _MusicPanel({
    required this.info,
    required this.mediaLibraryAuthorized,
    required this.onOpen,
    required this.onPrevious,
    required this.onTogglePlayback,
    required this.onNext,
  });

  final _NowPlayingInfo info;
  final bool mediaLibraryAuthorized;
  final VoidCallback onOpen;
  final VoidCallback? onPrevious;
  final VoidCallback? onTogglePlayback;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => Material(
    key: const ValueKey('driving-music'),
    color: const Color(0xD907303B),
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final artworkSize = math
                .min(constraints.maxHeight, constraints.maxWidth * .3)
                .toDouble();
            final title = info.title.isEmpty ? 'Not Playing' : info.title;
            final artist = info.artist.isEmpty
                ? mediaLibraryAuthorized
                      ? 'Open Apple Music to play a song'
                      : 'Allow access to show song details'
                : info.artist;
            return Row(
              children: [
                SizedBox.square(
                  dimension: artworkSize,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: info.artwork == null
                        ? const ColoredBox(
                            color: Color(0xFF34515F),
                            child: Icon(
                              CupertinoIcons.music_note,
                              color: Colors.white,
                              size: 42,
                            ),
                          )
                        : Image.memory(info.artwork!, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
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
                      Text(
                        artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
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
                            onPressed: onPrevious,
                          ),
                          _PlaybackButton(
                            tooltip: info.isPlaying ? 'Pause' : 'Play',
                            icon: info.isPlaying
                                ? CupertinoIcons.pause_fill
                                : CupertinoIcons.play_fill,
                            onPressed: onTogglePlayback,
                            size: 30,
                          ),
                          _PlaybackButton(
                            tooltip: 'Next track',
                            icon: CupertinoIcons.forward_fill,
                            onPressed: onNext,
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
      ),
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
  final VoidCallback? onPressed;
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
