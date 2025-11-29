---
title: Advanced Synchronization Patterns
---




This guide covers advanced synchronization patterns, monitoring, and control features in Datum. These patterns help you build robust, production-ready applications with sophisticated data synchronization requirements.

## Sync Strategies and Execution

<Info>
**Pro Tip**: Choose sync direction based on your app's needs. `pushThenPull` is recommended for most applications as it ensures local changes are sent first.
</Info>

### Sync Direction Control

Datum supports different synchronization directions to control the flow of data:

```dart
// Push local changes to remote, then pull remote changes
final pushThenPullResult = await manager.synchronize(
  'user123',
  options: DatumSyncOptions(direction: SyncDirection.pushThenPull),
);

// Pull remote changes first, then push local changes
final pullThenPushResult = await manager.synchronize(
  'user123',
  options: DatumSyncOptions(direction: SyncDirection.pullThenPush),
);

// Only push local changes (useful for one-way sync)
final pushOnlyResult = await manager.synchronize(
  'user123',
  options: DatumSyncOptions(direction: SyncDirection.pushOnly),
);

// Only pull remote changes (useful for read-only data)
final pullOnlyResult = await manager.synchronize(
  'user123',
  options: DatumSyncOptions(direction: SyncDirection.pullOnly),
);
```

### Execution Strategies

Control how sync operations are processed:

```dart
// Sequential processing (default) - process operations one by one
final config = DatumConfig(
  syncExecutionStrategy: SequentialStrategy(),
);

// Parallel processing - process multiple operations concurrently
final config = DatumConfig(
  syncExecutionStrategy: ParallelStrategy(batchSize: 10),
);

// Background isolate processing - run sync in separate thread to avoid UI blocking
final config = DatumConfig(
  syncExecutionStrategy: IsolateStrategy(SequentialStrategy()),
);

// Parallel processing in background isolate
final config = DatumConfig(
  syncExecutionStrategy: IsolateStrategy(
    ParallelStrategy(batchSize: 5, failFast: true),
  ),
);
```

<Info>
**Performance Tip**: Use `IsolateStrategy` for heavy sync operations to prevent UI freezing. Combine with `ParallelStrategy` for maximum throughput on multi-core devices.
</Info>

### Request Strategies

Control how concurrent synchronization requests are handled:

```dart
// Queue concurrent requests with retry (default)
final config = DatumConfig(
  syncRequestStrategy: SequentialRequestStrategy(retryCount: 3),
);

// Skip concurrent requests if sync is already running
final config = DatumConfig(
  syncRequestStrategy: SkipConcurrentStrategy(),
);
```

<Info>
**Strategy Selection**: Use `SequentialRequestStrategy` for data consistency when multiple sync triggers occur. Use `SkipConcurrentStrategy` for performance-critical scenarios where duplicate syncs are acceptable.
</Info>

#### Sequential Request Strategy

Ensures all sync requests are processed in order, preventing lost updates:

```dart
// Custom retry configuration
final config = DatumConfig(
  syncRequestStrategy: SequentialRequestStrategy(retryCount: 5),
);

// Handle rapid user interactions
class TaskManager {
  Future<void> saveAndSync(Task task) async {
    await manager.save(task, userId: currentUserId);
    await manager.synchronize(currentUserId); // Queued if another sync is running
  }
}

// Multiple rapid calls are queued and processed sequentially
await Future.wait([
  taskManager.saveAndSync(task1),
  taskManager.saveAndSync(task2),
  taskManager.saveAndSync(task3),
]);
```

#### Skip Concurrent Strategy

Prevents resource waste from overlapping sync operations:

```dart
final config = DatumConfig(
  syncRequestStrategy: SkipConcurrentStrategy(),
);

// Auto-sync triggers won't overlap
manager.startAutoSync('user123', interval: Duration(minutes: 2));

// Manual sync calls during auto-sync are skipped
final result = await manager.synchronize('user123');
if (result.wasSkipped) {
  print('Sync was skipped - another sync is already in progress');
}
```

<Warning>
**Data Loss Risk**: `SkipConcurrentStrategy` may result in lost updates if important changes are skipped. Use only when sync operations are idempotent.
</Warning>

## Conflict Resolution

### Built-in Resolvers

Datum provides several conflict resolution strategies:

```dart
// Last write wins - choose the most recently modified version
final config = DatumConfig(
  defaultConflictResolver: LastWriteWinsResolver<Task>(),
);

// Local priority - always prefer local changes
final config = DatumConfig(
  defaultConflictResolver: LocalPriorityResolver<Task>(),
);

// Remote priority - always prefer remote changes
final config = DatumConfig(
  defaultConflictResolver: RemotePriorityResolver<Task>(),
);

// Intelligent merging - attempt to merge conflicting changes
final config = DatumConfig(
  defaultConflictResolver: MergeResolver<Task>(
    mergeFunction: (local, remote) {
      // Custom merge logic
      return local.copyWith(
        title: local.title, // Keep local title
        description: remote.description, // Take remote description
        modifiedAt: DateTime.now(),
      );
    },
  ),
);
```

<Warning>
**Important**: Custom conflict resolvers run on the main thread. For complex resolution logic, consider offloading to background isolates to avoid blocking the UI.
</Warning>

### Custom Conflict Resolvers

Implement custom resolution logic:

```dart
class CustomResolver extends DatumConflictResolver<Task> {
  @override
  Future<DatumConflictResolution<Task>> resolve(
    ConflictContext<Task> context,
  ) async {
    final local = context.localEntity;
    final remote = context.remoteEntity;

    // Custom logic: prefer local for titles, remote for other fields
    if (local.title != remote.title) {
      // Conflict in title - prompt user
      final userChoice = await promptUser(local.title, remote.title);
      final resolved = userChoice == 'local' ? local : remote;
      return DatumConflictResolution.resolved(resolved, 'User choice');
    }

    // No conflict or auto-resolved
    return DatumConflictResolution.resolved(local, 'No conflict');
  }
}
```

### Conflict Monitoring

Monitor and handle conflicts reactively:

```dart
// Listen for conflict events
manager.onConflict.listen((event) {
  print('Conflict detected: ${event.conflict}');
  // Handle conflict resolution UI
});

// Listen for resolution events
manager.eventStream
  .whereType<ConflictResolvedEvent<Task>>()
  .listen((event) {
    print('Conflict resolved: ${event.resolution}');
  });
```

## User Switching

### User Switch Strategies

Handle user switching with different strategies:

```dart
// Sync current user before switching
final result1 = await manager.switchUser(
  oldUserId: 'user1',
  newUserId: 'user2',
  strategy: UserSwitchStrategy.syncThenSwitch,
);

// Clear new user's data and fetch from remote
final result2 = await manager.switchUser(
  oldUserId: 'user1',
  newUserId: 'user2',
  strategy: UserSwitchStrategy.clearAndFetch,
);

// Fail if current user has unsynced data
final result3 = await manager.switchUser(
  oldUserId: 'user1',
  newUserId: 'user2',
  strategy: UserSwitchStrategy.promptIfUnsyncedData,
);

// Switch without any data modifications
final result4 = await manager.switchUser(
  oldUserId: 'user1',
  newUserId: 'user2',
  strategy: UserSwitchStrategy.keepLocal,
);
```

### User Switch Monitoring

```dart
// Listen for user switch events
manager.onUserSwitched.listen((event) {
  print('Switched from ${event.previousUserId} to ${event.newUserId}');
  print('Had unsynced data: ${event.hadUnsyncedData}');
});
```

## Connectivity Monitoring and Auto-Sync

### Automatic Sync on Connectivity Restoration

Datum can automatically monitor device connectivity and trigger synchronization when the device regains network access. This ensures that any pending operations queued while offline are automatically synchronized once connectivity is restored.

```dart
// Enable connectivity monitoring in DatumConfig
final config = DatumConfig(
  connectivityChecker: DefaultConnectivityChecker(),
  // Auto-sync is enabled by default when connectivity monitoring is configured
);

// The system will automatically:
// 1. Monitor connectivity status changes
// 2. Queue sync operations when offline
// 3. Automatically trigger sync when connectivity is restored
// 4. Handle network failures gracefully with retry logic
```

### Custom Connectivity Checker

Implement custom connectivity monitoring logic:

```dart
class CustomConnectivityChecker extends DatumConnectivityChecker {
  @override
  Future<bool> isConnected() async {
    // Implement your connectivity check logic
    // Return true if connected, false if offline
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  @override
  Stream<bool> get onConnectivityChanged {
    // Return a stream that emits connectivity status changes
    return Connectivity().onConnectivityChanged.map(
      (result) => result != ConnectivityResult.none,
    );
  }
}

// Use custom checker
final config = DatumConfig(
  connectivityChecker: CustomConnectivityChecker(),
);
```

<Info>
**Network Optimization**: Connectivity monitoring helps reduce unnecessary sync attempts when offline and ensures data consistency when connectivity is restored.
</Info>

## Auto-Sync Management

### Periodic Auto-Sync

Configure automatic synchronization:

```dart
// Start auto-sync with default interval
manager.startAutoSync('user123');

// Start auto-sync with custom interval
manager.startAutoSync('user123', interval: Duration(minutes: 10));

// Stop auto-sync for specific user
manager.stopAutoSync(userId: 'user123');

// Stop auto-sync for all users
manager.stopAutoSync();
```

### Auto-Sync Monitoring

```dart
// Monitor next sync time
manager.watchNextSyncTime?.listen((nextTime) {
  if (nextTime != null) {
    print('Next sync at: $nextTime');
  } else {
    print('Auto-sync disabled');
  }
});

// Monitor time until next sync
manager.watchNextSyncDuration?.listen((duration) {
  if (duration != null) {
    print('Next sync in: ${duration.inMinutes} minutes');
  }
});
```

## Global Sync Control

### Pause/Resume Sync

Control synchronization across all managers:

```dart
// Pause all sync operations
Datum.instance.pauseSync();

// Resume all sync operations
Datum.instance.resumeSync();

// Check if sync is paused
final isPaused = Datum.instance.currentStatus.status == DatumSyncStatus.paused;
```

### Remote Change Subscriptions

Manage remote change listening:

```dart
// Temporarily stop listening to remote changes
await manager.unsubscribeFromRemoteChanges();

// Resume listening to remote changes
await manager.resubscribeToRemoteChanges();

// Global control
await Datum.instance.unsubscribeAllFromRemoteChanges();
await Datum.instance.resubscribeAllToRemoteChanges();
```

## Monitoring and Observers

### Global Observers

Add observers for cross-cutting concerns:

```dart
class AuditObserver extends GlobalDatumObserver {
  @override
  void onSyncStart() {
    print('Global sync started');
  }

  @override
  void onSyncEnd(DatumSyncResult result) {
    print('Global sync completed: ${result.syncedCount} items');
  }

  @override
  void onUserSwitchStart(String? oldUserId, String newUserId, UserSwitchStrategy strategy) {
    print('Switching user from $oldUserId to $newUserId');
  }
}

// Register global observer
Datum.instance.addObserver(AuditObserver());
```

### Local Observers

Add entity-specific observers:

```dart
class TaskObserver extends DatumObserver<Task> {
  @override
  void onCreateStart(Task entity) {
    print('Creating task: ${entity.title}');
  }

  @override
  void onUpdateEnd(Task entity) {
    print('Updated task: ${entity.title}');
  }

  @override
  void onDeleteStart(String id) {
    print('Deleting task: $id');
  }
}

// Register during initialization
DatumRegistration<Task>(
  // ... adapters
  observers: [TaskObserver()],
);
```

## Data Transformation Middleware

### Middleware Pipeline

Implement data transformation pipelines for preprocessing and postprocessing:

```dart
class ValidationMiddleware extends DatumMiddleware<Task> {
  @override
  Future<Task> transformBeforeSave(Task item) async {
    if (item.title.isEmpty) {
      throw ValidationException('Task title cannot be empty');
    }
    if (item.dueDate.isBefore(DateTime.now())) {
      throw ValidationException('Due date cannot be in the past');
    }
    return item;
  }
}

class EncryptionMiddleware extends DatumMiddleware<Task> {
  @override
  Future<Task> transformBeforeSave(Task item) async {
    // Encrypt sensitive fields before saving
    final encryptedDescription = await encrypt(item.description);
    return item.copyWith(description: encryptedDescription);
  }

  @override
  Future<Task> transformAfterFetch(Task item) async {
    // Decrypt sensitive fields after fetching
    final decryptedDescription = await decrypt(item.description);
    return item.copyWith(description: decryptedDescription);
  }
}

class AuditMiddleware extends DatumMiddleware<Task> {
  @override
  Future<Task> transformBeforeSave(Task item) async {
    // Add audit trail
    final auditEntry = {
      'modifiedBy': currentUserId,
      'modifiedAt': DateTime.now(),
      'changes': item.diff ?? {},
    };
    await logAudit(auditEntry);
    return item;
  }
}

// Register middleware pipeline
DatumRegistration<Task>(
  // ... adapters
  middlewares: [
    ValidationMiddleware(),
    EncryptionMiddleware(),
    AuditMiddleware(),
  ],
);
```

<Info>
**Pipeline Order**: Middleware executes in registration order. Place validation first, then transformations, then audit/logging.
</Info>

### Advanced Middleware Patterns

```dart
class CompressionMiddleware extends DatumMiddleware<Task> {
  @override
  Future<Task> transformBeforeSave(Task item) async {
    // Compress large text fields
    if (item.description.length > 1000) {
      final compressed = await compress(item.description);
      return item.copyWith(
        description: compressed,
        metadata: {...item.metadata, 'compressed': true},
      );
    }
    return item;
  }

  @override
  Future<Task> transformAfterFetch(Task item) async {
    // Decompress if needed
    if (item.metadata['compressed'] == true) {
      final decompressed = await decompress(item.description);
      return item.copyWith(
        description: decompressed,
        metadata: {...item.metadata}..remove('compressed'),
      );
    }
    return item;
  }
}

class RelationshipEnrichmentMiddleware extends DatumMiddleware<Task> {
  @override
  Future<Task> transformAfterFetch(Task item) async {
    // Enrich with related data
    final assignee = await fetchUser(item.assigneeId);
    final comments = await fetchComments(item.id);

    return item.copyWith(
      metadata: {
        ...item.metadata,
        'assigneeName': assignee.name,
        'commentCount': comments.length,
      },
    );
  }
}
```

<Warning>
**Performance Consideration**: Middleware runs on the main thread. For CPU-intensive operations, consider using background isolates or delegating to background services.
</Warning>

## Error Handling and Recovery

### Error Recovery Strategies

Configure automatic error recovery:

```dart
final config = DatumConfig(
  errorRecoveryStrategy: DatumErrorRecoveryStrategy(
    maxRetries: 3,
    backoffStrategy: ExponentialBackoffStrategy(
      initialDelay: Duration(seconds: 1),
      maxDelay: Duration(minutes: 5),
    ),
  ),
);
```

### Sync Error Handling

Handle synchronization errors:

```dart
try {
  final result = await manager.synchronize('user123');
} on DatumException catch (e) {
  print('Sync failed: ${e.message}');
  switch (e.code) {
    case DatumExceptionCode.networkError:
      // Handle network issues
      break;
    case DatumExceptionCode.authError:
      // Handle authentication issues
      break;
    case DatumExceptionCode.schemaMismatch:
      // Handle schema conflicts
      break;
  }
}
```

### Event-Based Error Monitoring

```dart
// Listen for sync errors
manager.onSyncError.listen((event) {
  print('Sync error: ${event.error}');
  // Implement retry logic or user notification
});
```

## Performance Optimization

### Batch Operations

Use batch operations for multiple items:

```dart
// Batch create
await manager.saveMany(
  items: taskList,
  userId: 'user123',
  andSync: true, // Sync after all items are saved
);

// Batch with immediate sync for each
for (final batch in taskList.batches(10)) {
  await manager.saveMany(items: batch, userId: 'user123');
  await manager.synchronize('user123'); // Sync each batch
}
```

### Selective Sync

Use sync scopes for partial synchronization:

```dart
// Sync only specific entities
final scope = DatumSyncScope(
  entityIds: ['task1', 'task2', 'task3'],
);

final result = await manager.synchronize(
  'user123',
  scope: scope,
);
```

### Connection-Aware Sync

Adapt sync behavior based on connectivity:

```dart
class SmartConnectivityChecker extends DatumConnectivityChecker {
  @override
  Future<bool> isConnected() async {
    // Check connection quality
    final quality = await checkConnectionQuality();
    return quality != ConnectionQuality.none;
  }

  Future<ConnectionQuality> checkConnectionQuality() async {
    // Return poor/fair/good/none
  }
}

// Use in config
final config = DatumConfig(
  connectivityChecker: SmartConnectivityChecker(),
);

// Adaptive sync intervals
if (await connectivityChecker.isConnected()) {
  manager.startAutoSync('user123', interval: Duration(minutes: 5));
} else {
  manager.startAutoSync('user123', interval: Duration(hours: 1));
}
```

## Advanced Querying

### Complex Queries

Build sophisticated queries:

```dart
final complexQuery = DatumQueryBuilder<Task>()
  .where('status', isEqualTo: 'active')
  .where('priority', isGreaterThan: 3)
  .where('dueDate', isLessThan: DateTime.now().add(Duration(days: 7)))
  .where('tags', arrayContains: 'urgent')
  .orderBy('priority', descending: true)
  .orderBy('dueDate', descending: false)
  .limit(50)
  .withRelated(['assignee', 'comments'])
  .build();

// Execute query
final urgentTasks = await manager.query(complexQuery, userId: 'user123');
```

### Reactive Queries

Watch query results in real-time:

```dart
final subscription = manager.watchQuery(complexQuery, userId: 'user123')
  ?.listen((tasks) {
    print('Urgent tasks updated: ${tasks.length}');
    // UI updates automatically
  });
```

## Migration and Schema Evolution

### Schema Migrations

Handle database schema changes:

```dart
final config = DatumConfig(
  schemaVersion: 2,
  migrations: [
    Migration1To2(
      execute: (data) {
        // Transform v1 data to v2 format
        return {
          ...data,
          'newField': data['oldField'] ?? 'default',
        };
      },
    ),
  ],
  onMigrationError: (error, stack) {
    // Handle migration failures
    reportError(error, stack);
  },
);
```

### Migration Strategies

```dart
class Migration1To2 implements Migration {
  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> data) async {
    // Add new required fields
    return {
      ...data,
      'version': 2,
      'migratedAt': DateTime.now().toIso8601String(),
      // Transform existing fields
      'status': data['isCompleted'] ? 'completed' : 'pending',
    };
  }

  @override
  Future<Map<String, dynamic>> rollback(Map<String, dynamic> data) async {
    // Revert changes if needed
    return {
      ...data,
      'isCompleted': data['status'] == 'completed',
      // Remove added fields
    }..remove('version')..remove('migratedAt');
  }
}
```

## Production Monitoring

### Health Checks

Monitor system health:

```dart
// Periodic health checks
Timer.periodic(Duration(minutes: 5), (_) async {
  final health = await manager.checkHealth();
  if (health.status == DatumHealthStatus.unhealthy) {
    alertSystem('Manager unhealthy: ${health.message}');
  }
});

// Global health monitoring
Datum.instance.allHealths.listen((healthMap) {
  final unhealthy = healthMap.entries
    .where((e) => e.value.status == DatumHealthStatus.unhealthy);

  if (unhealthy.isNotEmpty) {
    alertSystem('Unhealthy managers: ${unhealthy.map((e) => e.key).join(', ')}');
  }
});
```

### Metrics Collection

Track performance metrics:

```dart
Datum.instance.metrics.listen((metrics) {
  // Report to monitoring system
  reportMetric('total_syncs', metrics.totalSyncOperations);
  reportMetric('successful_syncs', metrics.successfulSyncs);
  reportMetric('failed_syncs', metrics.failedSyncs);
  reportMetric('bytes_synced',
    metrics.totalBytesPushed + metrics.totalBytesPulled);
});
```

### Performance Profiling

Profile sync performance:

```dart
final stopwatch = Stopwatch()..start();
final result = await manager.synchronize('user123');
stopwatch.stop();

final duration = stopwatch.elapsed;
final throughput = result.syncedCount / duration.inSeconds;

print('Sync performance: $throughput items/second');
print('Data transferred: ${result.totalBytesTransferred} bytes');
```

This guide covers the advanced patterns you'll need for building robust, scalable applications with Datum. Combine these patterns based on your specific requirements and constraints.

## 🚀 What's Next

Looking for even more advanced features? Check out our **[planned improvements](/coming_soon)** including new adapter support, enhanced developer tools, and interactive learning resources.
