// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'dart:async';

// import 'package:test_api/src/backend/invoker.dart';

import 'package:datum/datum.dart';

// import '_isolate_runner_io.dart' if (dart.library.html) '_isolate_runner_web.dart';

/// Defines the execution strategy for processing the sync queue.
abstract class DatumSyncExecutionStrategy {
  /// A strategy that processes pending operations one by one.
  const factory DatumSyncExecutionStrategy.sequential() = SequentialStrategy;

  /// A strategy that processes pending operations in parallel batches.
  const factory DatumSyncExecutionStrategy.parallel({int batchSize}) = ParallelStrategy;

  /// A strategy that runs the sync process in a background isolate to avoid
  /// blocking the UI thread.
  ///
  /// It wraps another [DatumSyncExecutionStrategy] (e.g., `sequential` or `parallel`)
  /// which will be executed within the isolate.
  // const factory DatumSyncExecutionStrategy.isolate(
  //   DatumSyncExecutionStrategy strategy, {
  //   // Add the optional parameter to the factory constructor as well.
  //   bool forceIsolateInTest,
  // }) = IsolateStrategy.new;

  /// Executes the push operations according to the strategy.
  ///
  /// - [operations]: The list of operations to process.
  /// - [processOperation]: A function that processes a single operation.
  /// - [isCancelled]: A function to check if the sync has been cancelled.
  /// - [onProgress]: A callback to report progress.
  Future<void> execute<T extends DatumEntityInterface>(
    List<DatumSyncOperation<T>> operations,
    Future<void> Function(DatumSyncOperation<T> operation) processOperation,
    bool Function() isCancelled,
    void Function(int completed, int total) onProgress,
  );
}

/// Processes pending operations one by one.
/// This is safer and less resource-intensive.
class SequentialStrategy implements DatumSyncExecutionStrategy {
  /// Creates a strategy that processes operations sequentially.
  const SequentialStrategy();

  @override
  Future<void> execute<T extends DatumEntityInterface>(
    List<DatumSyncOperation<T>> operations,
    Future<void> Function(DatumSyncOperation<T> operation) processOperation,
    bool Function() isCancelled,
    void Function(int completed, int total) onProgress,
  ) async {
    var completedOps = 0;
    final totalOps = operations.length;
    // Iterate over a copy to prevent concurrent modification errors.
    for (final operation in operations.toList()) {
      if (isCancelled()) {
        break;
      }
      try {
        await processOperation(operation);
        completedOps++;
        onProgress(completedOps, totalOps);
      } catch (e) {
        // If an error occurs, rethrow it to be handled by the caller.
        // This ensures that the sync process stops on failure.
        rethrow;
      }
    }
  }
}

/// Processes pending operations in parallel batches.
class ParallelStrategy implements DatumSyncExecutionStrategy {
  /// Creates a strategy that processes operations in parallel.
  ///
  /// [batchSize] determines how many operations are processed concurrently.
  /// [failFast] if true, stops processing remaining operations when the first error occurs.
  const ParallelStrategy({this.batchSize = 10, this.failFast = true});

  /// The number of operations to process concurrently in a single batch.
  final int batchSize;

  /// Whether to stop processing when the first error occurs.
  final bool failFast;

  @override
  Future<void> execute<T extends DatumEntityInterface>(
    List<DatumSyncOperation<T>> operations,
    Future<void> Function(DatumSyncOperation<T> operation) processOperation,
    bool Function() isCancelled,
    void Function(int completed, int total) onProgress,
  ) async {
    final totalOps = operations.length;
    final errors = <Object>[];

    for (var i = 0; i < totalOps; i += batchSize) {
      if (isCancelled()) break;

      // If we already have errors and failFast is enabled, stop processing
      if (failFast && errors.isNotEmpty) break;

      final end = (i + batchSize < totalOps) ? i + batchSize : totalOps;
      final batch = operations.sublist(i, end);

      if (failFast) {
        // Use Future.wait with eagerError for fail-fast behavior
        try {
          await Future.wait(
            batch.map((op) => processOperation(op)),
            eagerError: failFast,
          );
          // Report progress only on successful batch completion
          onProgress(end, totalOps);
        } catch (e) {
          // When failing fast, we rethrow immediately. Progress for this batch is not reported.
          rethrow;
        }
      } else {
        // Original behavior: collect all errors
        final results = await Future.wait(
          batch.map((op) async {
            try {
              await processOperation(op);
              return null; // Success
            } catch (e) {
              return e; // Failure
            }
          }),
        );

        errors.addAll(results.whereType<Object>());
        // Report progress even if there were errors in the batch, as failFast is false.
        onProgress(end, totalOps);
      }
    }

    // After all batches are processed, if we collected any errors (in non-failFast mode),
    // throw the first one to signal that the overall sync failed.
    if (errors.isNotEmpty) {
      throw errors.first is DatumException
          ? errors.first
          : DatumException.fromError(
              errors.first,
              code: DatumExceptionCode.unknown,
            );
    }
  }
}
