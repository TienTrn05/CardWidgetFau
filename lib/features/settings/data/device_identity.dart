import 'package:flutter/services.dart';

/// An app installation identifier, generated and stored by the host platform.
class DeviceIdentity {
  DeviceIdentity._();

  static const MethodChannel _channel = MethodChannel(
    'carwidget/device_identity',
  );

  static Future<String> getOrCreateId() async {
    final id = await _channel.invokeMethod<String>('getOrCreateId');
    if (id == null || id.isEmpty) {
      throw StateError('The device ID is unavailable.');
    }
    return id;
  }
}
