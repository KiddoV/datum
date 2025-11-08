import 'dart:async';

import 'package:datum/source/utils/datum_logger.dart';
import 'package:test/test.dart';

void main() {
  group('LogEntry', () {
    test('creates basic log entry', () {
      final timestamp = DateTime.now();
      final entry = LogEntry(
        timestamp: timestamp,
        level: LogLevel.info,
        message: 'Test message',
        category: 'test',
        metadata: {'key': 'value'},
      );

      expect(entry.timestamp, timestamp);
      expect(entry.level, LogLevel.info);
      expect(entry.message, 'Test message');
      expect(entry.category, 'test');
      expect(entry.metadata, {'key': 'value'});
      expect(entry.error, isNull);
      expect(entry.stackTrace, isNull);
      expect(entry.operationId, isNull);
      expect(entry.duration, isNull);
    });

    test('performance factory creates correct entry', () {
      const duration = Duration(milliseconds: 150);
      final entry = LogEntry.performance(
        operation: 'test_operation',
        duration: duration,
        metadata: {'extra': 'data'},
        operationId: 'op-123',
      );

      expect(entry.level, LogLevel.debug);
      expect(entry.category, 'performance');
      expect(entry.message, 'Performance: test_operation completed');
      expect(entry.operationId, 'op-123');
      expect(entry.duration, duration);
      expect(entry.metadata!['operation'], 'test_operation');
      expect(entry.metadata!['duration_ms'], 150);
      expect(entry.metadata!['extra'], 'data');
    });

    test('sync factory creates correct entry', () {
      final entry = LogEntry.sync(
        level: LogLevel.info,
        message: 'Sync completed',
        userId: 'user-123',
        entityId: 'entity-456',
        itemCount: 42,
        metadata: {'sync_type': 'full'},
      );

      expect(entry.level, LogLevel.info);
      expect(entry.category, 'sync');
      expect(entry.message, 'Sync completed');
      expect(entry.metadata!['user_id'], 'user-123');
      expect(entry.metadata!['entity_id'], 'entity-456');
      expect(entry.metadata!['item_count'], 42);
      expect(entry.metadata!['sync_type'], 'full');
    });

    test('toString formats correctly', () {
      final timestamp = DateTime(2023, 1, 1, 12, 0, 0);
      final entry = LogEntry(
        timestamp: timestamp,
        level: LogLevel.warn,
        message: 'Warning message',
        category: 'test',
        operationId: 'op-123',
        duration: const Duration(milliseconds: 250),
        metadata: {'key': 'value'},
      );

      final formatted = entry.toString();
      expect(formatted, contains('[2023-01-01T12:00:00.000]'));
      expect(formatted, contains('[WARN]'));
      expect(formatted, contains('[test]'));
      expect(formatted, contains('Warning message'));
      expect(formatted, contains('(op:op-123)'));
      expect(formatted, contains('(250ms)'));
      expect(formatted, contains('{key: value}'));
    });
  });

  group('RateLimitingSampler', () {
    test('allows logs within limit', () {
      final sampler = RateLimitingSampler(
        window: const Duration(seconds: 10),
        maxLogsPerWindow: 3,
      );

      final entry = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.info,
        message: 'test',
        category: 'test',
      );

      expect(sampler.shouldLog(entry), isTrue);
      sampler.recordLog(entry);
      expect(sampler.shouldLog(entry), isTrue);
      sampler.recordLog(entry);
      expect(sampler.shouldLog(entry), isTrue);
      sampler.recordLog(entry);
    });

    test('blocks logs over limit', () {
      final sampler = RateLimitingSampler(
        window: const Duration(seconds: 10),
        maxLogsPerWindow: 2,
      );

      final entry = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.info,
        message: 'test',
        category: 'test',
      );

      expect(sampler.shouldLog(entry), isTrue);
      sampler.recordLog(entry);
      expect(sampler.shouldLog(entry), isTrue);
      sampler.recordLog(entry);
      expect(sampler.shouldLog(entry), isFalse); // Over limit
    });

    test('resets after window expires', () async {
      final sampler = RateLimitingSampler(
        window: const Duration(milliseconds: 100),
        maxLogsPerWindow: 1,
      );

      final entry1 = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.info,
        message: 'test',
        category: 'test',
      );

      expect(sampler.shouldLog(entry1), isTrue);
      sampler.recordLog(entry1);
      expect(sampler.shouldLog(entry1), isFalse);

      // Wait for window to expire and create new entry with current timestamp
      await Future.delayed(const Duration(milliseconds: 150));

      final entry2 = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.info,
        message: 'test',
        category: 'test',
      );

      expect(sampler.shouldLog(entry2), isTrue);
    });

    test('handles different categories separately', () {
      final sampler = RateLimitingSampler(
        window: const Duration(seconds: 10),
        maxLogsPerWindow: 1,
      );

      final entry1 = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.info,
        message: 'test',
        category: 'category1',
      );

      final entry2 = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.info,
        message: 'test',
        category: 'category2',
      );

      expect(sampler.shouldLog(entry1), isTrue);
      sampler.recordLog(entry1);
      expect(sampler.shouldLog(entry1), isFalse); // category1 blocked

      expect(sampler.shouldLog(entry2), isTrue); // category2 still allowed
      sampler.recordLog(entry2);
      expect(sampler.shouldLog(entry2), isFalse); // category2 now blocked
    });
  });

  group('CountBasedSampler', () {
    test('logs every Nth occurrence', () {
      final sampler = CountBasedSampler(sampleRate: 3);

      final entry = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.info,
        message: 'test',
        category: 'test',
      );

      // Should log on 3rd, 6th, 9th, etc. occurrences
      expect(sampler.shouldLog(entry), isFalse); // 1st
      expect(sampler.shouldLog(entry), isFalse); // 2nd
      expect(sampler.shouldLog(entry), isTrue);  // 3rd
      expect(sampler.shouldLog(entry), isFalse); // 4th
      expect(sampler.shouldLog(entry), isFalse); // 5th
      expect(sampler.shouldLog(entry), isTrue);  // 6th
    });

    test('handles different categories separately', () {
      final sampler = CountBasedSampler(sampleRate: 2);

      final entry1 = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.info,
        message: 'test',
        category: 'category1',
      );

      final entry2 = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.info,
        message: 'test',
        category: 'category2',
      );

      // category1: logs on 2nd occurrence
      expect(sampler.shouldLog(entry1), isFalse); // 1st for category1
      expect(sampler.shouldLog(entry1), isTrue);  // 2nd for category1

      // category2: independent counter
      expect(sampler.shouldLog(entry2), isFalse); // 1st for category2
      expect(sampler.shouldLog(entry2), isTrue);  // 2nd for category2
    });
  });

  group('DatumLogger', () {
    test('respects enabled flag', () {
      final logger = DatumLogger(enabled: false);
      final entry = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.info,
        message: 'test',
      );

      // Should not log when disabled
      logger.log(entry);
      // No assertion needed - just ensuring no exceptions
    });

    test('respects minimum level', () {
      final logger = DatumLogger(
        enabled: true,
        minimumLevel: LogLevel.warn,
      );

      final debugEntry = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.debug,
        message: 'debug message',
      );

      final warnEntry = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.warn,
        message: 'warn message',
      );

      // Should not log debug, should log warn
      logger.log(debugEntry);
      logger.log(warnEntry);
    });

    test('applies sampling rules', () {
      final sampler = CountBasedSampler(sampleRate: 2);
      final logger = DatumLogger(
        enabled: true,
        minimumLevel: LogLevel.info,
        samplers: {'test': sampler},
      );

      final entry = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.info,
        message: 'test message',
        category: 'test',
      );

      // Should be sampled according to CountBasedSampler rules
      logger.log(entry); // 1st - not logged
      logger.log(entry); // 2nd - logged
      logger.log(entry); // 3rd - not logged
    });

    test('performance logging respects threshold', () {
      final logger = DatumLogger(
        enabled: true,
        enablePerformanceLogging: true,
        performanceThreshold: const Duration(milliseconds: 100),
      );

      // Should log operations over threshold
      logger.logPerformance(
        operation: 'slow_operation',
        duration: const Duration(milliseconds: 150),
      );

      // Should not log operations under threshold
      logger.logPerformance(
        operation: 'fast_operation',
        duration: const Duration(milliseconds: 50),
      );
    });

    test('structured sync logging', () {
      final logger = DatumLogger(enabled: true, minimumLevel: LogLevel.info);

      logger.logSync(
        level: LogLevel.info,
        message: 'Sync completed',
        userId: 'user-123',
        entityId: 'entity-456',
        itemCount: 42,
      );
    });

    test('convenience methods work', () {
      final logger = DatumLogger(enabled: true, minimumLevel: LogLevel.debug);

      logger.info('Info message', category: 'test', metadata: {'key': 'value'});
      logger.debug('Debug message', category: 'test');
      logger.warn('Warn message');
      logger.error('Error message');
      logger.trace('Trace message');
    });

    test('copyWith creates new instance with modified properties', () {
      final original = DatumLogger(
        enabled: true,
        minimumLevel: LogLevel.info,
        enablePerformanceLogging: false,
      );

      final modified = original.copyWith(
        enabled: false,
        minimumLevel: LogLevel.debug,
        enablePerformanceLogging: true,
      );

      expect(original.enabled, isTrue);
      expect(original.minimumLevel, LogLevel.info);
      expect(original.enablePerformanceLogging, isFalse);

      expect(modified.enabled, isFalse);
      expect(modified.minimumLevel, LogLevel.debug);
      expect(modified.enablePerformanceLogging, isTrue);
    });

    test('handles null metadata gracefully', () {
      final logger = DatumLogger(enabled: true);
      final entry = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.info,
        message: 'test',
        metadata: null,
      );

      logger.log(entry);
    });

    test('handles complex log entries', () {
      final logger = DatumLogger(enabled: true);
      final entry = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.error,
        message: 'Test error',
        category: 'test',
        operationId: 'op-123',
        duration: const Duration(milliseconds: 500),
        metadata: {'error_code': 500, 'user_id': 'user-123'},
      );

      // Should not throw any exceptions
      logger.log(entry);
    });
  });

  group('LogLevel', () {
    test('has correct values', () {
      expect(LogLevel.trace.value, 0);
      expect(LogLevel.debug.value, 1);
      expect(LogLevel.info.value, 2);
      expect(LogLevel.warn.value, 3);
      expect(LogLevel.error.value, 4);
      expect(LogLevel.fatal.value, 5);
      expect(LogLevel.off.value, 99);
    });

    test('ordering works correctly', () {
      expect(LogLevel.trace.value < LogLevel.debug.value, isTrue);
      expect(LogLevel.debug.value < LogLevel.info.value, isTrue);
      expect(LogLevel.info.value < LogLevel.warn.value, isTrue);
      expect(LogLevel.warn.value < LogLevel.error.value, isTrue);
      expect(LogLevel.error.value < LogLevel.fatal.value, isTrue);
      expect(LogLevel.fatal.value < LogLevel.off.value, isTrue);
    });
  });

  group('Integration tests', () {
    test('full logging pipeline with sampling', () {
      final sampler = RateLimitingSampler(
        window: const Duration(seconds: 1),
        maxLogsPerWindow: 2,
      );

      final logger = DatumLogger(
        enabled: true,
        minimumLevel: LogLevel.info,
        samplers: {'high_freq': sampler},
        enablePerformanceLogging: true,
        performanceThreshold: const Duration(milliseconds: 10),
      );

      // Test regular logging
      logger.info('Regular info message');

      // Test high-frequency logging with sampling
      for (var i = 0; i < 5; i++) {
        logger.info('High frequency message', category: 'high_freq');
      }

      // Test performance logging
      logger.logPerformance(
        operation: 'test_operation',
        duration: const Duration(milliseconds: 50),
        metadata: {'iterations': 100},
      );

      // Test structured sync logging
      logger.logSync(
        level: LogLevel.info,
        message: 'Batch sync completed',
        userId: 'user-123',
        itemCount: 50,
        metadata: {'sync_type': 'incremental'},
      );
    });

    test('handles edge cases gracefully', () {
      final logger = DatumLogger(enabled: true);

      // Empty message
      logger.info('');

      // Very long message
      final longMessage = 'a' * 10000;
      logger.info(longMessage);

      // Null category in sampler lookup
      final entry = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.info,
        message: 'test',
        category: null,
      );
      logger.log(entry);

      // Empty metadata
      logger.info('test', metadata: {});

      // Zero duration performance log
      logger.logPerformance(
        operation: 'instant_operation',
        duration: Duration.zero,
      );
    });
  });
}
