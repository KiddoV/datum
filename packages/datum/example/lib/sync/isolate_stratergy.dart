import 'package:datum/source/core/models/datum_entity.dart';
import 'package:datum/source/core/models/datum_sync_operation.dart';
import 'package:datum/source/core/sync/datum_sync_execution_strategy.dart';

import '_isolate_runner_io.dart';

class IsolateStrategy implements DatumSyncExecutionStrategy {
  /// Creates a strategy that wraps another strategy to run it in a background
  /// isolate.
  ///
  /// For example: `IsolateStrategy(SequentialStrategy())` will run the
  /// sequential sync process in a background isolate.
  const IsolateStrategy(
    this.wrappedStrategy, {
    this.forceIsolateInTest = false,
  });

  /// The underlying strategy (e.g., sequential or parallel) to be executed
  /// in the background isolate.
  final DatumSyncExecutionStrategy wrappedStrategy;

  /// When running in a test environment (`isTest` is true), this flag can be
  /// set to `true` to force the creation of a real isolate. This is useful
  /// for integration tests that need to verify the isolate communication logic.
  /// Defaults to `false`.
  final bool forceIsolateInTest;

  @override
  Future<void> execute<T extends DatumEntityInterface>(
    List<DatumSyncOperation<T>> operations,
    Future<void> Function(DatumSyncOperation<T> operation) processOperation,
    bool Function() isCancelled,
    void Function(int completed, int total) onProgress,
  ) {
    if (!forceIsolateInTest) {
      // In a test environment (and not forced), run the wrapped strategy
      // directly on the main thread to simplify testing.
      return wrappedStrategy.execute<T>(
        operations,
        processOperation,
        isCancelled,
        onProgress,
      );
    }

    // Use the platform-specific runner, which is resolved at compile time
    // via the conditional import.
    // - On native, `spawnIsolate` uses `Isolate.spawn` for full two-way communication.
    // - On web, `spawnIsolate` uses `compute` as a fallback, which has limitations
    //   (e.g., no progress reporting or cancellation).
    return spawnIsolate<T>(
      operations,
      processOperation,
      isCancelled,
      onProgress,
      wrappedStrategy,
    );
  }
}
