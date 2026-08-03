import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/build_info.dart';
import '../config/env_config.dart';

/// Production-grade structured logger (Phase 5).
///
/// Features:
///   - Environment-driven log level filtering
///   - Sensitive data redaction (JWT, PIN, tokens, passwords)
///   - In-memory log ring buffer for export
///   - File-based log rotation with size cap
///   - Crash reporting integration (Sentry)
class AppLogger {
  static late final Logger _logger;
  static late final Level _minLevel;
  static late final String _environment;
  static bool _initialized = false;

  // ── In-memory ring buffer for diagnostics export ───────────────────────────
  static const int _maxBufferSize = 2000;
  static final Queue<String> _logBuffer = Queue<String>();

  // ── File logging ───────────────────────────────────────────────────────────
  static const int _maxLogFileSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const int _maxLogFiles = 3;
  static IOSink? _fileSink;
  static File? _currentLogFile;

  // ── Sensitive patterns to redact ───────────────────────────────────────────
  static final RegExp _sensitivePattern = RegExp(
    r'(eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,})'  // JWT
    r'|(\bpin[:\s="]+\d{4,6}\b)'                                          // PIN
    r'|(bearer\s+[A-Za-z0-9._~+/=-]+)'                                   // Bearer token
    r'|(password[:\s="]+\S+)'                                             // Password
    r'|(token[:\s="]+[A-Za-z0-9._~+/=-]{8,})'                            // Generic token
    r'|(secret[:\s="]+\S+)',                                              // Secret
    caseSensitive: false,
  );

  /// Initialize the logger for the given environment.
  /// Must be called once during bootstrap before any logging.
  static Future<void> init({required String environment}) async {
    if (_initialized) return;

    _environment = environment;
    _minLevel = _levelFromString(EnvConfig().logLevel);

    _logger = Logger(
      level: _minLevel,
      printer: kDebugMode
          ? PrettyPrinter(
              methodCount: 2,
              errorMethodCount: 8,
              lineLength: 120,
              colors: true,
              printEmojis: true,
            )
          : SimplePrinter(colors: false),
      filter: ProductionFilter(),
    );

    // Initialize file logging for non-debug builds
    if (!kDebugMode) {
      await _initFileLogging();
    }

    _initialized = true;

    info(
      'AppLogger initialized | env=$_environment '
      '| level=${EnvConfig().logLevel} '
      '| version=${BuildInfo.version}+${BuildInfo.buildNumber} '
      '| commit=${BuildInfo.gitCommit} '
      '| built=${BuildInfo.buildTimestamp}',
    );
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(Level.debug, message, error, stackTrace);
  }

  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(Level.info, message, error, stackTrace);
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(Level.warning, message, error, stackTrace);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(Level.error, message, error, stackTrace);

    // Forward to crash reporting for error-level and above
    if (EnvConfig().enableCrashReporting && error != null) {
      Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  // ── Log Export (Phase 5 / Phase 7) ─────────────────────────────────────────

  /// Returns the in-memory log buffer as a single string for diagnostics export.
  static String exportLogs() {
    return _logBuffer.join('\n');
  }

  /// Returns the number of buffered log entries.
  static int get bufferCount => _logBuffer.length;

  /// Clears the in-memory log buffer.
  static void clearBuffer() {
    _logBuffer.clear();
  }

  /// Returns the path to the current log file, or null if file logging is off.
  static String? get logFilePath => _currentLogFile?.path;

  // ── Internal ───────────────────────────────────────────────────────────────

  static void _log(
    Level level,
    String message,
    dynamic error,
    StackTrace? stackTrace,
  ) {
    if (!_initialized) {
      // Pre-init fallback
      // ignore: avoid_print
      print('[PRE-INIT] $message');
      return;
    }

    final sanitized = _redactSensitive(message);
    final timestamp = DateTime.now().toIso8601String();
    final entry = '[$timestamp] [${level.name.toUpperCase()}] $sanitized';

    // Buffer for diagnostics export
    _addToBuffer(entry);

    // File logging
    _writeToFile(entry);

    // Console logging
    switch (level) {
      case Level.debug:
        _logger.d(sanitized, error: error, stackTrace: stackTrace);
      case Level.info:
        _logger.i(sanitized, error: error, stackTrace: stackTrace);
      case Level.warning:
        _logger.w(sanitized, error: error, stackTrace: stackTrace);
      case Level.error:
        _logger.e(sanitized, error: error, stackTrace: stackTrace);
      default:
        _logger.i(sanitized, error: error, stackTrace: stackTrace);
    }
  }

  static String _redactSensitive(String message) {
    return message.replaceAll(_sensitivePattern, '[REDACTED]');
  }

  static void _addToBuffer(String entry) {
    _logBuffer.addLast(entry);
    while (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeFirst();
    }
  }

  static void _writeToFile(String entry) {
    _fileSink?.writeln(entry);
  }

  static Future<void> _initFileLogging() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${dir.path}/logs');
      if (!logDir.existsSync()) {
        logDir.createSync(recursive: true);
      }

      // Rotate logs if needed
      await _rotateLogsIfNeeded(logDir);

      final logFile = File(
        '${logDir.path}/etm_${DateTime.now().millisecondsSinceEpoch}.log',
      );
      _currentLogFile = logFile;
      _fileSink = logFile.openWrite(mode: FileMode.append);
    } catch (_) {
      // File logging is best-effort; do not crash the app
    }
  }

  static Future<void> _rotateLogsIfNeeded(Directory logDir) async {
    try {
      final files = logDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.log'))
          .toList()
        ..sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

      // Remove oldest files if exceeding max count
      while (files.length >= _maxLogFiles) {
        final oldest = files.removeAt(0);
        oldest.deleteSync();
      }

      // If current file exceeds size, it will naturally be replaced on next init
      for (final file in files) {
        if (file.lengthSync() > _maxLogFileSizeBytes) {
          file.deleteSync();
        }
      }
    } catch (_) {
      // Best-effort rotation
    }
  }

  static Level _levelFromString(String level) {
    switch (level.toLowerCase()) {
      case 'debug':
        return Level.debug;
      case 'info':
        return Level.info;
      case 'warning':
        return Level.warning;
      case 'error':
        return Level.error;
      default:
        return Level.info;
    }
  }

  /// Flush file sink. Call on app lifecycle pause.
  static Future<void> flush() async {
    await _fileSink?.flush();
  }

  /// Close file sink. Call on app dispose.
  static Future<void> dispose() async {
    await _fileSink?.flush();
    await _fileSink?.close();
    _fileSink = null;
  }
}
