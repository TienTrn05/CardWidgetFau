import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_theme.dart';
import 'internet_connection.dart';

class ConnectionNotice extends StatefulWidget {
  const ConnectionNotice({super.key, required this.child});

  final Widget child;

  @override
  State<ConnectionNotice> createState() => _ConnectionNoticeState();
}

class _ConnectionNoticeState extends State<ConnectionNotice>
    with WidgetsBindingObserver {
  final _connection = InternetConnection();
  Timer? _timer;
  DialogRoute<void>? _dialog;
  bool _foreground = true;
  bool _notified = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resume();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resume();
    } else {
      _foreground = false;
      _generation++;
      _timer?.cancel();
      _connection.cancel();
    }
  }

  void _resume() {
    _foreground = true;
    _timer?.cancel();
    _connection.cancel();
    unawaited(_check(++_generation));
  }

  Future<void> _check(int generation) async {
    final connected = await _connection.check();
    if (!mounted || !_foreground || generation != _generation) return;
    if (connected == true) {
      _notified = false;
      _closeDialog();
    } else if (connected == false && !_notified) {
      _notified = true;
      _showDialog();
    }
    if (connected != null) {
      _timer = Timer(
        const Duration(seconds: 10),
        () => unawaited(_check(generation)),
      );
    }
  }

  void _showDialog() {
    if (_dialog != null) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = DialogRoute<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .65),
      barrierDismissible: false,
      builder: (_) => _OfflineDialog(onOpenSettings: _connection.openSettings),
    );
    _dialog = route;
    unawaited(
      navigator.push(route).whenComplete(() {
        if (identical(_dialog, route)) _dialog = null;
      }),
    );
  }

  void _closeDialog() {
    final route = _dialog;
    _dialog = null;
    if (route != null && route.isActive) {
      // Remove only this notice, even if another route has opened above it.
      route.navigator?.removeRoute(route);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    _timer?.cancel();
    _connection.cancel();
    final route = _dialog;
    _dialog = null;
    if (route != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (route.isActive) route.navigator?.removeRoute(route);
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _OfflineDialog extends StatefulWidget {
  const _OfflineDialog({required this.onOpenSettings});

  final Future<void> Function() onOpenSettings;

  @override
  State<_OfflineDialog> createState() => _OfflineDialogState();
}

class _OfflineDialogState extends State<_OfflineDialog> {
  bool _opening = false;
  String? _error;

  Future<void> _openSettings() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      await widget.onOpenSettings();
    } on PlatformException {
      if (mounted) {
        setState(() => _error = 'Please open Settings and connect to Wi-Fi.');
      }
    } on MissingPluginException {
      if (mounted) {
        setState(() => _error = 'Please open Settings and connect to Wi-Fi.');
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Dialog(
      backgroundColor: const Color(0xFF252D33),
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _OfflineIcon(),
              const SizedBox(height: 24),
              const Text(
                'No Internet Connection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'You’re offline. Please connect to the internet to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.3,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 14),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _opening ? null : _openSettings,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(0, 52),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Go to Settings',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _OfflineIcon extends StatelessWidget {
  const _OfflineIcon();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: 80,
      height: 72,
      child: const Icon(
        Icons.wifi_off_rounded,
        color: AppColors.green,
        size: 70,
      ),
    ),
  );
}
