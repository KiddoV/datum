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

  /// Disposes of any resources held by the strategy.
  void dispose() {}
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

  @override
  void dispose() {}
}

/// A strategy that queues new sync requests if one is already in progress.
///
/// This ensures that all requested syncs are executed sequentially, one after
/// the other, preventing lost updates from rapid, concurrent calls. This is
/// the recommended default for most applications to ensure data consistency.
class SequentialRequestStrategy implements DatumSyncRequestStrategy {
  /// The number of times to retry a failed synchronization action.
  final int retryCount;

  /// Creates a sequential strategy with an optional [retryCount].
  const SequentialRequestStrategy({this.retryCount = 3});

  @override
  Future<T> execute<T>(
    //
    Future<T> Function() action, {
    required bool Function() isSyncInProgress,
    required T Function() onSkipped,
  }) {
    final completer = Completer<T>();
    (_instanceQueues[this] ??= AsyncQueue.autoStart()).addJob(
      (queue) async {
        try {
          final result = await action();
          completer.complete(result);
        } catch (e, s) {
          try {
            queue.retry();
          } catch (_) {
            // This catch block handles the case where retry is called more than
            // `retryCount` times. The queue throws an error, and we complete
            // the future with the original error.
            completer.completeError(e, s);
          }
        }
      },
      retryTime: retryCount,
    );
    return completer.future;
  }

  @override
  void dispose() {
    _instanceQueues[this]?.stop();
  }
}

/// A weak map to hold a queue for each strategy instance.
final _instanceQueues = <SequentialRequestStrategy, AsyncQueue>{};
