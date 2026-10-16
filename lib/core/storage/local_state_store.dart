import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Stores Flutter app state independently of the WidgetKit export channel.
class LocalStateStore with WidgetsBindingObserver {
  LocalStateStore();

  static final instance = LocalStateStore();
  static const _channel = MethodChannel('carwidget/local_storage_v1');
  final saveError = ValueNotifier<bool>(false);
  Map<String, dynamic> _values = {};
  Directory? _directory;
  String? _lastGoodSnapshot;
  Future<void>? _writing;
  bool _dirty = false;
  bool _scheduled = false;
  int _mediaSequence = 0;

  Future<void> initialize({Directory? directory}) async {
    if (_directory != null) return;
    final path =
        directory?.path ??
        await _channel.invokeMethod<String>('getSupportDirectory');
    if (path == null || path.isEmpty) {
      throw StateError('Local storage is unavailable.');
    }
    final root = Directory(path);
    await root.create(recursive: true);
    final file = File('${root.path}/state_v1.json');
    final backup = File('${file.path}.bak');
    String? source;
    Map<String, dynamic> values = {};
    for (final candidate in [file, backup]) {
      if (!await candidate.exists()) continue;
      try {
        final content = await candidate.readAsString();
        final envelope = jsonDecode(content) as Map<String, dynamic>;
        if (envelope['schemaVersion'] != 1) {
          throw UnsupportedError('Unsupported local storage version.');
        }
        values = Map<String, dynamic>.from(envelope['data'] as Map);
        source = content;
        break;
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }
    if (source == null && (await file.exists() || await backup.exists())) {
      throw const FormatException('Saved data could not be read.');
    }
    _values = values;
    _lastGoodSnapshot = source;
    _directory = root;
  }

  Map<String, dynamic>? readMap(String key) {
    final value = _values[key];
    return value == null ? null : Map<String, dynamic>.from(value as Map);
  }

  void setValue(String key, Object? value) {
    _values[key] = value;
    _dirty = true;
    // Standalone widget tests can use the store in memory without a platform.
    if (_directory == null || _scheduled) return;
    _scheduled = true;
    scheduleMicrotask(() {
      _scheduled = false;
      unawaited(flush());
    });
  }

  Future<void> flush() async {
    if (_directory == null) return;
    if (_writing != null) return _writing!;
    final operation = _writePendingChanges();
    _writing = operation;
    try {
      await operation;
    } finally {
      _writing = null;
    }
  }

  Future<void> _writePendingChanges() async {
    final file = File('${_directory!.path}/state_v1.json');
    try {
      while (_dirty) {
        _dirty = false;
        final snapshot = jsonEncode({'schemaVersion': 1, 'data': _values});
        final pending = File('${file.path}.tmp');
        await pending.writeAsString(snapshot, flush: true);
        final backup = File('${file.path}.bak.tmp');
        await backup.writeAsString(_lastGoodSnapshot ?? snapshot, flush: true);
        await backup.rename('${file.path}.bak');
        await pending.rename(file.path);
        _lastGoodSnapshot = snapshot;
      }
      saveError.value = false;
    } catch (error, stack) {
      _dirty = true;
      saveError.value = true;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'local storage',
          context: ErrorDescription('while saving app state'),
        ),
      );
    }
  }

  Future<String> importVideo(String sourcePath) async {
    final directory = _directory;
    if (directory == null) {
      throw StateError('Local storage is not initialized.');
    }
    final media = Directory('${directory.path}/media');
    await media.create(recursive: true);
    final extension = sourcePath.split('.').last.toLowerCase();
    final suffix = RegExp(r'^[a-z0-9]{1,6}$').hasMatch(extension)
        ? extension
        : 'mp4';
    final name = '${DateTime.now().microsecondsSinceEpoch}_${_mediaSequence++}';
    final destination = '${media.path}/$name.$suffix';
    await File(sourcePath).copy(destination);
    return destination;
  }

  String? relativeMediaPath(String? path) {
    if (path == null || _directory == null) return path;
    final prefix = '${_directory!.path}/';
    return path.startsWith(prefix) ? path.substring(prefix.length) : path;
  }

  String? resolveMediaPath(String? path) {
    if (path == null || path.startsWith('/')) return path;
    if (!path.startsWith('media/') || path.split('/').contains('..')) {
      throw const FormatException('Invalid saved media path.');
    }
    if (_directory == null) {
      throw StateError('Local storage is not initialized.');
    }
    return '${_directory!.path}/$path';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(flush());
  }
}
