import 'dart:async';
import 'dart:isolate';

import 'package:datum/datum.dart';

/// Message type for cross-isolate logging communication.
class _LogMessage {
  final LogEntry entry;

  const _LogMessage(this.entry);
}

/// Main isolate logger that receives log messages from worker isolates.
/// This logger runs in the main isolate and forwards messages to a delegate logger.
class IsolateLogger implements DatumLogger {
  final DatumLogger _delegate;
  final ReceivePort _receivePort;
  final StreamSubscription<dynamic>? _subscription;
  final Map<String, SendPort> _workerPorts = {};

  IsolateLogger(this._delegate)
      : _receivePort = ReceivePort(),
        _subscription = null {
    // Start listening for messages from worker isolates
    _receivePort.listen(_handleMessage);
  }

  /// Creates a worker logger for use in background isolates.
  /// Returns a logger that can send messages back to this main isolate logger.
  IsolateWorkerLogger createWorkerLogger() {
    final workerLogger = IsolateWorkerLogger(_receivePort.sendPort);
    return workerLogger;
  }

  /// Registers a worker isolate's send port for direct communication.
  void registerWorkerPort(String workerId, SendPort sendPort) {
    _workerPorts[workerId] = sendPort;
  }

  /// Unregisters a worker isolate's send port.
  void unregisterWorkerPort(String workerId) {
    _workerPorts.remove(workerId);
  }

  void _handleMessage(dynamic message) {
    if (message is _LogMessage) {
      // Forward the log entry to the delegate logger
      _delegate.log(message.entry);
    }
  }

  @override
  bool get enabled => _delegate.enabled;

  @override
  bool get colors => _delegate.colors;

  @override
  LogLevel get minimumLevel => _delegate.minimumLevel;

  @override
  Map<String, LogSampler> get samplers => _delegate.samplers;

  @override
  bool get enablePerformanceLogging => _delegate.enablePerformanceLogging;

  @override
  Duration get performanceThreshold => _delegate.performanceThreshold;

  @override
  void log(LogEntry entry) {
    // Log directly in main isolate
    _delegate.log(entry);
  }

  @override
  void logPerformance({
    required String operation,
    required Duration duration,
    Map<String, dynamic>? metadata,
    String? operationId,
  }) {
    _delegate.logPerformance(
      operation: operation,
      duration: duration,
      metadata: metadata,
      operationId: operationId,
    );
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
    _delegate.logSync(
      level: level,
      message: message,
      userId: userId,
      entityId: entityId,
      itemCount: itemCount,
      metadata: metadata,
    );
  }

  @override
  void debug(String message,
      {String? category, Map<String, dynamic>? metadata}) {
    _delegate.debug(message, category: category, metadata: metadata);
  }

  @override
  void error(String message, [StackTrace? stackTrace]) {
    _delegate.error(message, stackTrace);
  }

  @override
  void info(String message,
      {String? category, Map<String, dynamic>? metadata}) {
    _delegate.info(message, category: category, metadata: metadata);
  }

  @override
  void warn(String message,
      {String? category, Map<String, dynamic>? metadata}) {
    _delegate.warn(message, category: category, metadata: metadata);
  }

  @override
  void trace(String message,
      {String? category, Map<String, dynamic>? metadata}) {
    _delegate.trace(message, category: category, metadata: metadata);
  }

  @override
  IsolateLogger copyWith({
    bool? enabled,
    bool? colors,
    LogLevel? minimumLevel,
    Map<String, LogSampler>? samplers,
    bool? enablePerformanceLogging,
    Duration? performanceThreshold,
  }) {
    return IsolateLogger(
      _delegate.copyWith(
        enabled: enabled,
        colors: colors,
        minimumLevel: minimumLevel,
        samplers: samplers,
        enablePerformanceLogging: enablePerformanceLogging,
        performanceThreshold: performanceThreshold,
      ),
    );
  }

  @override
  DatumLogger getWorkerLogger() {
    return createWorkerLogger();
  }

  /// Disposes the logger and closes the receive port.
  void dispose() {
    _subscription?.cancel();
    _receivePort.close();
    _workerPorts.clear();
  }
}

/// Worker isolate logger that sends log messages to the main isolate.
/// This logger runs in background isolates and communicates with the main isolate.
class IsolateWorkerLogger implements DatumLogger {
  final SendPort _mainSendPort;

  IsolateWorkerLogger(this._mainSendPort);

  @override
  DatumLogger getWorkerLogger() => this;

  @override
  bool get enabled =>
      true; // Always enabled - filtering happens in main isolate

  @override
  bool get colors => false; // Colors handled in main isolate

  @override
  LogLevel get minimumLevel =>
      LogLevel.trace; // All levels sent to main isolate

  @override
  Map<String, LogSampler> get samplers =>
      {}; // Sampling handled in main isolate

  @override
  bool get enablePerformanceLogging =>
      true; // Performance logging handled in main isolate

  @override
  Duration get performanceThreshold =>
      Duration.zero; // Threshold handled in main isolate

  @override
  void log(LogEntry entry) {
    // Send the log entry to the main isolate
    final message = _LogMessage(entry);
    _mainSendPort.send(message);
  }

  @override
  void logPerformance({
    required String operation,
    required Duration duration,
    Map<String, dynamic>? metadata,
    String? operationId,
  }) {
    final entry = LogEntry.performance(
      operation: operation,
      duration: duration,
      metadata: metadata,
      operationId: operationId,
    );
    log(entry);
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
    log(LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.debug,
      message: message,
      category: category,
      metadata: metadata,
    ));
  }

  @override
  void error(String message, [StackTrace? stackTrace]) {
    log(LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.error,
      message: message,
      stackTrace: stackTrace,
    ));
  }

  @override
  void info(String message,
      {String? category, Map<String, dynamic>? metadata}) {
    log(LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.info,
      message: message,
      category: category,
      metadata: metadata,
    ));
  }

  @override
  void warn(String message,
      {String? category, Map<String, dynamic>? metadata}) {
    log(LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.warn,
      message: message,
      category: category,
      metadata: metadata,
    ));
  }

  @override
  void trace(String message,
      {String? category, Map<String, dynamic>? metadata}) {
    log(LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.trace,
      message: message,
      category: category,
      metadata: metadata,
    ));
  }

  @override
  IsolateWorkerLogger copyWith({
    bool? enabled,
    bool? colors,
    LogLevel? minimumLevel,
    Map<String, LogSampler>? samplers,
    bool? enablePerformanceLogging,
    Duration? performanceThreshold,
  }) {
    // Worker logger configuration is handled in main isolate
    // Return a new instance with same send port
    return IsolateWorkerLogger(_mainSendPort);
  }
}
