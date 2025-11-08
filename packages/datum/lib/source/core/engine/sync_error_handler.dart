import 'dart:async';

import 'package:datum/datum.dart';

/// Utility class for handling synchronization errors consistently across the manager and engine.
class SyncErrorHandler {
  /// Handles sync errors by processing events and returning appropriate Future errors.
  ///
  /// This simplifies the complex pattern of checking if an error is already wrapped,
  /// processing events, and returning Future.error with the correct parameters.
  static Future<T> handleSyncError<T extends DatumEntityInterface>(
    Object error,
    StackTrace stack,
    List<DatumSyncEvent<T>> events,
    void Function(List<DatumSyncEvent<T>>) eventProcessor,
  ) {
    if (error is SyncExceptionWithEvents<T>) {
      // Error is already wrapped, just process events and rethrow
      eventProcessor(error.events);
      return Future.error(error.originalError, error.originalStackTrace);
    }

    // Create new wrapped exception for unwrapped errors
    final wrapped = SyncExceptionWithEvents<T>(error, stack, events);
    eventProcessor(wrapped.events);
    return Future.error(wrapped.originalError, wrapped.originalStackTrace);
  }

  /// Handles sync errors with automatic event processing for DatumManager.
  ///
  /// This is a convenience method that automatically calls _processSyncEvents.
  static Future<T> handleManagerSyncError<T extends DatumEntityInterface>(
    Object error,
    StackTrace stack,
    List<DatumSyncEvent<T>> events,
    void Function(List<DatumSyncEvent<T>>) eventProcessor,
  ) {
    return handleSyncError(error, stack, events, eventProcessor);
  }

  /// Handles sync errors at the manager level.
  ///
  /// Processes events from SyncExceptionWithEvents and re-throws the original error.
  static void handleManagerSyncErrorSync<T extends DatumEntityInterface>(
    Object error,
    StackTrace stack,
    List<DatumSyncEvent<T>> events,
    void Function(List<DatumSyncEvent<T>> events) eventProcessor,
  ) {
    // Process any events that were captured
    if (events.isNotEmpty) {
      eventProcessor(events);
    }

    // If it's already a SyncExceptionWithEvents, extract and re-throw the original error
    if (error is SyncExceptionWithEvents<T>) {
      // Re-throw the original error with the original stack trace
      throw error.originalError;
    }

    // For other errors, re-throw as-is
    throw error;
  }

  /// Handles sync errors at the engine level.
  ///
  /// Wraps errors in SyncExceptionWithEvents to preserve events and context.
  static Future<DatumSyncResult<T>> handleEngineSyncError<T extends DatumEntityInterface>(
    Object error,
    StackTrace stack,
    String userId,
    List<DatumSyncEvent<T>> events,
  ) async {
    // Create a sync error event if one doesn't already exist
    final hasErrorEvent = events.any((e) => e is DatumSyncErrorEvent<T>);
    if (!hasErrorEvent) {
      events.add(DatumSyncErrorEvent<T>(
        userId: userId,
        error: error,
        stackTrace: stack,
      ));
    }

    // Wrap the error with events for the manager to handle
    await Future.error(SyncExceptionWithEvents<T>(error, stack, events), stack);
    // This line won't be reached, but satisfies the type checker
    return DatumSyncResult<T>.fromError(userId, error);
  }
}
