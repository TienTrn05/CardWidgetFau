import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

class InternetConnection {
  static const _settingsChannel = MethodChannel(
    'carwidget/network_settings_v1',
  );
  final Set<HttpClient> _clients = {};
  int _generation = 0;

  Future<bool?> check() async {
    if (!Platform.isAndroid && !Platform.isIOS) return null;
    final generation = _generation;
    // A successful response checks Internet access, not just a Wi-Fi link.
    var connected = await _probe(
      Uri.https('www.gstatic.com', '/generate_204'),
      expectsEmptyResponse: true,
    );
    if (generation != _generation) return null;
    if (!connected) {
      connected = await _probe(
        Uri.https('captive.apple.com', '/hotspot-detect.html'),
        expectsEmptyResponse: false,
      );
    }
    return generation == _generation ? connected : null;
  }

  Future<bool> _probe(Uri uri, {required bool expectsEmptyResponse}) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    _clients.add(client);
    try {
      return await (() async {
        final request = await client.getUrl(uri);
        request.followRedirects = false;
        request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
        final response = await request.close();
        if (expectsEmptyResponse) {
          return response.statusCode == HttpStatus.noContent;
        }
        if (response.statusCode != HttpStatus.ok) return false;
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
          if (bytes.length > 4096) return false;
        }
        return utf8
            .decode(bytes, allowMalformed: true)
            .contains('<TITLE>Success</TITLE>');
      })().timeout(const Duration(seconds: 5));
    } on IOException {
      return false;
    } on TimeoutException {
      return false;
    } on StateError {
      // Closing a client while the app backgrounds can cancel an open request.
      return false;
    } finally {
      _clients.remove(client);
      client.close(force: true);
    }
  }

  Future<void> openSettings() =>
      _settingsChannel.invokeMethod<void>('openWifiSettings');

  void cancel() {
    _generation++;
    for (final client in _clients) {
      client.close(force: true);
    }
    _clients.clear();
  }
}
