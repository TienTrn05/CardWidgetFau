import 'dart:async';
import 'dart:math' as math;

import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/core/storage/local_state_store.dart';
import 'package:carwidget/features/settings/presentation/pages/widget_tutorial_page.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SoundsPage extends StatefulWidget {
  const SoundsPage({super.key});

  @override
  State<SoundsPage> createState() => _SoundsPageState();
}

class _SoundsPageState extends State<SoundsPage> {
  final Map<_SoundEvent, String?> _selections = {
    for (final event in _SoundEvent.values) event: null,
  };

  @override
  void initState() {
    super.initState();
    final saved = LocalStateStore.instance.readMap('sounds');
    if (saved != null) {
      for (final event in _SoundEvent.values) {
        _selections[event] = saved[event.name] as String?;
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 18),
        child: Text(
          'Sounds',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            height: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      _SetupShortcutButton(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const WidgetTutorialPage()),
        ),
      ),
      const SizedBox(height: 16),
      _SoundEventCard(
        event: _SoundEvent.connect,
        selectedSound: _selections[_SoundEvent.connect],
        onTap: () => _chooseSound(_SoundEvent.connect),
      ),
      const SizedBox(height: 16),
      _SoundEventCard(
        event: _SoundEvent.disconnect,
        selectedSound: _selections[_SoundEvent.disconnect],
        onTap: () => _chooseSound(_SoundEvent.disconnect),
      ),
      const SizedBox(height: 16),
      _SoundEventCard(
        event: _SoundEvent.home,
        selectedSound: _selections[_SoundEvent.home],
        onTap: () => _chooseSound(_SoundEvent.home),
      ),
    ],
  );

  Future<void> _chooseSound(_SoundEvent event) async {
    final result = await Navigator.of(context).push<_SoundSelectionResult>(
      MaterialPageRoute<_SoundSelectionResult>(
        builder: (_) => _SoundSelectionPage(
          title: event.title,
          initialSelection: _selections[event],
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _selections[event] = result.sound);
      LocalStateStore.instance.setValue('sounds', {
        for (final entry in _selections.entries) entry.key.name: entry.value,
      });
    }
  }
}

enum _SoundEvent { connect, disconnect, home }

extension on _SoundEvent {
  String get title => switch (this) {
    _SoundEvent.connect => 'Connect Sound',
    _SoundEvent.disconnect => 'Disconnect Sound',
    _SoundEvent.home => 'Home Arrived Sound',
  };

  String get subtitle => switch (this) {
    _SoundEvent.connect => 'Play when CarPlay connects',
    _SoundEvent.disconnect => 'Play when CarPlay disconnects',
    _SoundEvent.home => 'Play when arrives home',
  };

  IconData get icon => switch (this) {
    _SoundEvent.connect => Icons.play_arrow_rounded,
    _SoundEvent.disconnect => Icons.play_arrow_rounded,
    _SoundEvent.home => Icons.home_rounded,
  };

  Color get color => switch (this) {
    _SoundEvent.connect => AppColors.green,
    _SoundEvent.disconnect => const Color(0xFFFFB800),
    _SoundEvent.home => const Color(0xFF1685FF),
  };

  Color get iconBackground => switch (this) {
    _SoundEvent.connect => const Color(0xFF063D2C),
    _SoundEvent.disconnect => const Color(0xFF3D3005),
    _SoundEvent.home => const Color(0xFF0A2A4E),
  };
}

class _SetupShortcutButton extends StatelessWidget {
  const _SetupShortcutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFF303940)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_rounded, color: AppColors.green, size: 19),
            SizedBox(width: 10),
            Text(
              'How to Setup with Shortcut',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SoundEventCard extends StatelessWidget {
  const _SoundEventCard({
    required this.event,
    required this.selectedSound,
    required this.onTap,
  });

  final _SoundEvent event;
  final String? selectedSound;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: const Color(0xFF303940)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: event.iconBackground,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: event == _SoundEvent.home
                    ? Icon(event.icon, color: event.color, size: 25)
                    : CustomPaint(
                        painter: _SoundPlaybackRingPainter(color: event.color),
                        child: SizedBox.square(
                          dimension: 26,
                          child: Icon(event.icon, color: event.color, size: 18),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.3,
                      letterSpacing: .2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.subtitle,
                    style: const TextStyle(
                      color: Color(0xFFAAB6BF),
                      fontSize: 12,
                      height: 1.35,
                      letterSpacing: .1,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Material(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: CustomPaint(
              foregroundPainter: selectedSound == null
                  ? const _AddSoundBorderPainter()
                  : null,
              child: Container(
                constraints: const BoxConstraints(minHeight: 60),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selectedSound == null
                        ? Colors.transparent
                        : const Color(0xFF39424A),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selectedSound == null
                          ? CupertinoIcons.add
                          : Icons.graphic_eq_rounded,
                      color: selectedSound == null
                          ? Colors.white
                          : Colors.white70,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedSound ?? 'Add a sound',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.3,
                          letterSpacing: .2,
                          fontWeight: selectedSound == null
                              ? FontWeight.w400
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_forward,
                      color: Colors.white,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _SoundPlaybackRingPainter extends CustomPainter {
  const _SoundPlaybackRingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = (Offset.zero & size).deflate(1.5);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round;
    const segmentAngle = math.pi * 2 / 3;
    const gapAngle = .4;

    for (var segment = 0; segment < 3; segment++) {
      canvas.drawArc(
        bounds,
        -math.pi / 2 + gapAngle / 2 + segment * segmentAngle,
        segmentAngle - gapAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SoundPlaybackRingPainter oldDelegate) =>
      color != oldDelegate.color;
}

class _AddSoundBorderPainter extends CustomPainter {
  const _AddSoundBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.5),
          const Radius.circular(18),
        ),
      );
    final paint = Paint()
      ..color = AppColors.green.withValues(alpha: .8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final metric in path.computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += 11) {
        canvas.drawPath(
          metric.extractPath(distance, (distance + 6).clamp(0, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AddSoundBorderPainter oldDelegate) => false;
}

class _SoundSelectionResult {
  const _SoundSelectionResult(this.sound);

  final String? sound;
}

class _SoundSelectionPage extends StatefulWidget {
  const _SoundSelectionPage({
    required this.title,
    required this.initialSelection,
  });

  final String title;
  final String? initialSelection;

  @override
  State<_SoundSelectionPage> createState() => _SoundSelectionPageState();
}

class _SoundSelectionPageState extends State<_SoundSelectionPage> {
  static const _soundAssets = {
    'Car Horn': 'assets/sounds/car_horn.wav',
    'Calling': 'assets/sounds/calling.wav',
    'I Got This': 'assets/sounds/i_got_this.wav',
    'Sus Meme': 'assets/sounds/sus_meme.wav',
    'Hello There': 'assets/sounds/hello_there.wav',
    'Woooooaah': 'assets/sounds/wooooaah.wav',
    'Thud': 'assets/sounds/thud.wav',
    'Alfa Romeo Airlines': 'assets/sounds/alfa_romeo_airlines.wav',
    'Engine Start': 'assets/sounds/engine_start.wav',
    'Turbo Boost': 'assets/sounds/turbo_boost.wav',
    'Air Horn': 'assets/sounds/air_horn.wav',
    'Retro Chime': 'assets/sounds/retro_chime.wav',
    'Race Countdown': 'assets/sounds/race_countdown.wav',
    'Police Siren': 'assets/sounds/police_siren.wav',
    'Dog Bark': 'assets/sounds/dog_bark.wav',
    'Notification Bell': 'assets/sounds/notification_bell.wav',
  };

  static const _sounds = [
    'Car Horn',
    'Calling',
    'I Got This',
    'Sus Meme',
    'Hello There',
    'Woooooaah',
    'Thud',
    'Alfa Romeo Airlines',
    'Engine Start',
    'Turbo Boost',
    'Air Horn',
    'Retro Chime',
    'Race Countdown',
    'Police Siren',
    'Dog Bark',
    'Notification Bell',
  ];

  late String? _selectedSound = widget.initialSelection;
  String _query = '';
  VideoPlayerController? _previewController;

  @override
  void dispose() {
    final controller = _previewController;
    _previewController = null;
    if (controller != null) unawaited(controller.dispose());
    super.dispose();
  }

  Future<void> _playPreview(String sound) async {
    final asset = _soundAssets[sound];
    if (asset == null) {
      _showMessage('Audio preview is not available for this sound yet.');
      return;
    }

    final previousController = _previewController;
    _previewController = null;
    if (previousController != null) {
      await previousController.dispose();
    }
    if (!mounted) return;

    final controller = VideoPlayerController.asset(asset);
    _previewController = controller;
    try {
      await controller.initialize();
      if (!mounted || !identical(_previewController, controller)) {
        await controller.dispose();
        return;
      }

      late VoidCallback completionListener;
      completionListener = () {
        if (controller.value.isCompleted) {
          controller.removeListener(completionListener);
          if (identical(_previewController, controller)) {
            _previewController = null;
          }
          unawaited(controller.dispose());
        }
      };
      controller.addListener(completionListener);
      await controller.play();
    } catch (_) {
      if (identical(_previewController, controller)) {
        _previewController = null;
      }
      await controller.dispose();
      if (mounted) _showMessage('Unable to play this audio preview.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final filteredSounds = _sounds
        .where(
          (sound) => sound.toLowerCase().contains(_query.trim().toLowerCase()),
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search name sound',
                  hintStyle: const TextStyle(color: AppColors.muted),
                  prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(17),
                    borderSide: const BorderSide(color: Color(0xFF39424A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(17),
                    borderSide: const BorderSide(color: AppColors.green),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'LIST SOUNDS',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: filteredSounds.isEmpty
                  ? const Center(
                      child: Text(
                        'No sounds found',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      itemCount: filteredSounds.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final sound = filteredSounds[index];
                        return _SoundChoiceTile(
                          name: sound,
                          selected: _selectedSound == sound,
                          onSelect: () => setState(() {
                            _selectedSound = _selectedSound == sound
                                ? null
                                : sound;
                          }),
                          onPreview: () => _playPreview(sound),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 62,
                  child: FilledButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(_SoundSelectionResult(_selectedSound)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoundChoiceTile extends StatelessWidget {
  const _SoundChoiceTile({
    required this.name,
    required this.selected,
    required this.onSelect,
    required this.onPreview,
  });

  final String name;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(18),
      splashFactory: NoSplash.splashFactory,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.green : const Color(0xFF39424A),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: selected ? AppColors.green : AppColors.muted,
              size: 27,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: selected ? AppColors.green : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Preview $name',
              onPressed: onPreview,
              icon: const Icon(Icons.play_arrow_rounded, size: 16),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF87909B),
                foregroundColor: Colors.white,
                minimumSize: const Size(24, 24),
                maximumSize: const Size(24, 24),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
