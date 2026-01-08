// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:example/bootstrap.dart';

import 'package:datum/datum.dart';

class CustomDatumLogger implements DatumLogger {
  @override
  final bool enabled;
  @override
  final bool colors;
  @override
  final LogLevel minimumLevel;
  @override
  final Map<String, LogSampler> samplers;
  @override
  final bool enablePerformanceLogging;
  @override
  final Duration performanceThreshold;

  CustomDatumLogger({
    this.enabled = true,
    this.colors = true,
    this.minimumLevel = LogLevel.info,
    this.samplers = const {},
    this.enablePerformanceLogging = false,
    this.performanceThreshold = const Duration(milliseconds: 100),
  });

  @override
  void log(LogEntry entry) {
    if (!enabled || entry.level.value < minimumLevel.value) {
      return;
    }

    // Check sampling rules
    final sampler = samplers[entry.category];
    if (sampler != null) {
      if (!sampler.shouldLog(entry)) {
        return;
      }
      sampler.recordLog(entry);
    }

    // Use talker for logging based on level
    final message = _formatEntry(entry);
    switch (entry.level) {
      case LogLevel.trace:
      case LogLevel.debug:
        talker.debug(message);
        break;
      case LogLevel.info:
        talker.info(message);
        break;
      case LogLevel.warn:
        talker.warning(message);
        break;
      case LogLevel.error:
      case LogLevel.fatal:
        talker.error(message, entry.stackTrace);
        break;
      case LogLevel.off:
        // Don't log
        break;
    }
  }

  @override
  void logPerformance({
    required String operation,
    required Duration duration,
    Map<String, dynamic>? metadata,
    String? operationId,
  }) {
    if (!enablePerformanceLogging) return;

    final entry = LogEntry.performance(
      operation: operation,
      duration: duration,
      metadata: metadata,
      operationId: operationId,
    );

    // Only log if duration exceeds threshold
    if (duration > performanceThreshold) {
      log(entry);
    }
  }

  @override
  void logSync({
    required LogLevel level,
    required String message,
    required String userId,
    String? entityId,
    int? itemCount,
    Map<String, dynamic>? metadata,
  }) {
    final entry = LogEntry.sync(
      level: level,
      message: message,
      userId: userId,
      entityId: entityId,
      itemCount: itemCount,
      metadata: metadata,
    );
    log(entry);
  }

  @override
  void debug(String message,
      {String? category, Map<String, dynamic>? metadata}) {
    if (enabled) talker.debug(message);
  }

  @override
  void error(String message, [StackTrace? stackTrace]) {
    if (enabled) talker.error(message, stackTrace);
  }

  @override
  void info(String message,
      {String? category, Map<String, dynamic>? metadata}) {
    if (enabled) talker.info(message);
  }

  @override
  void warn(String message,
      {String? category, Map<String, dynamic>? metadata}) {
    if (enabled) talker.warning(message);
  }

  @override
  void trace(String message,
      {String? category, Map<String, dynamic>? metadata}) {
    if (enabled) talker.debug('TRACE: $message');
  }

  @override
  CustomDatumLogger copyWith({
    bool? enabled,
    bool? colors,
    LogLevel? minimumLevel,
    Map<String, LogSampler>? samplers,
    bool? enablePerformanceLogging,
    Duration? performanceThreshold,
  }) {
    return CustomDatumLogger(
      enabled: enabled ?? this.enabled,
      colors: colors ?? this.colors,
      minimumLevel: minimumLevel ?? this.minimumLevel,
      samplers: samplers ?? this.samplers,
      enablePerformanceLogging:
          enablePerformanceLogging ?? this.enablePerformanceLogging,
      performanceThreshold: performanceThreshold ?? this.performanceThreshold,
    );
  }

  String _formatEntry(LogEntry entry) {
    final buffer = StringBuffer();
    buffer.write('[Datum ${entry.level.name.toUpperCase()}]');

    if (entry.category != null) {
      buffer.write('[${entry.category}]');
    }

    buffer.write(': ${entry.message}');

    if (entry.operationId != null) {
      buffer.write(' (op:${entry.operationId})');
    }

    if (entry.duration != null) {
      buffer.write(' (${entry.duration!.inMilliseconds}ms)');
    }

    return buffer.toString();
  }

  @override
  DatumLogger getWorkerLogger() => this;
}
