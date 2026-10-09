import 'package:flutter/services.dart';

class AppSharing {
  AppSharing._();

  static const _channel = MethodChannel('carwidget/share_app');

  static Future<void> share() => _channel.invokeMethod<void>('share');
}
