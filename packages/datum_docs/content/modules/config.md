---
title: Configuration Module
---




The Configuration module provides comprehensive options for customizing Datum's behavior to match your application's requirements. Configuration affects everything from sync intervals to conflict resolution strategies.

<Info>
**Configuration Hierarchy**: Global config applies to all entities, but entity-specific configs override global settings for that entity type.
</Info>

## DatumConfig

The main configuration class that controls Datum's behavior globally and per-entity.

### Basic Configuration

```dart
final config = DatumConfig(
  // Logging and debugging
  enableLogging: true,

  // Auto-sync behavior
  autoStartSync: true,
  autoSyncInterval: Duration(minutes: 5),
  initialUserId: 'user123',

  // Delete behavior
  deleteBehavior: DeleteBehavior.hardDelete, // or softDelete

  // Sync behavior
  defaultSyncDirection: SyncDirection.pushThenPull,
  syncTimeout: Duration(seconds: 30),
  defaultSyncOptions: DatumSyncOptions(
    forceFullSync: false,
    resolveConflicts: true,
  ),

  // Schema management
  schemaVersion: 1,
  migrations: [Migration1To2()],

  // Error handling
  errorRecoveryStrategy: DatumErrorRecoveryStrategy(
    maxRetries: 3,
    backoffStrategy: ExponentialBackoffStrategy(),
  ),

  // User switching
  defaultUserSwitchStrategy: UserSwitchStrategy.syncThenSwitch,

  // Performance tuning
  syncExecutionStrategy: SequentialStrategy(),
  syncRequestStrategy: SequentialRequestStrategy(),
  remoteEventDebounceTime: Duration(milliseconds: 100),
  changeCacheDuration: Duration(seconds: 30),

  // Performance tuning for sync operations
  remoteSyncBatchSize: 100,
  remoteStreamBatchSize: 50,
  progressEventFrequency: 50,

  // Cold start synchronization
  coldStartConfig: ColdStartConfig(
    strategy: ColdStartStrategy.adaptive,
    maxDuration: Duration(seconds: 15),
    syncThreshold: Duration(hours: 1),
    initialDelay: Duration(milliseconds: 500),
  ),
);
```

### Delete Behavior Configuration

Configure how delete operations are handled globally:

```dart
final config = DatumConfig(
  deleteBehavior: DeleteBehavior.hardDelete, // Default: immediately remove from local storage
  // Or
  deleteBehavior: DeleteBehavior.softDelete, // Mark as deleted locally, queue for sync
);
```

#### Delete Behavior Options

- **`DeleteBehavior.hardDelete`**: Immediately removes items from local storage (default)
- **`DeleteBehavior.softDelete`**: Marks items as deleted locally and queues the delete operation for synchronization

#### Hard Delete Behavior

```dart
// Items are immediately removed from local storage
await manager.delete('task123', userId: 'user1');
// Item is gone from local storage immediately
// Delete operation is queued for remote sync
```

#### Soft Delete Behavior

```dart
// Items are marked as deleted locally but remain in storage
await manager.delete('task123', userId: 'user1');
// Item remains in local storage with isDeleted = true
// Delete operation is queued for remote sync
// Item will be removed after successful sync
```

#### Per-Operation Override

Override the global delete behavior for specific operations:

```dart
// Override global config for specific delete operations
await manager.delete(
  'task123',
  userId: 'user1',
  behavior: DeleteBehavior.softDelete, // Override global hardDelete setting
);

// Or use the sync method with behavior override
await manager.deleteAndSync(
  'task123',
  userId: 'user1',
  behavior: DeleteBehavior.hardDelete, // Override global softDelete setting
);
```

<Info>
**Delete Behavior Choice**: Use `hardDelete` for immediate local cleanup, `softDelete` for guaranteed sync of delete operations.
</Info>

### Default Sync Options

Configure default synchronization behavior that applies to all sync operations:

```dart
final config = DatumConfig(
  defaultSyncOptions: DatumSyncOptions(
    forceFullSync: false,        // Force full sync bypassing metadata comparison
    resolveConflicts: true,      // Whether to resolve conflicts during sync
    includeDeletes: true,        // Include delete operations in sync
    direction: SyncDirection.pushThenPull,  // Sync direction
    timeout: Duration(seconds: 30),         // Sync operation timeout
  ),
);
```

**Key Options:**
- **`forceFullSync`**: When `true`, forces a complete sync regardless of metadata comparison results
- **`resolveConflicts`**: Whether conflicts should be resolved during sync (default: `true`)
- **`includeDeletes`**: Whether delete operations should be included in sync (default: `true`)
- **`direction`**: The sync direction (push-then-pull, pull-then-push, etc.)
- **`timeout`**: Maximum time allowed for sync operations

### Sync Direction Options

Control the order and type of synchronization:

- **`SyncDirection.pushThenPull`**: Push local changes first, then pull remote changes (default)
- **`SyncDirection.pullThenPush`**: Pull remote changes first, then push local changes
- **`SyncDirection.pushOnly`**: Only push local changes to remote
- **`SyncDirection.pullOnly`**: Only pull remote changes to local

### Execution Strategies

Control how sync operations are processed:

#### SequentialStrategy (Default)

```dart
final config = DatumConfig(
  syncExecutionStrategy: SequentialStrategy(),
);
```

Processes operations one by one. Reliable but potentially slower for large batches.

#### ParallelStrategy

```dart
final config = DatumConfig(
  syncExecutionStrategy: ParallelStrategy(
    batchSize: 10, // Process 10 operations concurrently
  ),
);
```

Processes multiple operations concurrently. Faster for large batches but uses more resources.

### Request Strategies

Handle concurrent synchronization requests:

#### SequentialRequestStrategy (Default)

```dart
final config = DatumConfig(
  syncRequestStrategy: SequentialRequestStrategy(),
);
```

Queues concurrent sync requests and processes them in order.

#### SkipConcurrentStrategy

```dart
final config = DatumConfig(
  syncRequestStrategy: SkipConcurrentStrategy(),
);
```

Skips new sync requests if a sync is already in progress.

### Error Recovery

Configure automatic retry behavior for failed operations:

```dart
final config = DatumConfig(
  errorRecoveryStrategy: DatumErrorRecoveryStrategy(
    maxRetries: 3,
    backoffStrategy: ExponentialBackoffStrategy(
      initialDelay: Duration(seconds: 1),
      maxDelay: Duration(minutes: 5),
      multiplier: 2.0,
    ),
  ),
);
```

#### Built-in Backoff Strategies

- **`ExponentialBackoffStrategy`**: Exponential backoff with configurable parameters
- **`LinearBackoffStrategy`**: Linear delay increase
- **`FixedBackoffStrategy`**: Fixed delay between retries
- **`ImmediateRetryStrategy`**: No delay between retries

### User Switch Strategies

Control behavior when switching between users:

- **`UserSwitchStrategy.syncThenSwitch`**: Sync current user's data before switching
- **`UserSwitchStrategy.clearAndFetch`**: Clear new user's local data and fetch from remote
- **`UserSwitchStrategy.promptIfUnsyncedData`**: Fail switch if current user has unsynced data
- **`UserSwitchStrategy.keepLocal`**: Switch without any data modifications

### Conflict Resolution

Set default conflict resolution strategies:

```dart
final config = DatumConfig(
  defaultConflictResolver: LastWriteWinsResolver<Task>(),
  // Or use custom resolver
  defaultConflictResolver: CustomResolver(),
);
```

### Migration Configuration

Handle schema evolution:

```dart
final config = DatumConfig(
  schemaVersion: 2,
  migrations: [
    Migration1To2(execute: migrateV1ToV2, rollback: rollbackV1ToV2),
  ],
  onMigrationError: (error, stack) {
    // Handle migration failures
    reportError(error, stack);
  },
);
```

## Entity-Specific Configuration

Configure behavior per entity type:

```dart
final taskConfig = DatumConfig<Task>(
  // Task-specific settings
  autoSyncInterval: Duration(minutes: 2), // More frequent sync for tasks
  defaultConflictResolver: LocalPriorityResolver<Task>(), // Prefer local changes
  syncExecutionStrategy: ParallelStrategy(batchSize: 5),
);

DatumRegistration<Task>(
  localAdapter: HiveTaskAdapter(),
  remoteAdapter: RestApiTaskAdapter(),
  config: taskConfig,
);
```

## Connectivity Configuration

Configure network connectivity checking:

```dart
class CustomConnectivityChecker extends DatumConnectivityChecker {
  @override
  Future<bool> isConnected() async {
    // Custom connectivity logic
    return await checkNetworkStatus();
  }
}

final config = DatumConfig(
  connectivityChecker: CustomConnectivityChecker(),
);
```

## Observer Configuration

Add global and local observers:

```dart
// Global observers (applied to all entities)
final globalObservers = [
  AuditObserver(),
  MetricsObserver(),
];

// Local observers (entity-specific)
final localObservers = [
  TaskObserver(),
  ValidationObserver(),
];

DatumRegistration<Task>(
  // ... adapters
  observers: localObservers,
);

// Add global observers during initialization
await Datum.initialize(
  config: config,
  observers: globalObservers,
  // ... other params
);
```

## Performance Tuning

### Debouncing Remote Events

Reduce the frequency of remote change processing:

```dart
final config = DatumConfig(
  remoteEventDebounceTime: Duration(milliseconds: 500), // Buffer events for 500ms
);
```

### Change Cache Duration

Control how long recent changes are cached to prevent duplicates:

```dart
final config = DatumConfig(
  changeCacheDuration: Duration(minutes: 1), // Cache changes for 1 minute
);
```

### Sync Timeouts

Set timeouts for sync operations:

```dart
final config = DatumConfig(
  syncTimeout: Duration(minutes: 2), // 2 minute timeout
);
```

### Batch Processing

Configure batch sizes for memory-efficient sync operations:

```dart
final config = DatumConfig(
  remoteSyncBatchSize: 100,    // Process 100 remote items per batch
  remoteStreamBatchSize: 50,   // Stream 50 items at a time
  progressEventFrequency: 50,  // Emit progress events every 50 items
);
```

**Batch Processing Options:**
- **`remoteSyncBatchSize`**: Number of remote items processed together (default: 100)
- **`remoteStreamBatchSize`**: Number of items streamed at once for memory efficiency (default: 50)
- **`progressEventFrequency`**: How often progress events are emitted during sync (default: 50)

### Cold Start Configuration

Configure automatic synchronization behavior when the app is fully closed and reopened:

```dart
final config = DatumConfig(
  coldStartConfig: ColdStartConfig(
    strategy: ColdStartStrategy.adaptive,    // Sync strategy
    maxDuration: Duration(seconds: 15),      // Max sync time to prevent blocking UI
    syncThreshold: Duration(hours: 1),       // Minimum time between cold starts
    initialDelay: Duration(milliseconds: 500), // Delay before starting sync
  ),
);
```

#### Cold Start Strategies

- **`ColdStartStrategy.disabled`**: No automatic sync on cold start
- **`ColdStartStrategy.fullSync`**: Always perform full sync on cold start (default behavior)
- **`ColdStartStrategy.adaptive`**: Smart sync based on time since last sync and other factors
- **`ColdStartStrategy.incremental`**: Only sync changes since last successful sync
- **`ColdStartStrategy.priorityBased`**: Sync critical/high-priority data first, then background sync remaining data

#### Cold Start Configuration Options

- **`strategy`**: The synchronization strategy to use (default: `adaptive`)
- **`maxDuration`**: Maximum duration allowed for cold start sync to prevent blocking UI (default: 15 seconds)
- **`syncThreshold`**: Time threshold after which cold start sync is triggered (default: 1 hour)
- **`initialDelay`**: Delay before starting cold start sync to allow UI to load (default: 500ms)

## Initialization Configuration

Configure Datum initialization behavior:

```dart
await Datum.initialize(
  config: DatumConfig(
    // Global config applied to all entities
    enableLogging: true,
    autoStartSync: true,
  ),
  connectivityChecker: MyConnectivityChecker(),
  registrations: [
    // Entity-specific configs override globals
    DatumRegistration<Task>(
      localAdapter: HiveTaskAdapter(),
      remoteAdapter: RestApiTaskAdapter(),
      config: DatumConfig<Task>(
        autoSyncInterval: Duration(minutes: 1), // Override global setting
      ),
    ),
  ],
  observers: [GlobalObserver()],
);
```

<Warning>
**Critical Settings**: Always test configuration changes in development first. Settings like `syncExecutionStrategy` and `conflictResolver` can significantly impact performance and data integrity.
</Warning>

## Configuration Best Practices

### Development vs Production

```dart
DatumConfig getConfig(String environment) {
  switch (environment) {
    case 'development':
      return DatumConfig(
        enableLogging: true,
        autoSyncInterval: Duration(seconds: 30), // Frequent sync for testing
        errorRecoveryStrategy: DatumErrorRecoveryStrategy(
          maxRetries: 1, // Fail fast in development
        ),
      );

    case 'production':
      return DatumConfig(
        enableLogging: false,
        autoSyncInterval: Duration(minutes: 5),
        errorRecoveryStrategy: DatumErrorRecoveryStrategy(
          maxRetries: 5, // More retries in production
        ),
      );

    default:
      return DatumConfig();
  }
}
```

### Feature Flags

Use configuration for feature toggles:

```dart
class FeatureConfig {
  final bool enableOfflineSync;
  final bool enableConflictResolution;
  final bool enableMetrics;

  const FeatureConfig({
    this.enableOfflineSync = true,
    this.enableConflictResolution = true,
    this.enableMetrics = false,
  });

  DatumConfig toDatumConfig() {
    return DatumConfig(
      autoStartSync: enableOfflineSync,
      defaultConflictResolver: enableConflictResolution
          ? LastWriteWinsResolver()
          : null,
      // Configure metrics collection
    );
  }
}
```

### Environment-Specific Settings

```dart
DatumConfig getEnvironmentConfig() {
  final environment = Platform.environment['ENVIRONMENT'] ?? 'development';

  return DatumConfig(
    // Adjust settings based on environment
    enableLogging: environment == 'development',
    autoSyncInterval: environment == 'production'
        ? Duration(minutes: 5)
        : Duration(seconds: 30),
    syncTimeout: environment == 'production'
        ? Duration(minutes: 5)
        : Duration(seconds: 10),
  );
}
```

## Monitoring Configuration

Configure health checks and monitoring:

```dart
final config = DatumConfig(
  // Enable detailed health monitoring
  enableHealthChecks: true,

  // Configure health check intervals
  healthCheckInterval: Duration(minutes: 5),

  // Set up metrics collection
  metricsEnabled: true,
  metricsRetentionPeriod: Duration(days: 7),
);
```

## Migration Strategies

### Schema Versioning

```dart
class AppMigrations {
  static const currentVersion = 3;

  static List<Migration> get all => [
    Migration1To2(execute: _migrateToV2, rollback: _rollbackToV1),
    Migration2To3(execute: _migrateToV3, rollback: _rollbackToV2),
  ];

  static Map<String, dynamic> _migrateToV2(Map<String, dynamic> data) {
    // Add new fields with defaults
    return {
      ...data,
      'priority': data['priority'] ?? 'medium',
      'version': 2,
    };
  }

  static Map<String, dynamic> _rollbackToV1(Map<String, dynamic> data) {
    // Remove added fields
    return Map.from(data)..remove('priority')..remove('version');
  }

  // ... more migration methods
}
```

Use in configuration:

```dart
final config = DatumConfig(
  schemaVersion: AppMigrations.currentVersion,
  migrations: AppMigrations.all,
);
```

## DatumConfigPresets

Configuration presets provide optimized settings for common use cases, allowing you to quickly configure Datum for different environments and scenarios without manually tuning every parameter.

### Available Presets

#### Development Preset

Optimized for development environments with verbose logging, short timeouts, and frequent cleanup:

```dart
final config = DatumConfigPresets.development();

// Equivalent to:
DatumConfig(
  autoSyncInterval: Duration(minutes: 5),
  autoStartSync: true,
  syncTimeout: Duration(seconds: 30),
  enableLogging: true,
  logLevel: LogLevel.debug,
  enablePerformanceLogging: true,
  performanceLogThreshold: Duration(milliseconds: 50),
  changeCacheDuration: Duration(seconds: 10),
  maxChangeCacheSize: 500,
  changeCacheCleanupInterval: Duration(seconds: 15),
  remoteSyncBatchSize: 50,
  remoteStreamBatchSize: 25,
  progressEventFrequency: 25,
  remoteEventDebounceTime: Duration(milliseconds: 25),
);
```

**Features:**
- Verbose logging for debugging
- Short timeouts for faster feedback
- Frequent cache cleanup
- Auto-sync enabled with short intervals

#### Production Preset

Optimized for production environments with minimal logging, longer timeouts, and performance tuning:

```dart
final config = DatumConfigPresets.production();

// Equivalent to:
DatumConfig(
  autoSyncInterval: Duration(minutes: 30),
  autoStartSync: true,
  syncTimeout: Duration(minutes: 5),
  enableLogging: true,
  logLevel: LogLevel.warn,
  enablePerformanceLogging: false,
  changeCacheDuration: Duration(minutes: 2),
  maxChangeCacheSize: 2000,
  changeCacheCleanupInterval: Duration(minutes: 5),
  remoteSyncBatchSize: 200,
  remoteStreamBatchSize: 100,
  progressEventFrequency: 100,
  remoteEventDebounceTime: Duration(milliseconds: 100),
);
```

**Features:**
- Minimal logging for performance
- Longer timeouts for reliability
- Optimized batch sizes
- Auto-sync enabled with reasonable intervals

#### High Performance Preset

Maximum performance configuration with large batches and minimal overhead:

```dart
final config = DatumConfigPresets.highPerformance();

// Equivalent to:
DatumConfig(
  autoSyncInterval: Duration(hours: 1),
  autoStartSync: true,
  syncTimeout: Duration(minutes: 10),
  enableLogging: false,
  logLevel: LogLevel.error,
  enablePerformanceLogging: false,
  changeCacheDuration: Duration(minutes: 5),
  maxChangeCacheSize: 5000,
  changeCacheCleanupInterval: Duration(minutes: 15),
  remoteSyncBatchSize: 500,
  remoteStreamBatchSize: 250,
  progressEventFrequency: 250,
  remoteEventDebounceTime: Duration(milliseconds: 200),
);
```

**Features:**
- Minimal logging and overhead
- Large batch sizes for efficiency
- Extended cache durations
- Auto-sync with longer intervals

#### Low Memory Preset

Memory-efficient configuration with small caches and frequent cleanup:

```dart
final config = DatumConfigPresets.lowMemory();

// Equivalent to:
DatumConfig(
  autoSyncInterval: Duration(hours: 2),
  autoStartSync: false,
  syncTimeout: Duration(minutes: 2),
  enableLogging: true,
  logLevel: LogLevel.info,
  enablePerformanceLogging: false,
  changeCacheDuration: Duration(seconds: 30),
  maxChangeCacheSize: 200,
  changeCacheCleanupInterval: Duration(seconds: 30),
  remoteSyncBatchSize: 25,
  remoteStreamBatchSize: 10,
  progressEventFrequency: 10,
  remoteEventDebounceTime: Duration(milliseconds: 10),
);
```

**Features:**
- Small cache sizes
- Frequent cache cleanup
- Minimal batch sizes
- Auto-sync disabled by default

#### Testing Preset

Optimized for testing environments with minimal logging and fast timeouts:

```dart
final config = DatumConfigPresets.testing();

// Equivalent to:
DatumConfig(
  autoSyncInterval: Duration(hours: 1),
  autoStartSync: false,
  syncTimeout: Duration(seconds: 10),
  enableLogging: false,
  logLevel: LogLevel.error,
  enablePerformanceLogging: false,
  changeCacheDuration: Duration(seconds: 5),
  maxChangeCacheSize: 50,
  changeCacheCleanupInterval: Duration(seconds: 5),
  remoteSyncBatchSize: 10,
  remoteStreamBatchSize: 5,
  progressEventFrequency: 5,
  remoteEventDebounceTime: Duration(milliseconds: 1),
);
```

**Features:**
- Minimal logging
- Very short timeouts
- Small caches for fast cleanup
- Auto-sync disabled

#### Offline-First Preset

Optimized for offline-first applications with extended caching and moderate sync intervals:

```dart
final config = DatumConfigPresets.offlineFirst();

// Equivalent to:
DatumConfig(
  autoSyncInterval: Duration(minutes: 15),
  autoStartSync: true,
  syncTimeout: Duration(minutes: 3),
  enableLogging: true,
  logLevel: LogLevel.info,
  enablePerformanceLogging: false,
  changeCacheDuration: Duration(minutes: 10),
  maxChangeCacheSize: 1000,
  changeCacheCleanupInterval: Duration(minutes: 10),
  remoteSyncBatchSize: 100,
  remoteStreamBatchSize: 50,
  progressEventFrequency: 50,
  remoteEventDebounceTime: Duration(milliseconds: 50),
);
```

**Features:**
- Extended cache durations
- Auto-sync enabled with moderate intervals
- Larger batch sizes for efficiency
- Moderate logging

#### Real-Time Preset

Optimized for real-time applications with short debounce times and frequent sync:

```dart
final config = DatumConfigPresets.realTime();

// Equivalent to:
DatumConfig(
  autoSyncInterval: Duration(seconds: 30),
  autoStartSync: true,
  syncTimeout: Duration(seconds: 30),
  enableLogging: true,
  logLevel: LogLevel.warn,
  enablePerformanceLogging: false,
  changeCacheDuration: Duration(seconds: 10),
  maxChangeCacheSize: 100,
  changeCacheCleanupInterval: Duration(seconds: 10),
  remoteSyncBatchSize: 20,
  remoteStreamBatchSize: 10,
  progressEventFrequency: 10,
  remoteEventDebounceTime: Duration(milliseconds: 10),
);
```

**Features:**
- Very short debounce times
- Frequent auto-sync
- Small batch sizes for responsiveness
- Minimal caching

### Customizing Presets

Extend existing presets with custom values:

```dart
// Start with production preset and customize
final customConfig = DatumConfigPresets.custom(
  base: DatumConfigPresets.production(),
  autoSyncInterval: Duration(minutes: 10), // Override sync interval
  enableLogging: true,                      // Override logging
  maxChangeCacheSize: 3000,                 // Override cache size
);

// Or create entirely custom configuration
final customConfig = DatumConfig(
  // Mix and match settings from different presets
  autoSyncInterval: DatumConfigPresets.development().autoSyncInterval,
  remoteSyncBatchSize: DatumConfigPresets.highPerformance().remoteSyncBatchSize,
  enableLogging: true,
  // ... other custom settings
);
```

### Preset Selection Guide

Choose the appropriate preset based on your use case:

| Preset | Environment | Use Case |
|--------|-------------|----------|
| `development()` | Development | Fast feedback, debugging, testing |
| `production()` | Production | Balanced performance and reliability |
| `highPerformance()` | High-throughput | Maximum performance, large datasets |
| `lowMemory()` | Memory-constrained | Mobile apps, embedded systems |
| `testing()` | Automated testing | Fast test execution, minimal overhead |
| `offlineFirst()` | Offline-capable | Apps that work offline extensively |
| `realTime()` | Live collaboration | Real-time sync, instant updates |

### Environment-Based Configuration

```dart
DatumConfig getConfigForEnvironment(String environment) {
  switch (environment) {
    case 'development':
      return DatumConfigPresets.development();
    case 'staging':
      return DatumConfigPresets.custom(
        base: DatumConfigPresets.production(),
        enableLogging: true,
        logLevel: LogLevel.debug,
      );
    case 'production':
      return DatumConfigPresets.production();
    case 'testing':
      return DatumConfigPresets.testing();
    default:
      return DatumConfigPresets.production();
  }
}

// Usage
final config = getConfigForEnvironment(Platform.environment['ENVIRONMENT'] ?? 'development');
```

This configuration system provides extensive control over Datum's behavior while maintaining sensible defaults for most use cases.
