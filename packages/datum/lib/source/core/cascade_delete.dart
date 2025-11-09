import 'dart:async';

import 'models/datum_entity.dart';

/// Analytics data collected during cascade delete operations.
class CascadeAnalytics {
  /// Total duration of the cascade delete operation.
  final Duration totalDuration;

  /// Number of database queries executed.
  final int queriesExecuted;

  /// Number of relationships traversed.
  final int relationshipsTraversed;

  /// Map of entity types to the number of entities processed.
  final Map<Type, int> entitiesProcessedByType;

  /// Map of entity types to the number of entities successfully deleted.
  final Map<Type, int> entitiesDeletedByType;

  /// Number of restrict violations encountered.
  final int restrictViolations;

  /// Number of set-null operations performed.
  final int setNullOperations;

  /// Number of errors encountered.
  final int errorsEncountered;

  /// Whether the operation was a dry run.
  final bool wasDryRun;

  /// Timestamp when the operation started.
  final DateTime startedAt;

  /// Timestamp when the operation completed.
  final DateTime completedAt;

  const CascadeAnalytics({
    required this.totalDuration,
    required this.queriesExecuted,
    required this.relationshipsTraversed,
    required this.entitiesProcessedByType,
    required this.entitiesDeletedByType,
    required this.restrictViolations,
    required this.setNullOperations,
    required this.errorsEncountered,
    required this.wasDryRun,
    required this.startedAt,
    required this.completedAt,
  });

  /// Total number of entities processed across all types.
  int get totalEntitiesProcessed =>
      entitiesProcessedByType.values.fold(0, (sum, count) => sum + count);

  /// Total number of entities deleted across all types.
  int get totalEntitiesDeleted =>
      entitiesDeletedByType.values.fold(0, (sum, count) => sum + count);

  /// Success rate as a percentage (0.0 to 100.0).
  double get successRate =>
      totalEntitiesProcessed > 0
          ? (totalEntitiesDeleted / totalEntitiesProcessed) * 100.0
          : 100.0;

  /// Average time per entity processed.
  Duration get averageTimePerEntity =>
      totalEntitiesProcessed > 0
          ? Duration(microseconds: totalDuration.inMicroseconds ~/ totalEntitiesProcessed)
          : Duration.zero;

  /// Creates a copy with updated values.
  CascadeAnalytics copyWith({
    Duration? totalDuration,
    int? queriesExecuted,
    int? relationshipsTraversed,
    Map<Type, int>? entitiesProcessedByType,
    Map<Type, int>? entitiesDeletedByType,
    int? restrictViolations,
    int? setNullOperations,
    int? errorsEncountered,
    bool? wasDryRun,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return CascadeAnalytics(
      totalDuration: totalDuration ?? this.totalDuration,
      queriesExecuted: queriesExecuted ?? this.queriesExecuted,
      relationshipsTraversed: relationshipsTraversed ?? this.relationshipsTraversed,
      entitiesProcessedByType: entitiesProcessedByType ?? this.entitiesProcessedByType,
      entitiesDeletedByType: entitiesDeletedByType ?? this.entitiesDeletedByType,
      restrictViolations: restrictViolations ?? this.restrictViolations,
      setNullOperations: setNullOperations ?? this.setNullOperations,
      errorsEncountered: errorsEncountered ?? this.errorsEncountered,
      wasDryRun: wasDryRun ?? this.wasDryRun,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  String toString() {
    return 'CascadeAnalytics('
        'totalDuration: $totalDuration, '
        'queriesExecuted: $queriesExecuted, '
        'relationshipsTraversed: $relationshipsTraversed, '
        'totalEntitiesProcessed: $totalEntitiesProcessed, '
        'totalEntitiesDeleted: $totalEntitiesDeleted, '
        'restrictViolations: $restrictViolations, '
        'setNullOperations: $setNullOperations, '
        'errorsEncountered: $errorsEncountered, '
        'successRate: ${successRate.toStringAsFixed(1)}%, '
        'wasDryRun: $wasDryRun)';
  }
}

/// Builder for collecting cascade analytics during operations.
class CascadeAnalyticsBuilder {
  DateTime? _startedAt;
  DateTime? _completedAt;
  int _queriesExecuted = 0;
  int _relationshipsTraversed = 0;
  final Map<Type, int> _entitiesProcessedByType = {};
  final Map<Type, int> _entitiesDeletedByType = {};
  int _restrictViolations = 0;
  int _setNullOperations = 0;
  int _errorsEncountered = 0;
  bool _wasDryRun = false;

  void startOperation({bool dryRun = false}) {
    _startedAt = DateTime.now();
    _wasDryRun = dryRun;
  }

  void completeOperation() {
    _completedAt = DateTime.now();
  }

  void recordQueryExecuted() {
    _queriesExecuted++;
  }

  void recordRelationshipTraversed() {
    _relationshipsTraversed++;
  }

  void recordEntityProcessed(Type entityType) {
    _entitiesProcessedByType[entityType] = (_entitiesProcessedByType[entityType] ?? 0) + 1;
  }

  void recordEntityDeleted(Type entityType) {
    _entitiesDeletedByType[entityType] = (_entitiesDeletedByType[entityType] ?? 0) + 1;
  }

  void recordRestrictViolation() {
    _restrictViolations++;
  }

  void recordSetNullOperation() {
    _setNullOperations++;
  }

  void recordError() {
    _errorsEncountered++;
  }

  CascadeAnalytics build() {
    final now = DateTime.now();
    final startedAt = _startedAt ?? now;
    final completedAt = _completedAt ?? (_startedAt != null ? now : startedAt);
    final totalDuration = _startedAt != null && _completedAt != null
        ? completedAt.difference(startedAt)
        : Duration.zero;

    return CascadeAnalytics(
      totalDuration: totalDuration,
      queriesExecuted: _queriesExecuted,
      relationshipsTraversed: _relationshipsTraversed,
      entitiesProcessedByType: Map.unmodifiable(_entitiesProcessedByType),
      entitiesDeletedByType: Map.unmodifiable(_entitiesDeletedByType),
      restrictViolations: _restrictViolations,
      setNullOperations: _setNullOperations,
      errorsEncountered: _errorsEncountered,
      wasDryRun: _wasDryRun,
      startedAt: startedAt,
      completedAt: completedAt,
    );
  }
}

/// Result of a cascade delete operation.
class CascadeDeleteResult<T extends DatumEntityInterface> {
  /// Whether the cascade delete operation was successful.
  final bool success;

  /// The main entity that was attempted to be deleted.
  final T? entity;

  /// Map of entity types to lists of entities that were successfully deleted.
  final Map<Type, List<DatumEntityInterface>> deletedEntities;

  /// Map of relation names to entities that prevented deletion (for restrict behavior).
  final Map<String, List<DatumEntityInterface>> restrictedRelations;

  /// List of error messages encountered during the operation.
  final List<String> errors;

  const CascadeDeleteResult({
    required this.success,
    required this.entity,
    required this.deletedEntities,
    required this.restrictedRelations,
    required this.errors,
  });

  /// Total number of entities deleted across all types.
  int get totalDeleted => deletedEntities.values.fold(0, (sum, list) => sum + list.length);
}



/// Configuration for cascade delete operations.
class CascadeOptions {
  final bool dryRun;
  final void Function(CascadeProgress)? onProgress;
  final CancellationToken? cancellationToken;
  final Duration timeout;
  final bool allowPartialDeletes;

  const CascadeOptions({
    this.dryRun = false,
    this.onProgress,
    this.cancellationToken,
    this.timeout = const Duration(seconds: 30),
    this.allowPartialDeletes = false,
  });

  CascadeOptions copyWith({
    bool? dryRun,
    void Function(CascadeProgress)? onProgress,
    CancellationToken? cancellationToken,
    Duration? timeout,
    bool? allowPartialDeletes,
  }) {
    return CascadeOptions(
      dryRun: dryRun ?? this.dryRun,
      onProgress: onProgress ?? this.onProgress,
      cancellationToken: cancellationToken ?? this.cancellationToken,
      timeout: timeout ?? this.timeout,
      allowPartialDeletes: allowPartialDeletes ?? this.allowPartialDeletes,
    );
  }
}

/// Progress information for cascade delete operations.
class CascadeProgress {
  final int completed;
  final int total;
  final String currentEntityType;
  final String currentEntityId;
  final String? message;

  const CascadeProgress({
    required this.completed,
    required this.total,
    required this.currentEntityType,
    required this.currentEntityId,
    this.message,
  });

  double get progressPercentage => total > 0 ? (completed / total) * 100 : 0;
}

/// Cancellation token for cascade operations.
class CancellationToken {
  bool _isCancelled = false;
  final _listeners = <void Function()>[];

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    for (final listener in _listeners) {
      listener();
    }
    _listeners.clear();
  }

  void onCancel(void Function() callback) {
    if (_isCancelled) {
      callback();
    } else {
      _listeners.add(callback);
    }
  }
}

/// Fluent API builder for cascade delete operations.
class CascadeDeleteBuilder<T extends DatumEntityInterface> {
  final dynamic _manager;
  final String _entityId;
  String? _userId;
  CascadeOptions _options;

  CascadeDeleteBuilder(this._manager, this._entityId)
      : _options = const CascadeOptions();

  /// Specify the user ID for the operation.
  CascadeDeleteBuilder<T> forUser(String userId) {
    _userId = userId;
    return this;
  }

  /// Configure cascade options.
  CascadeDeleteBuilder<T> withOptions(CascadeOptions options) {
    _options = options;
    return this;
  }

  /// Enable dry-run mode to preview what would be deleted.
  CascadeDeleteBuilder<T> dryRun() {
    _options = _options.copyWith(dryRun: true);
    return this;
  }

  /// Set progress callback.
  CascadeDeleteBuilder<T> withProgress(void Function(CascadeProgress) callback) {
    _options = _options.copyWith(onProgress: callback);
    return this;
  }

  /// Set cancellation token.
  CascadeDeleteBuilder<T> withCancellation(CancellationToken token) {
    _options = _options.copyWith(cancellationToken: token);
    return this;
  }

  /// Set timeout duration.
  CascadeDeleteBuilder<T> withTimeout(Duration timeout) {
    _options = _options.copyWith(timeout: timeout);
    return this;
  }

  /// Allow partial deletes when some operations fail.
  CascadeDeleteBuilder<T> allowPartialDeletes() {
    _options = _options.copyWith(allowPartialDeletes: true);
    return this;
  }

  /// Execute the cascade delete operation.
  Future<CascadeResult<T>> execute() async {
    if (_userId == null) {
      throw ArgumentError('User ID must be specified. Use forUser() method.');
    }

    return _manager.executeCascadeDeleteWithOptions(
      _entityId,
      _userId!,
      _options,
    );
  }
}

/// Enhanced result types for cascade operations.
abstract class CascadeResult<T extends DatumEntityInterface> {
  bool get success;
  T? get entity;
  int get totalDeleted;
  List<String> get errors;
}

/// Successful cascade delete result.
class CascadeSuccess<T extends DatumEntityInterface> extends CascadeResult<T> {
  @override
  final bool success = true;

  @override
  final T entity;

  @override
  final int totalDeleted;

  final Map<Type, List<DatumEntityInterface>> deletedEntities;
  final Map<String, List<DatumEntityInterface>> restrictedRelations;

  /// Analytics data collected during the operation.
  final CascadeAnalytics analytics;

  @override
  final List<String> errors = const [];

  CascadeSuccess({
    required this.entity,
    required this.totalDeleted,
    required this.deletedEntities,
    required this.restrictedRelations,
    required this.analytics,
  });
}

/// Failed cascade delete result.
class CascadeFailure<T extends DatumEntityInterface> extends CascadeResult<T> {
  @override
  final bool success = false;

  @override
  final T? entity;

  @override
  final int totalDeleted = 0;

  final CascadeError error;
  final List<String> _errors;

  @override
  List<String> get errors => [error.message, ..._errors];

  CascadeFailure({
    required this.entity,
    required this.error,
    List<String> errors = const [],
  }) : _errors = errors;
}

/// Detailed error information for cascade operations.
class CascadeError {
  final String code;
  final String message;
  final Map<String, dynamic>? details;
  final String? entityType;
  final String? entityId;
  final String? relationName;

  const CascadeError({
    required this.code,
    required this.message,
    this.details,
    this.entityType,
    this.entityId,
    this.relationName,
  });

  static CascadeError entityNotFound(String entityId) {
    return CascadeError(
      code: 'ENTITY_NOT_FOUND',
      message: 'Entity with ID "$entityId" does not exist',
      entityId: entityId,
    );
  }

  static CascadeError restrictViolation(String relationName, List<String> entityIds) {
    return CascadeError(
      code: 'RESTRICT_VIOLATION',
      message: 'Cannot delete due to restrict constraint on relation "$relationName"',
      relationName: relationName,
      details: {'restrictedEntities': entityIds},
    );
  }

  static CascadeError deleteFailed(String entityType, String entityId, String reason) {
    return CascadeError(
      code: 'DELETE_FAILED',
      message: 'Failed to delete $entityType "$entityId": $reason',
      entityType: entityType,
      entityId: entityId,
      details: {'reason': reason},
    );
  }

  static CascadeError timeout(Duration timeout) {
    return CascadeError(
      code: 'TIMEOUT',
      message: 'Cascade delete operation timed out after ${timeout.inSeconds} seconds',
      details: {'timeoutSeconds': timeout.inSeconds},
    );
  }

  static CascadeError cancelled() {
    return const CascadeError(
      code: 'CANCELLED',
      message: 'Cascade delete operation was cancelled',
    );
  }
}
