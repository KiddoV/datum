import 'dart:async';

import 'package:async_queue/async_queue.dart';

/// Defines the strategy for handling concurrent calls to the `synchronize` method.
abstract class DatumSyncRequestStrategy {
  /// Executes the given [action] according to the strategy's rules.
  ///
  /// - [action]: The synchronization logic to be executed.
  /// - [isSyncInProgress]: A function that returns true if a sync is currently running.
  /// - [onSkipped]: A callback that is invoked if the strategy decides to skip the action.
  Future<T> execute<T>(
    Future<T> Function() action, {
    required bool Function() isSyncInProgress,
    required T Function() onSkipped,
  });
}

/// A strategy that skips new sync requests if one is already in progress.
/// This prevents re-entrant sync calls.
class SkipConcurrentStrategy implements DatumSyncRequestStrategy {
  const SkipConcurrentStrategy();

  @override
  Future<T> execute<T>(
    Future<T> Function() action, {
    required bool Function() isSyncInProgress,
    required T Function() onSkipped,
  }) {
    if (isSyncInProgress()) {
      return Future.value(onSkipped());
    }
    return action();
  }
}

/// A strategy that queues new sync requests if one is already in progress.
///
/// This ensures that all requested syncs are executed sequentially, one after
/// the other, preventing lost updates from rapid, concurrent calls. This is
/// the recommended default for most applications to ensure data consistency.
class SequentialRequestStrategy implements DatumSyncRequestStrategy {
  const SequentialRequestStrategy();

  // A static queue to ensure all DatumManager instances share the same
  // sequential processing logic if they are part of the same Isolate.
  static final AsyncQueue _queue = AsyncQueue.autoStart();

  @override
  Future<T> execute<T>(
    Future<T> Function() action, {
    required bool Function() isSyncInProgress,
    required T Function() onSkipped,
  }) {
    final completer = Completer<T>();
    _queue.addJob((_) async {
      try {
        final result = await action();
        completer.complete(result);
      } catch (e, s) {
        completer.completeError(e, s);
      }
    });
    return completer.future;
  }
}
