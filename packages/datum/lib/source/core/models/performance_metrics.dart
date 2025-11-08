import 'dart:math' as math;
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Represents memory usage information for performance monitoring.
@immutable
class MemoryUsage extends Equatable {
  /// Current heap usage in bytes.
  final int heapUsage;

  /// Peak heap usage in bytes during the operation.
  final int peakHeapUsage;

  /// External heap usage in bytes.
  final int externalUsage;

  /// Total heap size in bytes.
  final int heapSize;

  /// RSS (Resident Set Size) in bytes.
  final int rss;

  const MemoryUsage({
    required this.heapUsage,
    required this.peakHeapUsage,
    required this.externalUsage,
    required this.heapSize,
    required this.rss,
  });

  /// Creates a MemoryUsage snapshot from current VM metrics.
  /// Note: This is a simplified implementation. For production use,
  /// consider using platform-specific APIs or the observatory service.
  factory MemoryUsage.current() {
    // Simplified memory monitoring - in a real implementation,
    // you would use platform-specific APIs or the VM service
    return const MemoryUsage(
      heapUsage: 0,
      peakHeapUsage: 0,
      externalUsage: 0,
      heapSize: 0,
      rss: 0,
    );
  }

  /// Calculates the difference between two memory usage snapshots.
  MemoryUsage difference(MemoryUsage other) {
    return MemoryUsage(
      heapUsage: heapUsage - other.heapUsage,
      peakHeapUsage: peakHeapUsage - other.peakHeapUsage,
      externalUsage: externalUsage - other.externalUsage,
      heapSize: heapSize - other.heapSize,
      rss: rss - other.rss,
    );
  }

  @override
  List<Object?> get props => [heapUsage, peakHeapUsage, externalUsage, heapSize, rss];

  @override
  String toString() {
    return 'MemoryUsage('
        'heap: ${(heapUsage / 1024 / 1024).toStringAsFixed(2)} MB, '
        'peak: ${(peakHeapUsage / 1024 / 1024).toStringAsFixed(2)} MB, '
        'external: ${(externalUsage / 1024 / 1024).toStringAsFixed(2)} MB, '
        'size: ${(heapSize / 1024 / 1024).toStringAsFixed(2)} MB, '
        'rss: ${(rss / 1024 / 1024).toStringAsFixed(2)} MB'
        ')';
  }
}

/// Represents timing information for an operation.
@immutable
class OperationTiming extends Equatable {
  /// The name of the operation being timed.
  final String operationName;

  /// Start time of the operation.
  final DateTime startTime;

  /// End time of the operation.
  final DateTime endTime;

  /// Duration of the operation.
  final Duration duration;

  /// Memory usage at the start of the operation.
  final MemoryUsage? startMemory;

  /// Memory usage at the end of the operation.
  final MemoryUsage? endMemory;

  /// Memory usage delta during the operation.
  MemoryUsage? get memoryDelta =>
      startMemory != null && endMemory != null
          ? endMemory!.difference(startMemory!)
          : null;

  const OperationTiming({
    required this.operationName,
    required this.startTime,
    required this.endTime,
    required this.duration,
    this.startMemory,
    this.endMemory,
  });

  /// Creates an OperationTiming from a stopwatch.
  factory OperationTiming.fromStopwatch(
    String operationName,
    Stopwatch stopwatch, {
    MemoryUsage? startMemory,
    MemoryUsage? endMemory,
  }) {
    final endTime = DateTime.now();
    final startTime = endTime.subtract(stopwatch.elapsed);
    return OperationTiming(
      operationName: operationName,
      startTime: startTime,
      endTime: endTime,
      duration: stopwatch.elapsed,
      startMemory: startMemory,
      endMemory: endMemory,
    );
  }

  @override
  List<Object?> get props => [
        operationName,
        startTime,
        endTime,
        duration,
        startMemory,
        endMemory,
      ];

  @override
  String toString() {
    final memInfo = memoryDelta != null
        ? ', memory: ${memoryDelta!.heapUsage > 0 ? '+' : ''}${(memoryDelta!.heapUsage / 1024).toStringAsFixed(1)} KB'
        : '';
    return 'OperationTiming($operationName: ${duration.inMilliseconds}ms$memInfo)';
  }
}

/// Performance baseline for detecting regressions.
@immutable
class PerformanceBaseline extends Equatable {
  /// Operation name this baseline applies to.
  final String operationName;

  /// Average duration for this operation.
  final Duration averageDuration;

  /// Standard deviation of durations.
  final Duration stdDevDuration;

  /// Average memory usage delta.
  final int averageMemoryDelta;

  /// Standard deviation of memory usage.
  final int stdDevMemoryDelta;

  /// Number of samples used to calculate this baseline.
  final int sampleCount;

  /// Last updated timestamp.
  final DateTime lastUpdated;

  const PerformanceBaseline({
    required this.operationName,
    required this.averageDuration,
    required this.stdDevDuration,
    required this.averageMemoryDelta,
    required this.stdDevMemoryDelta,
    required this.sampleCount,
    required this.lastUpdated,
  });

  /// Creates a baseline from a list of timings.
  factory PerformanceBaseline.fromTimings(
    String operationName,
    List<OperationTiming> timings,
  ) {
    if (timings.isEmpty) {
      return PerformanceBaseline(
        operationName: operationName,
        averageDuration: Duration.zero,
        stdDevDuration: Duration.zero,
        averageMemoryDelta: 0,
        stdDevMemoryDelta: 0,
        sampleCount: 0,
        lastUpdated: DateTime.now(),
      );
    }

    final durations = timings.map((t) => t.duration.inMicroseconds).toList();
    final avgDurationMicros = durations.reduce((a, b) => a + b) / durations.length;
    final variance = durations.map((d) => (d - avgDurationMicros) * (d - avgDurationMicros)).reduce((a, b) => a + b) / durations.length;
    final stdDevDurationMicros = variance == 0 ? 0 : math.sqrt(variance);

    final memoryDeltas = timings
        .where((t) => t.memoryDelta != null)
        .map((t) => t.memoryDelta!.heapUsage)
        .toList();

    final avgMemoryDelta = memoryDeltas.isEmpty ? 0 : memoryDeltas.reduce((a, b) => a + b) ~/ memoryDeltas.length;
    final memoryVariance = memoryDeltas.isEmpty ? 0 :
        memoryDeltas.map((d) => (d - avgMemoryDelta) * (d - avgMemoryDelta)).reduce((a, b) => a + b) / memoryDeltas.length;
    final stdDevMemory = memoryVariance == 0 ? 0 : math.sqrt(memoryVariance);

    return PerformanceBaseline(
      operationName: operationName,
      averageDuration: Duration(microseconds: avgDurationMicros.round()),
      stdDevDuration: Duration(microseconds: stdDevDurationMicros.round()),
      averageMemoryDelta: avgMemoryDelta,
      stdDevMemoryDelta: stdDevMemory.round(),
      sampleCount: timings.length,
      lastUpdated: DateTime.now(),
    );
  }

  /// Updates this baseline with new timing data.
  PerformanceBaseline updateWith(OperationTiming timing) {
    final newSampleCount = sampleCount + 1;
    final currentAvgDuration = averageDuration.inMicroseconds;
    final newAvgDuration = ((currentAvgDuration * sampleCount) + timing.duration.inMicroseconds) / newSampleCount;

    final currentAvgMemory = averageMemoryDelta;
    final timingMemory = timing.memoryDelta?.heapUsage ?? 0;
    final newAvgMemory = ((currentAvgMemory * sampleCount) + timingMemory) ~/ newSampleCount;

    // Simplified variance calculation for updating
    final durationDiff = timing.duration.inMicroseconds - newAvgDuration;
    final newStdDevDuration = Duration(
      microseconds: ((stdDevDuration.inMicroseconds * sampleCount) + (durationDiff * durationDiff)) ~/ newSampleCount,
    );

    final memoryDiff = timingMemory - newAvgMemory;
    final newStdDevMemory = ((stdDevMemoryDelta * sampleCount) + (memoryDiff * memoryDiff)) ~/ newSampleCount;

    return PerformanceBaseline(
      operationName: operationName,
      averageDuration: Duration(microseconds: newAvgDuration.round()),
      stdDevDuration: newStdDevDuration,
      averageMemoryDelta: newAvgMemory,
      stdDevMemoryDelta: newStdDevMemory,
      sampleCount: newSampleCount,
      lastUpdated: DateTime.now(),
    );
  }

  /// Checks if a timing represents a performance regression.
  /// Returns the severity level (0 = no regression, higher = more severe).
  int checkRegression(OperationTiming timing, {double threshold = 2.0}) {
    if (sampleCount < 5) return 0; // Not enough samples for reliable baseline

    final durationZScore = (timing.duration.inMicroseconds - averageDuration.inMicroseconds) /
        (stdDevDuration.inMicroseconds == 0 ? 1 : stdDevDuration.inMicroseconds);

    // Only consider memory if we have memory data in the timing
    double? memoryZScore;
    if (timing.memoryDelta != null) {
      final memoryDelta = timing.memoryDelta!.heapUsage;
      memoryZScore = (memoryDelta - averageMemoryDelta) /
          (stdDevMemoryDelta == 0 ? 1 : stdDevMemoryDelta);
    }

    // Use the maximum z-score from available metrics
    final zScores = [durationZScore.abs()];
    if (memoryZScore != null) {
      zScores.add(memoryZScore.abs());
    }
    final maxZScore = zScores.reduce((a, b) => a > b ? a : b);

    if (maxZScore >= threshold * 3) return 3; // Severe regression
    if (maxZScore >= threshold * 2) return 2; // Moderate regression
    if (maxZScore >= threshold) return 1; // Mild regression

    return 0; // No regression
  }

  @override
  List<Object?> get props => [
        operationName,
        averageDuration,
        stdDevDuration,
        averageMemoryDelta,
        stdDevMemoryDelta,
        sampleCount,
        lastUpdated,
      ];

  @override
  String toString() {
    return 'PerformanceBaseline($operationName: '
        'avg=${averageDuration.inMilliseconds}ms±${stdDevDuration.inMilliseconds}ms, '
        'mem=${(averageMemoryDelta / 1024).toStringAsFixed(1)}KB±${(stdDevMemoryDelta / 1024).toStringAsFixed(1)}KB, '
        'samples=$sampleCount)';
  }
}

/// Performance monitoring configuration.
@immutable
class PerformanceConfig extends Equatable {
  /// Whether performance monitoring is enabled.
  final bool enabled;

  /// Whether memory tracking is enabled.
  final bool trackMemory;

  /// Whether to track detailed operation timings.
  final bool trackOperationTimings;

  /// Whether to detect performance regressions.
  final bool detectRegressions;

  /// Threshold for regression detection (in standard deviations).
  final double regressionThreshold;

  /// Maximum number of timing samples to keep for baseline calculation.
  final int maxTimingSamples;

  /// Operations to monitor (empty means monitor all).
  final Set<String> monitoredOperations;

  const PerformanceConfig({
    this.enabled = true,
    this.trackMemory = true,
    this.trackOperationTimings = true,
    this.detectRegressions = true,
    this.regressionThreshold = 2.0,
    this.maxTimingSamples = 100,
    this.monitoredOperations = const {},
  });

  /// Creates a config that monitors all operations.
  const PerformanceConfig.monitorAll({
    this.enabled = true,
    this.trackMemory = true,
    this.trackOperationTimings = true,
    this.detectRegressions = true,
    this.regressionThreshold = 2.0,
    this.maxTimingSamples = 100,
  }) : monitoredOperations = const {};

  /// Checks if a specific operation should be monitored.
  bool shouldMonitor(String operationName) {
    return monitoredOperations.isEmpty || monitoredOperations.contains(operationName);
  }

  @override
  List<Object?> get props => [
        enabled,
        trackMemory,
        trackOperationTimings,
        detectRegressions,
        regressionThreshold,
        maxTimingSamples,
        monitoredOperations,
      ];
}
