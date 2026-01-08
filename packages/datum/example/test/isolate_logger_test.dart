import 'package:datum/source/utils/datum_logger.dart';
import 'package:example/isolate_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IsolateLogger', () {
    late IsolateLogger mainLogger;
    late DatumLogger delegateLogger;

    setUp(() {
      // Create a simple test logger that collects messages
      delegateLogger = TestLogger();
      mainLogger = IsolateLogger(delegateLogger);
    });

    tearDown(() {
      mainLogger.dispose();
    });

    test('logs messages in main isolate', () {
      mainLogger.info('Test message from main isolate');

      final testLogger = delegateLogger as TestLogger;
      expect(testLogger.messages.length, 1);
      expect(
          testLogger.messages[0], contains('Test message from main isolate'));
    });

    test('creates worker logger', () {
      final workerLogger = mainLogger.createWorkerLogger();

      expect(workerLogger, isA<IsolateWorkerLogger>());
    });

    test('worker logger sends messages to main isolate', () async {
      final workerLogger = mainLogger.createWorkerLogger();

      // Send a message from worker logger
      workerLogger.info('Test message from worker isolate');

      // Wait a bit for the message to be processed
      await Future.delayed(const Duration(milliseconds: 100));

      final testLogger = delegateLogger as TestLogger;
      expect(testLogger.messages.length, 1);
      expect(
          testLogger.messages[0], contains('Test message from worker isolate'));
    });

    test('handles multiple worker loggers', () async {
      final workerLogger1 = mainLogger.createWorkerLogger();
      final workerLogger2 = mainLogger.createWorkerLogger();

      workerLogger1.info('Message from worker 1');
      workerLogger2.debug('Message from worker 2');

      // Wait for messages to be processed
      await Future.delayed(const Duration(milliseconds: 100));

      final testLogger = delegateLogger as TestLogger;
      expect(testLogger.messages.length, 2);
      expect(
          testLogger.messages
              .any((msg) => msg.contains('Message from worker 1')),
          isTrue);
      expect(
          testLogger.messages
              .any((msg) => msg.contains('Message from worker 2')),
          isTrue);
    });
  });
}

/// Simple test logger that collects messages
class TestLogger implements DatumLogger {
  final List<String> messages = [];

  @override
  bool get enabled => true;

  @override
  bool get colors => false;

  @override
  LogLevel get minimumLevel => LogLevel.trace;

  @override
  Map<String, LogSampler> get samplers => {};

  @override
  bool get enablePerformanceLogging => false;

  @override
  Duration get performanceThreshold => Duration.zero;

  @override
  void log(LogEntry entry) {
    messages.add(entry.toString());
  }

  @override
  void logPerformance({
    required String operation,
    required Duration duration,
    Map<String, dynamic>? metadata,
    String? operationId,
  }) {}

  @override
  void logSync({
    required LogLevel level,
    required String message,
    required String userId,
    String? entityId,
    int? itemCount,
    Map<String, dynamic>? metadata,
  }) {}

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
  TestLogger copyWith({
    bool? enabled,
    bool? colors,
    LogLevel? minimumLevel,
    Map<String, LogSampler>? samplers,
    bool? enablePerformanceLogging,
    Duration? performanceThreshold,
  }) {
    return TestLogger();
  }

  @override
  DatumLogger getWorkerLogger() => this;
}
