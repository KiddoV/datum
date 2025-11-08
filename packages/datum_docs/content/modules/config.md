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

  // Sync behavior
  defaultSyncDirection: SyncDirection.pushThenPull,
  syncTimeout: Duration(seconds: 30),

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
);
```

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

This configuration system provides extensive control over Datum's behavior while maintaining sensible defaults for most use cases.
