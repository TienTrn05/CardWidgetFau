import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppIconPreference {
  AppIconPreference._();

  static const _channel = MethodChannel('carwidget/app_icon_preference');
  static final selected = ValueNotifier<int>(0);

  static Future<void> load() async {
    final value = await _channel.invokeMethod<int>('getSelectedIcon');
    selected.value = value != null && value >= 0 && value < 6 ? value : 0;
  }

  static Future<void> choose(int value) async {
    if (value < 0 || value > 5) throw RangeError.range(value, 0, 5);
    await _channel.invokeMethod<void>('setSelectedIcon', value);
    selected.value = value;
  }
}
