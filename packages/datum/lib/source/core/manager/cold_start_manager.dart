import 'dart:async';

import 'package:datum/source/core/models/cold_start_strategy.dart';
import 'package:datum/source/core/models/datum_sync_options.dart';
import 'package:datum/source/core/models/datum_sync_result.dart';
import 'package:datum/source/utils/datum_logger.dart';

/// Interface for cold start state persistence
abstract class ColdStartPersistence {
  Future<void> saveState(String userId, Map<String, dynamic> state);
  Future<Map<String, dynamic>?> loadState(String userId);
  Future<void> clearState(String userId);
}

/// In-memory implementation for cold start persistence
class InMemoryColdStartPersistence implements ColdStartPersistence {
  final Map<String, Map<String, dynamic>> _storage = {};

  @override
  Future<void> saveState(String userId, Map<String, dynamic> state) async {
    _storage[userId] = Map.from(state);
  }

  @override
  Future<Map<String, dynamic>?> loadState(String userId) async {
    return _storage[userId];
  }

  @override
  Future<void> clearState(String userId) async {
    _storage.remove(userId);
  }
}

/// Manages cold start synchronization behavior.
/// Handles detection of cold starts and orchestrates appropriate sync strategies.
class ColdStartManager {
  // Per-user state instead of global static state
  final Map<String, bool> _isColdStart = {};
  final Map<String, DateTime?> _lastColdStartTime = {};
  final ColdStartConfig _config;
  final DatumLogger _logger;

  // Retry configuration
  final int _maxRetries;
  final Duration _initialRetryDelay;
  final double _retryBackoffMultiplier;

  ColdStartManager(
    this._config, {
    DatumLogger? logger,
    ColdStartPersistence? persistence,
    int maxRetries = 3,
    Duration initialRetryDelay = const Duration(seconds: 5),
    double retryBackoffMultiplier = 2.0,
  })  : _logger = logger ?? DatumLogger(),
        _maxRetries = maxRetries,
        _initialRetryDelay = initialRetryDelay,
        _retryBackoffMultiplier = retryBackoffMultiplier;

  /// Checks if this is a cold start and performs appropriate sync if needed.
  Future<bool> handleColdStartIfNeeded(
    String userId,
    Future<DatumSyncResult> Function(DatumSyncOptions) syncFunction,
  ) async {
    _logger.debug('Checking for cold start sync for user: $userId');

    // Initialize user state if not exists
    _isColdStart.putIfAbsent(userId, () => true);

    final isColdStart = _isColdStart[userId] ?? true;

    if (!isColdStart || _config.strategy == ColdStartStrategy.disabled) {
      if (_config.strategy == ColdStartStrategy.disabled) {
        _logger.debug('Cold start sync disabled by configuration');
      } else if (!isColdStart) {
        _logger.debug('Not a cold start, skipping cold start sync');
      }
      return false;
    }

    final shouldSync = await _shouldPerformColdStartSync(userId);
    if (!shouldSync) {
      _logger.debug('Cold start sync not needed based on strategy evaluation');
      _isColdStart[userId] = false;
      return false;
    }

    _logger.info('Performing cold start sync for user: $userId using strategy: ${_config.strategy}');

    try {
      await _performColdStartSync(userId, syncFunction);
      _isColdStart[userId] = false;
      _lastColdStartTime[userId] = DateTime.now();
      _logger.info('Cold start sync completed successfully for user: $userId');
      return true;
    } catch (e, stack) {
      _logger.error('Cold start sync failed for user: $userId', stack);
      // On cold start sync failure, don't mark as completed
      // Allow retry on next app launch
      rethrow;
    }
  }

  /// Determines if cold start sync should be performed based on strategy and conditions.
  Future<bool> _shouldPerformColdStartSync(String userId) async {
    switch (_config.strategy) {
      case ColdStartStrategy.disabled:
        return false;

      case ColdStartStrategy.fullSync:
        return true;

      case ColdStartStrategy.adaptive:
        return await _evaluateAdaptiveStrategy(userId);

      case ColdStartStrategy.incremental:
        return await _shouldPerformIncrementalSync(userId);

      case ColdStartStrategy.priorityBased:
        return true; // Always attempt priority-based sync
    }
  }

  /// Evaluates adaptive strategy based on time since last sync and other factors.
  Future<bool> _evaluateAdaptiveStrategy(String userId) async {
    _logger.debug('Evaluating adaptive cold start strategy for user: $userId');

    // Check time since last sync
    final lastTime = _lastColdStartTime[userId];
    if (lastTime != null) {
      final timeSinceLastColdStart = DateTime.now().difference(lastTime);
      _logger.debug('Time since last cold start: $timeSinceLastColdStart, threshold: ${_config.syncThreshold}');

      if (timeSinceLastColdStart < _config.syncThreshold) {
        _logger.debug('Skipping cold start sync - too soon since last cold start');
        return false; // Too soon for another cold start sync
      }
    } else {
      _logger.debug('No previous cold start recorded, allowing sync');
    }

    // Could add more adaptive logic here:
    // - Check battery level
    // - Check network conditions
    // - Check if there are pending local changes
    // - Check app usage patterns

    _logger.debug('Adaptive strategy evaluation: allowing cold start sync');
    return true;
  }

  /// Determines if incremental sync should be performed.
  Future<bool> _shouldPerformIncrementalSync(String userId) async {
    _logger.debug('Evaluating incremental cold start strategy for user: $userId');
    // Incremental sync logic would go here
    // Check if remote has changes since last local sync
    _logger.debug('Incremental strategy: allowing cold start sync');
    return true; // For now, always attempt
  }

  /// Performs the appropriate cold start sync based on strategy.
  Future<void> _performColdStartSync(
    String userId,
    Future<DatumSyncResult> Function(DatumSyncOptions) syncFunction,
  ) async {
    _logger.debug('Starting cold start sync execution for user: $userId');

    // Add initial delay to allow UI to load
    if (_config.initialDelay > Duration.zero) {
      _logger.debug('Applying initial delay of ${_config.initialDelay} before cold start sync');
      await Future.delayed(_config.initialDelay);
    }

    final forceFullSync = _shouldForceFullSync();
    final options = DatumSyncOptions(
      forceFullSync: forceFullSync,
      timeout: _config.maxDuration,
    );

    _logger.info('Executing cold start sync with forceFullSync: $forceFullSync, timeout: ${_config.maxDuration}');

    // Implement retry logic with exponential backoff
    await _executeWithRetry(
      () => syncFunction(options),
      userId: userId,
      operationName: 'cold start sync',
    );

    _logger.debug('Cold start sync execution completed');
  }

  /// Executes an operation with retry logic and exponential backoff.
  Future<T> _executeWithRetry<T>(
    Future<T> Function() operation, {
    required String userId,
    required String operationName,
  }) async {
    int attempt = 0;
    Duration currentDelay = _initialRetryDelay;

    while (attempt <= _maxRetries) {
      try {
        if (attempt > 0) {
          _logger.info('Retrying $operationName for user $userId (attempt ${attempt + 1}/${_maxRetries + 1}) after ${currentDelay.inSeconds}s delay');
          await Future.delayed(currentDelay);
          currentDelay = Duration(milliseconds: (currentDelay.inMilliseconds * _retryBackoffMultiplier).round());
        }

        return await operation();
      } catch (e, stack) {
        attempt++;

        if (attempt > _maxRetries) {
          _logger.error('$operationName failed after ${_maxRetries + 1} attempts for user $userId', stack);
          rethrow;
        }

        _logger.warn('$operationName failed on attempt $attempt for user $userId: $e');

        // Don't retry certain types of errors
        if (e is ArgumentError || e is StateError || e is UnsupportedError) {
          _logger.warn('Not retrying $operationName for user $userId due to non-retryable error: $e');
          rethrow;
        }
      }
    }

    // This should never be reached, but just in case
    throw StateError('Unexpected retry logic error');
  }

  /// Determines if full sync should be forced based on strategy.
  bool _shouldForceFullSync() {
    switch (_config.strategy) {
      case ColdStartStrategy.fullSync:
      case ColdStartStrategy.adaptive:
        return true;
      case ColdStartStrategy.incremental:
      case ColdStartStrategy.priorityBased:
        return false;
      case ColdStartStrategy.disabled:
        return false;
    }
  }



  /// Resets cold start state for a specific user (useful for testing).
  void resetForUser(String userId) {
    _isColdStart[userId] = true;
    _lastColdStartTime[userId] = null;
  }

  /// Resets cold start state for all users (useful for testing).
  void resetAll() {
    _isColdStart.clear();
    _lastColdStartTime.clear();
  }

  /// Sets the last cold start time for a specific user (useful for testing).
  void setLastColdStartTimeForUser(String userId, DateTime? time) {
    _lastColdStartTime[userId] = time;
  }

  /// Gets current cold start status for a specific user.
  bool isColdStartForUser(String userId) {
    return _isColdStart[userId] ?? true;
  }

  /// Gets the last cold start time for a specific user.
  DateTime? getLastColdStartTimeForUser(String userId) {
    return _lastColdStartTime[userId];
  }

  /// Gets all users with cold start state.
  Set<String> getActiveUsers() {
    return _isColdStart.keys.toSet();
  }

  ColdStartConfig get config => _config;
}
