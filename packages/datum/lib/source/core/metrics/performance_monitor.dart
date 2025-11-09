import 'dart:async';
import 'dart:collection';

import 'package:datum/source/core/models/performance_metrics.dart';
import 'package:meta/meta.dart';

/// Service for monitoring performance metrics and detecting regressions.
class PerformanceMonitor {
  final PerformanceConfig config;
  final Map<String, PerformanceBaseline> _baselines = {};
  final Map<String, Queue<OperationTiming>> _recentTimings = {};
  final StreamController<PerformanceEvent> _eventController = StreamController.broadcast();

  /// Stream of performance events (regressions, anomalies, etc.)
  Stream<PerformanceEvent> get events => _eventController.stream;

  PerformanceMonitor(this.config);

  /// Records timing for an operation and checks for regressions.
  void recordTiming(OperationTiming timing) {
    if (!config.enabled || !config.shouldMonitor(timing.operationName)) {
      return;
    }

    // Store recent timing for baseline calculation
    _recentTimings.putIfAbsent(timing.operationName, () => Queue()).add(timing);

    // Maintain max samples limit
    final queue = _recentTimings[timing.operationName]!;
    while (queue.length > config.maxTimingSamples) {
      queue.removeFirst();
    }

    // Check for regressions BEFORE updating baseline
    if (config.detectRegressions) {
      final currentBaseline = _baselines[timing.operationName];
      if (currentBaseline != null) {
        final regressionLevel = currentBaseline.checkRegression(
          timing,
          threshold: config.regressionThreshold,
        );

        if (regressionLevel > 0) {
          _eventController.add(
            PerformanceRegressionEvent(
              operationName: timing.operationName,
              timing: timing,
              baseline: currentBaseline,
              severity: regressionLevel,
            ),
          );
        }
      }
    }

    // Update or create baseline AFTER checking for regression
    final baseline = _baselines[timing.operationName];
    if (baseline == null) {
      // Create initial baseline from recent timings
      final timings = _recentTimings[timing.operationName]!.toList();
      if (timings.length >= 5) {
        // Minimum samples for reliable baseline
        _baselines[timing.operationName] = PerformanceBaseline.fromTimings(
          timing.operationName,
          timings,
        );
      }
    } else {
      // Update existing baseline
      _baselines[timing.operationName] = baseline.updateWith(timing);
    }

    // Emit timing event for monitoring
    _eventController.add(
      OperationTimingEvent(
        timing: timing,
        baseline: _baselines[timing.operationName],
      ),
    );
  }

  /// Times an async operation and records the performance metrics.
  Future<T> timeAsync<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    if (!config.enabled || !config.shouldMonitor(operationName)) {
      return operation();
    }

    final startMemory = config.trackMemory ? MemoryUsage.current() : null;
    final stopwatch = Stopwatch()..start();

    try {
      final result = await operation();
      stopwatch.stop();
      final endMemory = config.trackMemory ? MemoryUsage.current() : null;

      final timing = OperationTiming.fromStopwatch(
        operationName,
        stopwatch,
        startMemory: startMemory,
        endMemory: endMemory,
      );

      recordTiming(timing);
      return result;
    } catch (e) {
      stopwatch.stop();
      final endMemory = config.trackMemory ? MemoryUsage.current() : null;

      final timing = OperationTiming.fromStopwatch(
        operationName,
        stopwatch,
        startMemory: startMemory,
        endMemory: endMemory,
      );

      recordTiming(timing);
      rethrow;
    }
  }

  /// Times a sync operation and records the performance metrics.
  T timeSync<T>(String operationName, T Function() operation) {
    if (!config.enabled || !config.shouldMonitor(operationName)) {
      return operation();
    }

    final startMemory = config.trackMemory ? MemoryUsage.current() : null;
    final stopwatch = Stopwatch()..start();

    try {
      final result = operation();
      stopwatch.stop();
      final endMemory = config.trackMemory ? MemoryUsage.current() : null;

      final timing = OperationTiming.fromStopwatch(
        operationName,
        stopwatch,
        startMemory: startMemory,
        endMemory: endMemory,
      );

      recordTiming(timing);
      return result;
    } catch (e) {
      stopwatch.stop();
      final endMemory = config.trackMemory ? MemoryUsage.current() : null;

      final timing = OperationTiming.fromStopwatch(
        operationName,
        stopwatch,
        startMemory: startMemory,
        endMemory: endMemory,
      );

      recordTiming(timing);
      rethrow;
    }
  }

  /// Gets the current performance baseline for an operation.
  PerformanceBaseline? getBaseline(String operationName) {
    return _baselines[operationName];
  }

  /// Gets all current baselines.
  Map<String, PerformanceBaseline> getAllBaselines() {
    return Map.unmodifiable(_baselines);
  }

  /// Gets recent timings for an operation.
  List<OperationTiming> getRecentTimings(String operationName, {int? limit}) {
    final queue = _recentTimings[operationName];
    if (queue == null) return [];

    final timings = queue.toList();
    if (limit != null && timings.length > limit) {
      return timings.sublist(timings.length - limit);
    }
    return timings;
  }

  /// Clears all stored performance data.
  void clear() {
    _baselines.clear();
    _recentTimings.clear();
  }

  /// Disposes of the performance monitor.
  void dispose() {
    _eventController.close();
  }
}

/// Base class for performance-related events.
@immutable
abstract class PerformanceEvent {
  const PerformanceEvent();
}

/// Event emitted when an operation is timed.
class OperationTimingEvent extends PerformanceEvent {
  final OperationTiming timing;
  final PerformanceBaseline? baseline;

  const OperationTimingEvent({
    required this.timing,
    this.baseline,
  });

  @override
  String toString() => 'OperationTimingEvent(${timing.operationName}: ${timing.duration.inMilliseconds}ms)';
}

/// Event emitted when a performance regression is detected.
class PerformanceRegressionEvent extends PerformanceEvent {
  final String operationName;
  final OperationTiming timing;
  final PerformanceBaseline baseline;
  final int severity; // 1 = mild, 2 = moderate, 3 = severe

  const PerformanceRegressionEvent({
    required this.operationName,
    required this.timing,
    required this.baseline,
    required this.severity,
  });

  String get severityDescription {
    switch (severity) {
      case 1:
        return 'mild';
      case 2:
        return 'moderate';
      case 3:
        return 'severe';
      default:
        return 'unknown';
    }
  }

  @override
  String toString() {
    return 'PerformanceRegressionEvent($operationName: $severityDescription regression, '
        '${timing.duration.inMilliseconds}ms vs baseline ${baseline.averageDuration.inMilliseconds}ms)';
  }
}
