import 'package:datum/source/core/metrics/performance_monitor.dart';
import 'package:datum/source/core/models/performance_metrics.dart';
import 'package:test/test.dart';

void main() {
  group('PerformanceMonitor', () {
    late PerformanceMonitor monitor;

    setUp(() {
      monitor = PerformanceMonitor(
        const PerformanceConfig.monitorAll(),
      );
    });

    tearDown(() {
      monitor.dispose();
    });

    test('records operation timing', () async {
      final timing = OperationTiming(
        operationName: 'test_operation',
        startTime: DateTime.now().subtract(const Duration(milliseconds: 100)),
        endTime: DateTime.now(),
        duration: const Duration(milliseconds: 100),
      );

      monitor.recordTiming(timing);

      final recentTimings = monitor.getRecentTimings('test_operation');
      expect(recentTimings.length, 1);
      expect(recentTimings.first.operationName, 'test_operation');
      expect(recentTimings.first.duration.inMilliseconds, 100);
    });

    test('times async operations', () async {
      final result = await monitor.timeAsync('async_test', () async {
        await Future.delayed(const Duration(milliseconds: 50));
        return 'success';
      });

      expect(result, 'success');

      final timings = monitor.getRecentTimings('async_test');
      expect(timings.length, 1);
      expect(timings.first.duration.inMilliseconds, greaterThanOrEqualTo(50));
    });

    test('times sync operations', () {
      final result = monitor.timeSync('sync_test', () {
        // Simulate some work
        var sum = 0;
        for (var i = 0; i < 1000; i++) {
          sum += i;
        }
        return sum;
      });

      expect(result, 499500); // Sum of 0 to 999

      final timings = monitor.getRecentTimings('sync_test');
      expect(timings.length, 1);
      expect(timings.first.duration.inMicroseconds, greaterThan(0));
    });

    test('creates performance baseline after sufficient samples', () {
      // Record multiple timings to establish a baseline
      for (var i = 0; i < 10; i++) {
        final timing = OperationTiming(
          operationName: 'baseline_test',
          startTime: DateTime.now().subtract(const Duration(milliseconds: 100)),
          endTime: DateTime.now(),
          duration: const Duration(milliseconds: 100),
        );
        monitor.recordTiming(timing);
      }

      final baseline = monitor.getBaseline('baseline_test');
      expect(baseline, isNotNull);
      expect(baseline!.sampleCount, 10);
      expect(baseline.averageDuration.inMilliseconds, 100);
    });

    test('detects performance regression', () async {
      // Establish baseline with normal performance
      for (var i = 0; i < 10; i++) {
        final timing = OperationTiming(
          operationName: 'regression_test',
          startTime: DateTime.now().subtract(const Duration(milliseconds: 100)),
          endTime: DateTime.now(),
          duration: const Duration(milliseconds: 100),
        );
        monitor.recordTiming(timing);
      }

      // Verify baseline was created
      final baseline = monitor.getBaseline('regression_test');
      expect(baseline, isNotNull);
      expect(baseline!.sampleCount, 10);

      // Record a significantly slower operation
      final slowTiming = OperationTiming(
        operationName: 'regression_test',
        startTime: DateTime.now().subtract(const Duration(milliseconds: 500)),
        endTime: DateTime.now(),
        duration: const Duration(milliseconds: 500), // 5x slower
      );

      var regressionDetected = false;
      final subscription = monitor.events.listen((event) {
        if (event is PerformanceRegressionEvent) {
          regressionDetected = true;
          expect(event.operationName, 'regression_test');
          expect(event.severity, greaterThan(0));
        }
      });

      monitor.recordTiming(slowTiming);

      // Wait for async event processing
      await Future.delayed(const Duration(milliseconds: 10));
      expect(regressionDetected, isTrue);
      subscription.cancel();
    });

    test('respects operation filtering', () {
      final filteredMonitor = PerformanceMonitor(
        const PerformanceConfig(
          enabled: true,
          monitoredOperations: {'allowed_operation'},
        ),
      );

      final allowedTiming = OperationTiming(
        operationName: 'allowed_operation',
        startTime: DateTime.now().subtract(const Duration(milliseconds: 100)),
        endTime: DateTime.now(),
        duration: const Duration(milliseconds: 100),
      );

      final blockedTiming = OperationTiming(
        operationName: 'blocked_operation',
        startTime: DateTime.now().subtract(const Duration(milliseconds: 100)),
        endTime: DateTime.now(),
        duration: const Duration(milliseconds: 100),
      );

      filteredMonitor.recordTiming(allowedTiming);
      filteredMonitor.recordTiming(blockedTiming);

      expect(filteredMonitor.getRecentTimings('allowed_operation').length, 1);
      expect(filteredMonitor.getRecentTimings('blocked_operation').length, 0);

      filteredMonitor.dispose();
    });

    test('respects disabled configuration', () async {
      final disabledMonitor = PerformanceMonitor(
        const PerformanceConfig(enabled: false),
      );

      final result = await disabledMonitor.timeAsync('disabled_test', () async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 'result';
      });

      expect(result, 'result');
      expect(disabledMonitor.getRecentTimings('disabled_test').length, 0);

      disabledMonitor.dispose();
    });

    test('limits stored timing samples', () {
      final limitedMonitor = PerformanceMonitor(
        const PerformanceConfig(
          enabled: true,
          maxTimingSamples: 3,
        ),
      );

      // Add 5 timings
      for (var i = 0; i < 5; i++) {
        final timing = OperationTiming(
          operationName: 'limited_test',
          startTime: DateTime.now().subtract(const Duration(milliseconds: 100)),
          endTime: DateTime.now(),
          duration: const Duration(milliseconds: 100),
        );
        limitedMonitor.recordTiming(timing);
      }

      final timings = limitedMonitor.getRecentTimings('limited_test');
      expect(timings.length, 3); // Should be limited to maxTimingSamples

      limitedMonitor.dispose();
    });

    test('handles exceptions in timed operations', () async {
      var timingRecorded = false;
      final subscription = monitor.events.listen((event) {
        if (event is OperationTimingEvent) {
          timingRecorded = true;
          expect(event.timing.operationName, 'exception_test');
        }
      });

      // Test async operation that throws
      await expectLater(
        monitor.timeAsync('exception_test', () async {
          await Future.delayed(const Duration(milliseconds: 10));
          throw Exception('Test exception');
        }),
        throwsException,
      );

      // Wait for async event processing
      await Future.delayed(const Duration(milliseconds: 10));
      expect(timingRecorded, isTrue);

      subscription.cancel();
    });

    test('handles exceptions in sync timed operations', () {
      var timingRecorded = false;
      final subscription = monitor.events.listen((event) {
        if (event is OperationTimingEvent) {
          timingRecorded = true;
          expect(event.timing.operationName, 'sync_exception_test');
        }
      });

      // Test sync operation that throws
      expect(
        () => monitor.timeSync('sync_exception_test', () {
          throw Exception('Test sync exception');
        }),
        throwsException,
      );

      // Wait for async event processing
      Future.delayed(const Duration(milliseconds: 10)).then((_) {
        expect(timingRecorded, isTrue);
        subscription.cancel();
      });
    });

    test('getRecentTimings respects limit parameter', () {
      // Add multiple timings
      for (var i = 0; i < 10; i++) {
        final timing = OperationTiming(
          operationName: 'limit_test',
          startTime: DateTime.now().subtract(const Duration(milliseconds: 100)),
          endTime: DateTime.now(),
          duration: const Duration(milliseconds: 100),
        );
        monitor.recordTiming(timing);
      }

      final allTimings = monitor.getRecentTimings('limit_test');
      expect(allTimings.length, 10);

      final limitedTimings = monitor.getRecentTimings('limit_test', limit: 5);
      expect(limitedTimings.length, 5);

      // Should return the most recent ones
      expect(limitedTimings, equals(allTimings.sublist(5)));
    });

    test('getRecentTimings returns empty list for unknown operation', () {
      final timings = monitor.getRecentTimings('unknown_operation');
      expect(timings, isEmpty);
    });

    test('getRecentTimings with limit larger than available returns all', () {
      // Add 3 timings
      for (var i = 0; i < 3; i++) {
        final timing = OperationTiming(
          operationName: 'small_limit_test',
          startTime: DateTime.now().subtract(const Duration(milliseconds: 100)),
          endTime: DateTime.now(),
          duration: const Duration(milliseconds: 100),
        );
        monitor.recordTiming(timing);
      }

      final timings = monitor.getRecentTimings('small_limit_test', limit: 10);
      expect(timings.length, 3); // Should return all available
    });
  });

  group('OperationTiming Creation', () {
    test('creates timing from stopwatch', () {
      final stopwatch = Stopwatch()..start();
      Future.delayed(const Duration(milliseconds: 10)).then((_) {
        stopwatch.stop();
      });

      return Future.delayed(const Duration(milliseconds: 20)).then((_) {
        final timing = OperationTiming.fromStopwatch('test', stopwatch);

        expect(timing.operationName, 'test');
        expect(timing.duration, stopwatch.elapsed);
        expect(timing.endTime.difference(timing.startTime), timing.duration);
      });
    });

    test('calculates memory delta correctly', () {
      const startMemory = MemoryUsage(
        heapUsage: 1000,
        peakHeapUsage: 1500,
        externalUsage: 200,
        heapSize: 2000,
        rss: 3000,
      );

      const endMemory = MemoryUsage(
        heapUsage: 1200,
        peakHeapUsage: 1600,
        externalUsage: 250,
        heapSize: 2100,
        rss: 3100,
      );

      final timing = OperationTiming(
        operationName: 'memory_test',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        duration: const Duration(milliseconds: 100),
        startMemory: startMemory,
        endMemory: endMemory,
      );

      expect(timing.memoryDelta, isNotNull);
      expect(timing.memoryDelta!.heapUsage, 200); // 1200 - 1000
      expect(timing.memoryDelta!.externalUsage, 50); // 250 - 200
    });
  });

  group('PerformanceBaseline', () {
    test('creates baseline from timings', () {
      final timings = [
        OperationTiming(
          operationName: 'baseline_test',
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          duration: const Duration(milliseconds: 100),
        ),
        OperationTiming(
          operationName: 'baseline_test',
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          duration: const Duration(milliseconds: 120),
        ),
      ];

      final baseline = PerformanceBaseline.fromTimings('baseline_test', timings);

      expect(baseline.operationName, 'baseline_test');
      expect(baseline.sampleCount, 2);
      expect(baseline.averageDuration.inMilliseconds, 110); // Average of 100 and 120
    });

    test('updates baseline with new timing', () {
      final initialBaseline = PerformanceBaseline(
        operationName: 'update_test',
        averageDuration: const Duration(milliseconds: 100),
        stdDevDuration: const Duration(milliseconds: 10),
        averageMemoryDelta: 1000,
        stdDevMemoryDelta: 100,
        sampleCount: 10,
        lastUpdated: DateTime.now(),
      );

      final newTiming = OperationTiming(
        operationName: 'update_test',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        duration: const Duration(milliseconds: 110),
        startMemory: MemoryUsage.current(),
        endMemory: MemoryUsage.current(),
      );

      final updatedBaseline = initialBaseline.updateWith(newTiming);

      expect(updatedBaseline.sampleCount, 11);
      // With 10 samples at 100ms and 1 at 110ms, average should be ~100.9ms
      expect(updatedBaseline.averageDuration.inMilliseconds, closeTo(101, 1));
    });

    test('checks for regression correctly', () {
      final baseline = PerformanceBaseline(
        operationName: 'regression_check',
        averageDuration: const Duration(milliseconds: 100),
        stdDevDuration: const Duration(milliseconds: 5),
        averageMemoryDelta: 1000,
        stdDevMemoryDelta: 50,
        sampleCount: 20,
        lastUpdated: DateTime.now(),
      );

      // Normal performance - no regression
      final normalTiming = OperationTiming(
        operationName: 'regression_check',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        duration: const Duration(milliseconds: 105), // Within 1 std dev
      );

      expect(baseline.checkRegression(normalTiming), 0);

      // Significant regression - should be detected
      final slowTiming = OperationTiming(
        operationName: 'regression_check',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        duration: const Duration(milliseconds: 200), // Way above baseline
      );

      final regressionLevel = baseline.checkRegression(slowTiming);
      expect(regressionLevel, greaterThan(0));
      expect(regressionLevel, 3); // Severe regression
    });

    test('toString formats baseline information correctly', () {
      final baseline = PerformanceBaseline(
        operationName: 'test_operation',
        averageDuration: const Duration(milliseconds: 150),
        stdDevDuration: const Duration(milliseconds: 25),
        averageMemoryDelta: 2048, // 2 KB
        stdDevMemoryDelta: 512, // 0.5 KB
        sampleCount: 42,
        lastUpdated: DateTime(2023, 1, 1, 12, 0, 0),
      );

      final result = baseline.toString();
      expect(result, contains('PerformanceBaseline(test_operation:'));
      expect(result, contains('avg=150ms±25ms'));
      expect(result, contains('mem=2.0KB±0.5KB'));
      expect(result, contains('samples=42'));
    });

    test('props returns correct equality properties', () {
      final baseline1 = PerformanceBaseline(
        operationName: 'test',
        averageDuration: const Duration(milliseconds: 100),
        stdDevDuration: const Duration(milliseconds: 10),
        averageMemoryDelta: 1000,
        stdDevMemoryDelta: 100,
        sampleCount: 10,
        lastUpdated: DateTime(2023, 1, 1),
      );

      final baseline2 = PerformanceBaseline(
        operationName: 'test',
        averageDuration: const Duration(milliseconds: 100),
        stdDevDuration: const Duration(milliseconds: 10),
        averageMemoryDelta: 1000,
        stdDevMemoryDelta: 100,
        sampleCount: 10,
        lastUpdated: DateTime(2023, 1, 1),
      );

      final baseline3 = PerformanceBaseline(
        operationName: 'different',
        averageDuration: const Duration(milliseconds: 100),
        stdDevDuration: const Duration(milliseconds: 10),
        averageMemoryDelta: 1000,
        stdDevMemoryDelta: 100,
        sampleCount: 10,
        lastUpdated: DateTime(2023, 1, 1),
      );

      expect(baseline1.props, equals(baseline2.props));
      expect(baseline1.props, isNot(equals(baseline3.props)));
      expect(baseline1.props.length, 7); // All fields should be included
    });

    test('checkRegression calculates memory Z-score correctly', () {
      final baseline = PerformanceBaseline(
        operationName: 'memory_zscore_test',
        averageDuration: const Duration(milliseconds: 100),
        stdDevDuration: const Duration(milliseconds: 10),
        averageMemoryDelta: 1000, // 1000 bytes average
        stdDevMemoryDelta: 100, // 100 bytes std dev
        sampleCount: 20,
        lastUpdated: DateTime.now(),
      );

      // Test with memory data - should calculate Z-score
      const startMemory = MemoryUsage(
        heapUsage: 1000,
        peakHeapUsage: 1500,
        externalUsage: 200,
        heapSize: 2000,
        rss: 3000,
      );

      const endMemory = MemoryUsage(
        heapUsage: 1200, // 200 bytes increase
        peakHeapUsage: 1600,
        externalUsage: 250,
        heapSize: 2100,
        rss: 3100,
      );

      final timingWithMemory = OperationTiming(
        operationName: 'memory_zscore_test',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        duration: const Duration(milliseconds: 100), // Normal duration
        startMemory: startMemory,
        endMemory: endMemory,
      );

      // Z-score = (200 - 1000) / 100 = (-800) / 100 = -8.0
      // Since we take abs, it should be 8.0
      final regressionLevel = baseline.checkRegression(timingWithMemory);
      expect(regressionLevel, 3); // Severe regression due to high memory Z-score
    });

    test('checkRegression ignores memory when no memory data available', () {
      final baseline = PerformanceBaseline(
        operationName: 'no_memory_test',
        averageDuration: const Duration(milliseconds: 100),
        stdDevDuration: const Duration(milliseconds: 10),
        averageMemoryDelta: 1000,
        stdDevMemoryDelta: 100,
        sampleCount: 20,
        lastUpdated: DateTime.now(),
      );

      // Test without memory data - should only use duration
      final timingNoMemory = OperationTiming(
        operationName: 'no_memory_test',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        duration: const Duration(milliseconds: 100), // Normal duration
      );

      final regressionLevel = baseline.checkRegression(timingNoMemory);
      expect(regressionLevel, 0); // No regression
    });

    test('checkRegression uses maximum Z-score from duration and memory', () {
      final baseline = PerformanceBaseline(
        operationName: 'max_zscore_test',
        averageDuration: const Duration(milliseconds: 100),
        stdDevDuration: const Duration(milliseconds: 10), // Low variance
        averageMemoryDelta: 1000,
        stdDevMemoryDelta: 100, // Low variance
        sampleCount: 20,
        lastUpdated: DateTime.now(),
      );

      // Create timing with both high duration and high memory usage
      const startMemory = MemoryUsage(
        heapUsage: 1000,
        peakHeapUsage: 1500,
        externalUsage: 200,
        heapSize: 2000,
        rss: 3000,
      );

      const endMemory = MemoryUsage(
        heapUsage: 1100, // Only 100 bytes increase (normal)
        peakHeapUsage: 1600,
        externalUsage: 250,
        heapSize: 2100,
        rss: 3100,
      );

      final timing = OperationTiming(
        operationName: 'max_zscore_test',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        duration: const Duration(milliseconds: 130), // 3 std devs from mean (100 + 3*10 = 130)
        startMemory: startMemory,
        endMemory: endMemory,
      );

      final regressionLevel = baseline.checkRegression(timing);
      expect(regressionLevel, 3); // Severe regression (memory Z-score = 9.0 > duration Z-score = 3.0)
    });

    test('fromTimings sets lastUpdated to current time', () {
      final timings = [
        OperationTiming(
          operationName: 'last_updated_test',
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          duration: const Duration(milliseconds: 100),
        ),
      ];

      final beforeCreation = DateTime.now();
      final baseline = PerformanceBaseline.fromTimings('last_updated_test', timings);
      final afterCreation = DateTime.now();

      expect(baseline.lastUpdated.isAfter(beforeCreation.subtract(const Duration(seconds: 1))), isTrue);
      expect(baseline.lastUpdated.isBefore(afterCreation.add(const Duration(seconds: 1))), isTrue);
    });

    test('updateWith sets lastUpdated to current time', () {
      final baseline = PerformanceBaseline(
        operationName: 'update_last_updated_test',
        averageDuration: const Duration(milliseconds: 100),
        stdDevDuration: const Duration(milliseconds: 10),
        averageMemoryDelta: 1000,
        stdDevMemoryDelta: 100,
        sampleCount: 10,
        lastUpdated: DateTime(2023, 1, 1), // Old date
      );

      final timing = OperationTiming(
        operationName: 'update_last_updated_test',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        duration: const Duration(milliseconds: 110),
      );

      final beforeUpdate = DateTime.now();
      final updatedBaseline = baseline.updateWith(timing);
      final afterUpdate = DateTime.now();

      expect(updatedBaseline.lastUpdated.isAfter(beforeUpdate.subtract(const Duration(seconds: 1))), isTrue);
      expect(updatedBaseline.lastUpdated.isBefore(afterUpdate.add(const Duration(seconds: 1))), isTrue);
      expect(updatedBaseline.lastUpdated, isNot(equals(baseline.lastUpdated)));
    });
  });

  group('MemoryUsage', () {
    test('toString formats memory information correctly', () {
      const memory = MemoryUsage(
        heapUsage: 1024 * 1024, // 1 MB
        peakHeapUsage: 2 * 1024 * 1024, // 2 MB
        externalUsage: 512 * 1024, // 512 KB = 0.5 MB
        heapSize: 3 * 1024 * 1024, // 3 MB
        rss: 4 * 1024 * 1024, // 4 MB
      );

      final result = memory.toString();
      expect(result, contains('MemoryUsage('));
      expect(result, contains('heap: 1.00 MB'));
      expect(result, contains('peak: 2.00 MB'));
      expect(result, contains('external: 0.50 MB'));
      expect(result, contains('size: 3.00 MB'));
      expect(result, contains('rss: 4.00 MB'));
    });

    test('props returns correct equality properties', () {
      const memory1 = MemoryUsage(
        heapUsage: 1000,
        peakHeapUsage: 1500,
        externalUsage: 200,
        heapSize: 2000,
        rss: 3000,
      );

      const memory2 = MemoryUsage(
        heapUsage: 1000,
        peakHeapUsage: 1500,
        externalUsage: 200,
        heapSize: 2000,
        rss: 3000,
      );

      const memory3 = MemoryUsage(
        heapUsage: 1001,
        peakHeapUsage: 1500,
        externalUsage: 200,
        heapSize: 2000,
        rss: 3000,
      );

      expect(memory1.props, equals(memory2.props));
      expect(memory1.props, isNot(equals(memory3.props)));
      expect(memory1.props.length, 5); // All fields should be included
    });

    test('difference calculates correct deltas', () {
      const memory1 = MemoryUsage(
        heapUsage: 1000,
        peakHeapUsage: 1500,
        externalUsage: 200,
        heapSize: 2000,
        rss: 3000,
      );

      const memory2 = MemoryUsage(
        heapUsage: 1200,
        peakHeapUsage: 1600,
        externalUsage: 250,
        heapSize: 2100,
        rss: 3100,
      );

      final diff = memory2.difference(memory1);

      expect(diff.heapUsage, 200);
      expect(diff.peakHeapUsage, 100);
      expect(diff.externalUsage, 50);
      expect(diff.heapSize, 100);
      expect(diff.rss, 100);
    });
  });

  group('OperationTiming', () {
    test('toString formats timing information correctly', () {
      const startMemory = MemoryUsage(
        heapUsage: 1000,
        peakHeapUsage: 1500,
        externalUsage: 200,
        heapSize: 2000,
        rss: 3000,
      );

      const endMemory = MemoryUsage(
        heapUsage: 1200,
        peakHeapUsage: 1600,
        externalUsage: 250,
        heapSize: 2100,
        rss: 3100,
      );

      final timing = OperationTiming(
        operationName: 'test_operation',
        startTime: DateTime(2023, 1, 1, 12, 0, 0),
        endTime: DateTime(2023, 1, 1, 12, 0, 0, 0, 150), // 150ms later
        duration: const Duration(milliseconds: 150),
        startMemory: startMemory,
        endMemory: endMemory,
      );

      final result = timing.toString();
      expect(result, contains('OperationTiming(test_operation: 150ms'));
      expect(result, contains('memory: +0.2 KB'));
    });

    test('toString handles timing without memory data', () {
      final timing = OperationTiming(
        operationName: 'simple_operation',
        startTime: DateTime(2023, 1, 1, 12, 0, 0),
        endTime: DateTime(2023, 1, 1, 12, 0, 0, 0, 100), // 100ms later
        duration: const Duration(milliseconds: 100),
      );

      final result = timing.toString();
      expect(result, contains('OperationTiming(simple_operation: 100ms'));
      expect(result, isNot(contains('memory:')));
    });

    test('props returns correct equality properties', () {
      final timing1 = OperationTiming(
        operationName: 'test',
        startTime: DateTime(2023, 1, 1, 12, 0, 0),
        endTime: DateTime(2023, 1, 1, 12, 0, 0, 0, 100),
        duration: const Duration(milliseconds: 100),
        startMemory: MemoryUsage.current(),
        endMemory: MemoryUsage.current(),
      );

      final timing2 = OperationTiming(
        operationName: 'test',
        startTime: DateTime(2023, 1, 1, 12, 0, 0),
        endTime: DateTime(2023, 1, 1, 12, 0, 0, 0, 100),
        duration: const Duration(milliseconds: 100),
        startMemory: MemoryUsage.current(),
        endMemory: MemoryUsage.current(),
      );

      final timing3 = OperationTiming(
        operationName: 'different',
        startTime: DateTime(2023, 1, 1, 12, 0, 0),
        endTime: DateTime(2023, 1, 1, 12, 0, 0, 0, 100),
        duration: const Duration(milliseconds: 100),
      );

      expect(timing1.props, equals(timing2.props));
      expect(timing1.props, isNot(equals(timing3.props)));
      expect(timing1.props.length, 6); // All fields should be included
    });

    test('memoryDelta calculates difference correctly', () {
      const startMemory = MemoryUsage(
        heapUsage: 1000,
        peakHeapUsage: 1500,
        externalUsage: 200,
        heapSize: 2000,
        rss: 3000,
      );

      const endMemory = MemoryUsage(
        heapUsage: 1200,
        peakHeapUsage: 1600,
        externalUsage: 250,
        heapSize: 2100,
        rss: 3100,
      );

      final timing = OperationTiming(
        operationName: 'memory_test',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        duration: const Duration(milliseconds: 100),
        startMemory: startMemory,
        endMemory: endMemory,
      );

      expect(timing.memoryDelta, isNotNull);
      expect(timing.memoryDelta!.heapUsage, 200);
      expect(timing.memoryDelta!.externalUsage, 50);
    });

    test('memoryDelta returns null when memory data is missing', () {
      final timing = OperationTiming(
        operationName: 'no_memory_test',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        duration: const Duration(milliseconds: 100),
      );

      expect(timing.memoryDelta, isNull);
    });

    test('fromStopwatch creates timing with memory tracking', () async {
      final stopwatch = Stopwatch()..start();
      await Future.delayed(const Duration(milliseconds: 10));
      stopwatch.stop();

      const startMemory = MemoryUsage(
        heapUsage: 1000,
        peakHeapUsage: 1500,
        externalUsage: 200,
        heapSize: 2000,
        rss: 3000,
      );

      const endMemory = MemoryUsage(
        heapUsage: 1200,
        peakHeapUsage: 1600,
        externalUsage: 250,
        heapSize: 2100,
        rss: 3100,
      );

      final timing = OperationTiming.fromStopwatch(
        'memory_test',
        stopwatch,
        startMemory: startMemory,
        endMemory: endMemory,
      );

      expect(timing.operationName, 'memory_test');
      expect(timing.duration, stopwatch.elapsed);
      expect(timing.startMemory, startMemory);
      expect(timing.endMemory, endMemory);
      expect(timing.memoryDelta, isNotNull);
      expect(timing.memoryDelta!.heapUsage, 200);
    });

    test('fromStopwatch creates timing without memory tracking', () async {
      final stopwatch = Stopwatch()..start();
      await Future.delayed(const Duration(milliseconds: 10));
      stopwatch.stop();

      final timing = OperationTiming.fromStopwatch('simple_test', stopwatch);

      expect(timing.operationName, 'simple_test');
      expect(timing.duration, stopwatch.elapsed);
      expect(timing.startMemory, isNull);
      expect(timing.endMemory, isNull);
      expect(timing.memoryDelta, isNull);
    });
  });

  group('PerformanceMonitor Utility Methods', () {
    late PerformanceMonitor monitor;

    setUp(() {
      monitor = PerformanceMonitor(
        const PerformanceConfig.monitorAll(),
      );
    });

    tearDown(() {
      monitor.dispose();
    });

    test('clear removes all stored performance data', () {
      // Add some data
      final timing = OperationTiming(
        operationName: 'test_operation',
        startTime: DateTime.now().subtract(const Duration(milliseconds: 100)),
        endTime: DateTime.now(),
        duration: const Duration(milliseconds: 100),
      );

      monitor.recordTiming(timing);

      // Create baseline by adding multiple timings
      for (var i = 0; i < 10; i++) {
        monitor.recordTiming(timing);
      }

      // Verify data exists
      expect(monitor.getRecentTimings('test_operation').length, greaterThan(0));
      expect(monitor.getBaseline('test_operation'), isNotNull);

      // Clear all data
      monitor.clear();

      // Verify data is cleared
      expect(monitor.getRecentTimings('test_operation').length, 0);
      expect(monitor.getBaseline('test_operation'), isNull);
    });
  });

  group('Performance Events', () {
    test('OperationTimingEvent toString formats correctly', () {
      final timing = OperationTiming(
        operationName: 'event_test',
        startTime: DateTime(2023, 1, 1, 12, 0, 0),
        endTime: DateTime(2023, 1, 1, 12, 0, 0, 0, 150),
        duration: const Duration(milliseconds: 150),
      );

      final event = OperationTimingEvent(timing: timing);

      final result = event.toString();
      expect(result, contains('OperationTimingEvent(event_test: 150ms'));
    });

    test('PerformanceRegressionEvent severityDescription returns correct descriptions', () {
      final baseline = PerformanceBaseline(
        operationName: 'severity_test',
        averageDuration: const Duration(milliseconds: 100),
        stdDevDuration: const Duration(milliseconds: 10),
        averageMemoryDelta: 1000,
        stdDevMemoryDelta: 100,
        sampleCount: 20,
        lastUpdated: DateTime.now(),
      );

      final timing = OperationTiming(
        operationName: 'severity_test',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        duration: const Duration(milliseconds: 200), // Severe regression
      );

      final event = PerformanceRegressionEvent(
        operationName: 'severity_test',
        timing: timing,
        baseline: baseline,
        severity: 3,
      );

      expect(event.severityDescription, 'severe');

      // Test all severity levels
      final mildEvent = PerformanceRegressionEvent(
        operationName: 'severity_test',
        timing: timing,
        baseline: baseline,
        severity: 1,
      );
      expect(mildEvent.severityDescription, 'mild');

      final moderateEvent = PerformanceRegressionEvent(
        operationName: 'severity_test',
        timing: timing,
        baseline: baseline,
        severity: 2,
      );
      expect(moderateEvent.severityDescription, 'moderate');

      final unknownEvent = PerformanceRegressionEvent(
        operationName: 'severity_test',
        timing: timing,
        baseline: baseline,
        severity: 99,
      );
      expect(unknownEvent.severityDescription, 'unknown');
    });

    test('PerformanceRegressionEvent toString formats correctly', () {
      final baseline = PerformanceBaseline(
        operationName: 'regression_display_test',
        averageDuration: const Duration(milliseconds: 100),
        stdDevDuration: const Duration(milliseconds: 10),
        averageMemoryDelta: 1000,
        stdDevMemoryDelta: 100,
        sampleCount: 20,
        lastUpdated: DateTime.now(),
      );

      final timing = OperationTiming(
        operationName: 'regression_display_test',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        duration: const Duration(milliseconds: 200),
      );

      final event = PerformanceRegressionEvent(
        operationName: 'regression_display_test',
        timing: timing,
        baseline: baseline,
        severity: 3,
      );

      final result = event.toString();
      expect(result, contains('PerformanceRegressionEvent(regression_display_test: severe regression'));
      expect(result, contains('200ms vs baseline 100ms'));
    });
  });

  group('PerformanceConfig', () {
    test('props returns correct equality properties', () {
      const config1 = PerformanceConfig(
        enabled: true,
        trackMemory: true,
        trackOperationTimings: true,
        detectRegressions: true,
        regressionThreshold: 2.0,
        maxTimingSamples: 100,
        monitoredOperations: {'op1', 'op2'},
      );

      const config2 = PerformanceConfig(
        enabled: true,
        trackMemory: true,
        trackOperationTimings: true,
        detectRegressions: true,
        regressionThreshold: 2.0,
        maxTimingSamples: 100,
        monitoredOperations: {'op1', 'op2'},
      );

      const config3 = PerformanceConfig(
        enabled: false, // Different
        trackMemory: true,
        trackOperationTimings: true,
        detectRegressions: true,
        regressionThreshold: 2.0,
        maxTimingSamples: 100,
        monitoredOperations: {'op1', 'op2'},
      );

      expect(config1.props, equals(config2.props));
      expect(config1.props, isNot(equals(config3.props)));
      expect(config1.props.length, 7); // All fields should be included
    });

    test('monitorAll creates config with empty monitored operations', () {
      const config = PerformanceConfig.monitorAll();

      expect(config.enabled, isTrue);
      expect(config.trackMemory, isTrue);
      expect(config.trackOperationTimings, isTrue);
      expect(config.detectRegressions, isTrue);
      expect(config.regressionThreshold, 2.0);
      expect(config.maxTimingSamples, 100);
      expect(config.monitoredOperations, isEmpty);
    });

    test('shouldMonitor returns true for empty monitored operations', () {
      const config = PerformanceConfig.monitorAll();

      expect(config.shouldMonitor('any_operation'), isTrue);
    });

    test('shouldMonitor returns true for operations in monitored set', () {
      const config = PerformanceConfig(
        monitoredOperations: {'allowed_op', 'another_op'},
      );

      expect(config.shouldMonitor('allowed_op'), isTrue);
      expect(config.shouldMonitor('another_op'), isTrue);
    });

    test('shouldMonitor returns false for operations not in monitored set', () {
      const config = PerformanceConfig(
        monitoredOperations: {'allowed_op'},
      );

      expect(config.shouldMonitor('blocked_op'), isFalse);
      expect(config.shouldMonitor('another_blocked'), isFalse);
    });
  });
}
