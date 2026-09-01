import 'dart:async';

enum LogLevel { info, warning, error }

class DebugLog {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  DebugLog(this.timestamp, this.level, this.message);
}

class DebugLogService {
  static final DebugLogService _instance = DebugLogService._internal();
  factory DebugLogService() => _instance;
  DebugLogService._internal();

  final List<DebugLog> _logs = [];
  final StreamController<DebugLog> _logStream =
      StreamController<DebugLog>.broadcast();

  List<DebugLog> get logs => List.unmodifiable(_logs);
  Stream<DebugLog> get logStream => _logStream.stream;

  void log(String message, {LogLevel level = LogLevel.info}) {
    final entry = DebugLog(DateTime.now(), level, message);
    _logs.add(entry);
    if (_logs.length > 1000) {
      _logs.removeAt(0);
    }
    _logStream.add(entry);
  }

  void info(String message) => log(message, level: LogLevel.info);
  void warning(String message) => log(message, level: LogLevel.warning);
  void error(String message) => log(message, level: LogLevel.error);

  String getAllLogsAsString() {
    final buffer = StringBuffer();
    for (final entry in _logs) {
      final time =
          '${entry.timestamp.hour}:${entry.timestamp.minute}:${entry.timestamp.second}';
      final level = entry.level.toString().split('.').last.toUpperCase();
      buffer.writeln('[$time] [$level] ${entry.message}');
    }
    return buffer.toString();
  }

  void clear() {
    _logs.clear();
  }

  void dispose() {
    _logStream.close();
  }
}