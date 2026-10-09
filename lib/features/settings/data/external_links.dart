import 'package:carwidget/features/settings/data/device_identity.dart';
import 'package:flutter/services.dart';

class ExternalLinks {
  ExternalLinks._();

  static const _channel = MethodChannel('carwidget/external_links');

  static final Uri legal = Uri.parse('https://mxtapp.website/');

  static Future<void> openFeedback() async {
    Map<String, String>? details;
    String id = 'Unknown';
    try {
      details = await _channel.invokeMapMethod<String, String>('getDeviceInfo');
    } on PlatformException {
      // A missing diagnostic field must not prevent the user from sending feedback.
    } on MissingPluginException {
      // Native changes require a full rebuild; keep the email available meanwhile.
    }
    try {
      id = await DeviceIdentity.getOrCreateId();
    } on PlatformException {
      // Keep the feedback action available when the support ID cannot be read.
    } on MissingPluginException {
      // Keep the feedback action available when the native ID channel is absent.
    } on StateError {
      // Keep the feedback action available when the support ID is empty.
    }
    String detail(String key) => details?[key] ?? 'Unknown';
    final body = [
      'Device information:',
      '',
      'Device ID: $id',
      'Phone model: ${detail('model')}',
      'OS version: ${detail('osVersion')}',
      'App version: ${detail('appVersion')}',
      'Bundle ID: ${detail('bundleId')}',
      'Premium: Unknown',
      'Language: ${detail('language')}',
      '--------------------',
      'Content:',
      '',
    ].join('\n');
    final uri = Uri(
      scheme: 'mailto',
      path: 'maixuantruongcvdev@gmail.com',
      query:
          'subject=${Uri.encodeComponent('CarWidget feedback')}'
          '&body=${Uri.encodeComponent(body)}',
    );
    await _open(uri);
  }

  static Future<void> openLegal() => _open(legal);

  static Future<void> _open(Uri uri) =>
      _channel.invokeMethod<void>('open', uri.toString());
}
