import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/features/settings/data/app_icon_preference.dart';
import 'package:carwidget/features/settings/data/app_sharing.dart';
import 'package:carwidget/features/settings/data/device_identity.dart';
import 'package:carwidget/features/settings/data/settings_content.dart';
import 'package:carwidget/features/settings/presentation/pages/change_icon_page.dart';
import 'package:carwidget/features/settings/presentation/pages/widget_tutorial_page.dart';
import 'package:carwidget/features/settings/presentation/widgets/tutorial_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _deviceId;
  bool _deviceIdFailed = false;
  late final Future<SettingsContent> _contentFuture;

  @override
  void initState() {
    super.initState();
    _contentFuture = SettingsContent.load();
    _loadDeviceId();
    AppIconPreference.load().catchError((Object _) {});
  }

  Future<void> _loadDeviceId() async {
    try {
      final id = await DeviceIdentity.getOrCreateId();
      if (mounted) setState(() => _deviceId = id);
    } catch (_) {
      if (mounted) setState(() => _deviceIdFailed = true);
    }
  }

  Future<void> _copyDeviceId() async {
    if (_deviceId == null) {
      if (_deviceIdFailed) {
        setState(() => _deviceIdFailed = false);
        await _loadDeviceId();
      }
      return;
    }
    await Clipboard.setData(ClipboardData(text: _deviceId!));
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Device ID copied.')));
    }
  }

  Future<void> _shareApp() async {
    try {
      await AppSharing.share();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open sharing.')),
        );
      }
    }
  }

  void _showUnavailable(BuildContext context, String title) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$title is not available yet.')));
  }

  void _openItem(SettingsItem item) {
    switch (item.id) {
      case 'change_icon':
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const ChangeIconPage()));
      case 'widget_tutorial':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const WidgetTutorialPage()),
        );
      case 'video_tutorial':
        showTutorialSheet(context);
      case 'share_app':
        _shareApp();
      case 'device_id':
        _copyDeviceId();
      default:
        _showUnavailable(context, item.title);
    }
  }

  IconData _iconFor(String name) => switch (name) {
    'purchase' => Icons.shopping_cart_outlined,
    'icon' => Icons.dashboard_customize_outlined,
    'info' => Icons.info_outline_rounded,
    'video' => Icons.play_circle_outline_rounded,
    'share' => Icons.ios_share_rounded,
    'feedback' => Icons.chat_bubble_outline_rounded,
    'terms' => Icons.article_outlined,
    'device' => Icons.phone_iphone_outlined,
    _ => Icons.settings_outlined,
  };

  @override
  Widget build(BuildContext context) => FutureBuilder<SettingsContent>(
    future: _contentFuture,
    initialData: SettingsContent.cached,
    builder: (context, snapshot) => ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            tooltip: 'Back',
            onPressed: widget.onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
        ),
        const SizedBox(height: 17),
        Text(
          snapshot.data?.title ?? '',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 26),
        if (snapshot.hasError)
          const Text('Settings could not be loaded.')
        else if (!snapshot.hasData)
          const Center(child: Text('Loading settings...'))
        else
          for (final section in snapshot.data!.sections) ...[
            _SettingsGroup(
              title: section.title,
              rows: [
                for (final item in section.items)
                  _SettingsRow(
                    icon: _iconFor(item.icon),
                    title: item.title,
                    subtitle: item.id == 'device_id'
                        ? _deviceId ??
                              (_deviceIdFailed ? 'Tap to retry' : 'Loading...')
                        : null,
                    onTap: () => _openItem(item),
                  ),
              ],
            ),
            const SizedBox(height: 18),
          ],
      ],
    ),
  );
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.rows});

  final String title;
  final List<_SettingsRow> rows;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      const SizedBox(height: 7),
      Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.subtleBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0)
                const Divider(
                  height: 1,
                  indent: 14,
                  endIndent: 14,
                  color: AppColors.subtleBorder,
                ),
              rows[index],
            ],
          ],
        ),
      ),
    ],
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      height: subtitle == null ? 50 : 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 21, color: AppColors.white),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14)),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 23,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    ),
  );
}
