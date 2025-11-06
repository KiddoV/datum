---
title: Initialization & Global API
---
This guide covers how to initialize Datum and use the global API for managing your data synchronization.

## Overview

The `Datum` class is the central entry point for all Datum operations. It manages entity registration, synchronization, and provides global access to managers.

## Initialization

Before using any Datum features, you must initialize the singleton instance:

```dart
import 'package:datum/datum.dart';

void main() async {
  // Initialize Datum
  final datum = await Datum.initialize(
    config: DatumConfig(
      // Configuration options
      autoSyncInterval: Duration(minutes: 15),
      enableLogging: true,
    ),
    connectivityChecker: MyConnectivityChecker(),
    registrations: [
      DatumRegistration<Task>(
        localAdapter: HiveTaskAdapter(),
        remoteAdapter: SupabaseTaskAdapter(),
      ),
      DatumRegistration<User>(
        localAdapter: HiveUserAdapter(),
        remoteAdapter: SupabaseUserAdapter(),
      ),
    ],
  );

  // Now you can use Datum
  runApp(MyApp());
}
```

### Configuration Options

```dart
final config = DatumConfig(
  // Synchronization
  autoSyncInterval: Duration(minutes: 15),        // How often to auto-sync
  autoStartSync: true,                           // Start sync automatically
  syncTimeout: Duration(seconds: 30),            // Sync operation timeout
  defaultSyncDirection: SyncDirection.pushThenPull, // Default sync behavior

  // Conflict Resolution
  defaultConflictResolver: LastWriteWinsResolver(), // Default resolver

  // User Management
  defaultUserSwitchStrategy: UserSwitchStrategy.syncThenSwitch,
  initialUserId: null,                           // User to sync on startup

  // Performance
  remoteEventDebounceTime: Duration(milliseconds: 50),
  changeCacheDuration: Duration(seconds: 5),

  // Error Handling
  errorRecoveryStrategy: DatumErrorRecoveryStrategy(
    maxRetries: 3,
    backoffStrategy: ExponentialBackoffStrategy(),
  ),

  // Schema Management
  schemaVersion: 1,
  migrations: [MyMigration()],

  // Execution Strategies
  syncExecutionStrategy: SequentialStrategy(),
  syncRequestStrategy: SequentialRequestStrategy(),
);
```

### Connectivity Checker

You must provide a connectivity checker implementation:

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

class MyConnectivityChecker implements DatumConnectivityChecker {
  final _connectivity = Connectivity();

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  @override
  Stream<bool> get onStatusChange {
    return _connectivity.onConnectivityChanged.map((results) {
      return !results.contains(ConnectivityResult.none);
    });
  }
}
```

## Entity Registration

Register your entities with their adapters:

```dart
final registrations = [
  DatumRegistration<Task>(
    localAdapter: HiveTaskAdapter(),
    remoteAdapter: SupabaseTaskAdapter(),
    conflictResolver: MergeResolver(),
    middlewares: [EncryptionMiddleware()],
    observers: [TaskObserver()],
    config: DatumConfig(
      // Entity-specific config overrides
      autoSyncInterval: Duration(minutes: 5),
    ),
  ),
];
```

## Global CRUD Operations

Once initialized, you can perform CRUD operations globally:

```dart
// Create
final newTask = await Datum.create(Task(
  id: 'task-1',
  userId: 'user-123',
  title: 'Learn Datum',
  createdAt: DateTime.now(),
  modifiedAt: DateTime.now(),
));

// Read
final task = await Datum.read<Task>('task-1', userId: 'user-123');
final allTasks = await Datum.readAll<Task>(userId: 'user-123');

// Update
final updatedTask = await Datum.update(task.copyWith(title: 'Learn Datum v2'));

// Delete
final deleted = await Datum.delete<Task>(id: 'task-1', userId: 'user-123');

// Batch operations
final newTasks = await Datum.createMany<Task>(
  items: [task1, task2, task3],
  userId: 'user-123',
);
```

## Manager Access

Access specific managers for advanced operations:

```dart
// Get manager for a type
final taskManager = Datum.manager<Task>();

// Perform manager-specific operations
await taskManager.startAutoSync('user-123');
final pendingCount = await taskManager.getPendingCount('user-123');
```

## Global Synchronization

Trigger synchronization across all registered entities:

```dart
// Sync all entities for a user
final result = await Datum.instance.synchronize('user-123');

// Sync with custom options
final result = await Datum.instance.synchronize(
  'user-123',
  options: DatumSyncOptions(
    direction: SyncDirection.pullThenPush,
    includeDeletes: true,
  ),
);
```

## Reactive Streams

Watch for changes globally:

```dart
// Watch all tasks
final taskStream = Datum.watchAll<Task>(userId: 'user-123');

// Watch specific task
final taskStream = Datum.watchById<Task>('task-1', 'user-123');

// Watch with pagination
final paginatedStream = Datum.watchAllPaginated<Task>(
  PaginationConfig(limit: 20, offset: 0),
  userId: 'user-123',
);
```

## Querying

Perform queries across entities:

```dart
// Simple query
final completedTasks = await Datum.query<Task>(
  DatumQuery(
    filters: [Filter('isCompleted', FilterOperator.equals, true)],
    sorting: [SortDescriptor('createdAt', SortDirection.descending)],
  ),
  source: DataSource.local,
  userId: 'user-123',
);

// Complex query with relationships
final postsWithAuthors = await Datum.query<Post>(
  DatumQuery(
    filters: [Filter('createdAt', FilterOperator.greaterThan, DateTime.now().subtract(Duration(days: 7)))],
    withRelated: ['author'],
    sorting: [SortDescriptor('createdAt', SortDirection.descending)],
    limit: 50,
  ),
  source: DataSource.remote,
  userId: 'user-123',
);
```

## Health Monitoring

Check the health of all managers:

```dart
// Check health of all managers
final allHealths = await Datum.instance.allHealths.first;

// Check health of specific manager
final taskHealth = await Datum.checkHealth<Task>();
```

## Metrics and Monitoring

Access global metrics and status:

```dart
// Global metrics stream
final metricsStream = Datum.instance.metrics;

// Current metrics
final currentMetrics = Datum.instance.currentMetrics;

// User-specific status
final userStatus = Datum.instance.statusForUser('user-123');
```

## Error Handling

Handle initialization and runtime errors:

```dart
try {
  final datum = await Datum.initialize(/* ... */);
} on DatumException catch (e) {
  switch (e.code) {
    case 'entity_already_registered':
      print('Entity already registered');
      break;
    case 'network_error':
      print('Network connectivity issue');
      break;
    default:
      print('Initialization failed: ${e.message}');
  }
}
```

## Lifecycle Management

Properly dispose of resources when shutting down:

```dart
// Pause all operations
Datum.instance.pauseSync();

// Resume operations
Datum.instance.resumeSync();

// Complete shutdown
await Datum.instance.dispose();
```

## Best Practices

1. **Initialize early**: Call `Datum.initialize()` as early as possible in your app lifecycle
2. **Handle connectivity**: Always provide a reliable connectivity checker
3. **Configure appropriately**: Tune configuration options based on your app's needs
4. **Monitor health**: Regularly check health status and handle degraded states
5. **Clean up**: Always dispose of Datum when shutting down your app
6. **Error handling**: Implement proper error handling for all Datum operations</content>
