import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/features/settings/presentation/pages/widget_tutorial_page.dart';
import 'package:flutter/material.dart';

class SoundsPage extends StatefulWidget {
  const SoundsPage({super.key});

  @override
  State<SoundsPage> createState() => _SoundsPageState();
}

class _SoundsPageState extends State<SoundsPage> {
  final Map<_SoundEvent, String> _selections = {
    _SoundEvent.connect: 'Car Horn',
    _SoundEvent.disconnect: 'I Got This',
    _SoundEvent.home: 'Car Horn',
  };

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
        selectedSound: _selections[_SoundEvent.connect]!,
        onTap: () => _chooseSound(_SoundEvent.connect),
      ),
      const SizedBox(height: 16),
      _SoundEventCard(
        event: _SoundEvent.disconnect,
        selectedSound: _selections[_SoundEvent.disconnect]!,
        onTap: () => _chooseSound(_SoundEvent.disconnect),
      ),
      const SizedBox(height: 16),
      _SoundEventCard(
        event: _SoundEvent.home,
        selectedSound: _selections[_SoundEvent.home]!,
        onTap: () => _chooseSound(_SoundEvent.home),
      ),
    ],
  );

  Future<void> _chooseSound(_SoundEvent event) async {
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => _SoundSelectionPage(
          title: event.title,
          initialSelection: _selections[event]!,
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _selections[event] = selected);
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
    _SoundEvent.connect => Icons.play_circle_outline_rounded,
    _SoundEvent.disconnect => Icons.play_circle_outline_rounded,
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
  final String selectedSound;
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
              child: Icon(event.icon, color: event.color, size: 23),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
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
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 49,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF39424A)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.graphic_eq_rounded,
                    color: Colors.white70,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedSound,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _SoundSelectionPage extends StatefulWidget {
  const _SoundSelectionPage({
    required this.title,
    required this.initialSelection,
  });

  final String title;
  final String initialSelection;

  @override
  State<_SoundSelectionPage> createState() => _SoundSelectionPageState();
}

class _SoundSelectionPageState extends State<_SoundSelectionPage> {
  static const _sounds = [
    'Car Horn',
    'Calling',
    'I Got This',
    'Sus Meme',
    'Hello There',
    'Woooooaah',
    'Thud',
    'Alfa Romeo Airlines',
  ];

  late String _selectedSound = widget.initialSelection;
  String _query = '';

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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _CreateCustomSoundButton(
                onTap: () => ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Custom sounds are not available yet.'),
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
                    fontWeight: FontWeight.w500,
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
                          onSelect: () =>
                              setState(() => _selectedSound = sound),
                          onPreview: () => ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Audio preview is not available yet.',
                                ),
                              ),
                            ),
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
                    onPressed: () => Navigator.of(context).pop(_selectedSound),
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

class _CreateCustomSoundButton extends StatelessWidget {
  const _CreateCustomSoundButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(1),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.green, Color(0xFF25C8D7)],
      ),
      borderRadius: BorderRadius.circular(19),
    ),
    child: Material(
      color: const Color(0xFF072A2C),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: const SizedBox(
          height: 88,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 17),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF063D2C),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.queue_music_rounded,
                      color: AppColors.green,
                      size: 24,
                    ),
                  ),
                ),
                SizedBox(width: 13),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Custom Sound',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Make your own personalized sounds',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
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
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF39424A)),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Preview $name',
              onPressed: onPreview,
              icon: const Icon(Icons.play_arrow_rounded, size: 19),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF87909B),
                foregroundColor: Colors.white,
                minimumSize: const Size(29, 29),
                maximumSize: const Size(29, 29),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
