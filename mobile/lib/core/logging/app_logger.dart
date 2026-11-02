import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum LogLevel { debug, info, warn, error }

class LogEntry {
  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  });

  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  String _levelLabel() {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warn:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }

  String format() {
    final buf = StringBuffer()
      ..write(timestamp.toUtc().toIso8601String())
      ..write(' [')
      ..write(_levelLabel())
      ..write('] [')
      ..write(tag)
      ..write('] ')
      ..write(message);
    if (error != null) {
      buf.write(' | error: $error');
    }
    if (stackTrace != null) {
      buf.write('\n$stackTrace');
    }
    return buf.toString();
  }
}

class AppLogger {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  static const int bufferCapacity = 1000;
  static const int _maxFileBytes = 1024 * 1024;
  static const String _logDirName = 'logs';
  static const String _currentFileName = 'anchor.log';
  static const String _previousFileName = 'anchor.log.1';

  final Queue<LogEntry> _buffer = Queue<LogEntry>();
  final StreamController<LogEntry> _controller =
      StreamController<LogEntry>.broadcast();

  /// Minimum level echoed to the console; buffer and file always get
  /// everything.
  LogLevel consoleLevel = LogLevel.debug;

  File? _file;
  Future<void> _writeChain = Future.value();
  bool _initialized = false;

  Stream<LogEntry> get stream => _controller.stream;
  List<LogEntry> get snapshot => List.unmodifiable(_buffer);

  Future<void> init() async {
    if (_initialized) return;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, _logDirName));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _file = File(p.join(dir.path, _currentFileName));
      if (!await _file!.exists()) {
        await _file!.create();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('AppLogger: failed to init file: $e');
      _file = null;
    }
    _initialized = true;
    info('App', 'Logger initialized');
  }

  void debug(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.debug, tag, message, error: error, stackTrace: stackTrace);
  }

  void info(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.info, tag, message, error: error, stackTrace: stackTrace);
  }

  void warn(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.warn, tag, message, error: error, stackTrace: stackTrace);
  }

  void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, tag, message, error: error, stackTrace: stackTrace);
  }

  void _log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
    _buffer.addLast(entry);
    while (_buffer.length > bufferCapacity) {
      _buffer.removeFirst();
    }
    if (!_controller.isClosed) {
      _controller.add(entry);
    }
    if (kDebugMode && level.index >= consoleLevel.index) {
      debugPrint(entry.format());
    }
    _enqueueWrite(entry);
  }

  /// Completes once everything logged so far is in the file; a background
  /// task awaits it before its engine goes away.
  Future<void> flush() => _writeChain;

  void _enqueueWrite(LogEntry entry) {
    final file = _file;
    if (file == null) return;
    _writeChain = _writeChain.then((_) async {
      try {
        await _rotateIfNeeded(file);
        await file.writeAsString(
          '${entry.format()}\n',
          mode: FileMode.append,
          flush: false,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('AppLogger: write failed: $e');
      }
    });
  }

  Future<void> _rotateIfNeeded(File current) async {
    try {
      if (!await current.exists()) {
        await current.create();
        return;
      }
      final size = await current.length();
      if (size < _maxFileBytes) return;
      final previous = File(p.join(current.parent.path, _previousFileName));
      if (await previous.exists()) {
        await previous.delete();
      }
      await current.rename(previous.path);
      await File(p.join(current.parent.path, _currentFileName)).create();
      _file = File(p.join(current.parent.path, _currentFileName));
    } catch (e) {
      if (kDebugMode) debugPrint('AppLogger: rotate failed: $e');
    }
  }

  Future<String> dumpAll() async {
    await _writeChain;
    final buf = StringBuffer();
    final file = _file;
    if (file != null) {
      final previous = File(p.join(file.parent.path, _previousFileName));
      if (await previous.exists()) {
        buf.write(await previous.readAsString());
      }
      if (await file.exists()) {
        buf.write(await file.readAsString());
      }
    } else {
      for (final entry in _buffer) {
        buf
          ..write(entry.format())
          ..write('\n');
      }
    }
    return buf.toString();
  }

  Future<void> clear() async {
    _buffer.clear();
    final file = _file;
    if (file != null) {
      _writeChain = _writeChain.then((_) async {
        try {
          final previous = File(p.join(file.parent.path, _previousFileName));
          if (await previous.exists()) await previous.delete();
          if (await file.exists()) {
            await file.writeAsString('', mode: FileMode.write, flush: true);
          }
        } catch (e) {
          if (kDebugMode) debugPrint('AppLogger: clear failed: $e');
        }
      });
      await _writeChain;
    }
    info('App', 'Logs cleared');
  }
}
