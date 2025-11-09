# Core Module




The Core module is the heart of the Datum ecosystem, encompassing the fundamental functionalities and architectural components. It orchestrates data management, synchronization, event handling, and conflict resolution.

## Sub-modules

<Info>
**Thread Safety**: Datum is designed to be thread-safe. All operations can be called from any isolate, and the framework handles synchronization internally.
</Info>

### Datum Singleton

The `Datum` class provides a global singleton instance that offers convenient access to all Datum functionality. It serves as the central entry point for initialization, global operations, and convenience methods.

**Key Features:**
- Global access to all registered entity managers
- Convenience methods for common operations
- Global synchronization control
- Health monitoring across all entities
- Metrics collection and reporting

**Initialization:**
```dart
// Initialize the singleton (required before use)
final result = await Datum.initialize(
  config: DatumConfig(),
  connectivityChecker: MyConnectivityChecker(),
  registrations: [/* entity registrations */],
);

if (result.isSuccess) {
  // Datum is ready to use
}
```

**Global Operations:**
- `Datum.manager<T>()`: Get manager for entity type
- `Datum.instance.synchronize(userId)`: Sync all entities
- `Datum.instance.startAutoSync(userId)`: Start auto-sync across all managers
- `Datum.instance.getRemoteSyncMetadata<T>(userId)`: Get remote sync metadata
- `Datum.instance.allHealths`: Monitor all entity health
- `Datum.instance.metrics`: Global metrics stream

### Manager

The Manager sub-module provides high-level interfaces for interacting with Datum's functionalities, primarily through the `DatumManager<T>` class.

#### DatumManager<T>

The main entry point for Datum operations, providing a comprehensive API for data management and synchronization.

**Initialization:**
- `DatumManager(LocalAdapter<T>, RemoteAdapter<T>, ...)`: Constructor with required adapters and optional configuration
- `initialize()`: Must be called before any other operations

**CRUD Operations:**
- `push(T item, {String userId, DataSource source, bool forceRemoteSync})`: Saves entity locally and queues for sync
- `read(String id, {String? userId})`: Retrieves single entity
- `readAll({String? userId})`: Retrieves all entities
- `delete(String id, String userId, ...)`: Deletes entity and queues for sync

**Batch Operations:**
- `saveMany(List<T> items, String userId, ...)`: Saves multiple entities
- `pushAndSync(T item, String userId, ...)`: Saves and immediately syncs
- `deleteAndSync(String id, String userId, ...)`: Deletes and immediately syncs

**Reactive Streams:**
- `eventStream`: Stream of all sync-related events
- `onDataChange`: Stream of data change events
- `onSyncStarted/onSyncProgress/onSyncCompleted`: Sync lifecycle events
- `onConflict`: Conflict detection events
- `watchAll({String? userId})`: Reactive stream of all entities
- `watchById(String id, String? userId)`: Reactive stream of single entity
- `watchStorageSize({String? userId})`: Reactive storage size monitoring

**Querying:**
- `query(DatumQuery query, DataSource source, String? userId)`: Executes queries against local or remote
- `watchQuery(DatumQuery query, String? userId)`: Reactive query results

**Synchronization:**
- `synchronize(String userId, ...)`: Manual synchronization
- `startAutoSync(String userId, Duration? interval)`: Enables periodic auto-sync
- `stopAutoSync({String? userId})`: Stops auto-sync
- `pauseSync()` / `resumeSync()`: Pause/resume all sync activity

**Cascading Delete:**
- `cascadeDelete(String id, String userId, ...)`: Delete entity and related entities based on cascade behaviors
- `deleteCascade(String entityId)`: Fluent API builder for cascade delete operations
- `executeCascadeDeleteWithOptions(String entityId, String userId, CascadeOptions options)`: Advanced cascade delete with full control

**User Management:**
- `switchUser(String? oldUserId, String newUserId, ...)`: Switches active user with configurable strategy

**Monitoring & Health:**
- `health`: Stream of health status
- `checkHealth()`: Performs health check
- `getPendingCount(String userId)`: Gets count of pending operations
- `getLastSyncResult(String userId)`: Gets result of last sync

### Engine

The Engine sub-module manages the core data synchronization and processing logic.

#### DatumSyncEngine<T>

Orchestrates the synchronization process between local and remote adapters.

**Key Methods:**
- `synchronize(String userId, ...)`: Executes sync process
- `checkForUserSwitch(String userId)`: Handles user switching logic

#### DatumConflictDetector<T>

Detects conflicts between local and remote data during synchronization.

#### QueueManager<T>

Manages the queue of pending synchronization operations.

**Key Methods:**
- `enqueue(DatumSyncOperation<T> operation)`: Adds operation to queue
- `getPending(String userId)`: Gets pending operations for user
- `getPendingCount(String userId)`: Gets count of pending operations

### Events

The Events sub-module handles and dispatches various events within the Datum system.

#### Event Types

**Sync Events:**
- `DatumSyncStartedEvent<T>`: Synchronization started
- `DatumSyncProgressEvent<T>`: Sync progress updates
- `DatumSyncCompletedEvent<T>`: Synchronization completed
- `DatumSyncErrorEvent<T>`: Sync errors

**Data Events:**
- `DataChangeEvent<T>`: Local data changes
- `ConflictDetectedEvent<T>`: Conflicts detected during sync
- `ConflictResolvedEvent<T>`: Conflicts resolved
- `UserSwitchedEvent<T>`: User switching
- `InitialSyncEvent<T>`: Initial sync completion

#### Event Streams

All events are accessible through the manager's event streams for reactive programming.

### Health

The Health sub-module provides mechanisms for monitoring the health and status of Datum.

#### DatumHealth

Represents the health status of the Datum system.

**Properties:**
- `status`: Current health status (healthy, degraded, unhealthy)
- `message`: Human-readable status description
- `timestamp`: When health was last checked
- `details`: Additional diagnostic information

#### Health Monitoring

- `checkHealth()`: Performs comprehensive health check of adapters and sync status
- `health`: Reactive stream of health status changes

### Middleware

The Middleware sub-module allows for custom processing and transformation of data operations.

#### DatumMiddleware<T>

Abstract class for implementing middleware that can transform data during save/retrieval operations.

**Key Methods:**
- `transformBeforeSave(T entity)`: Transform entity before saving
- `transformAfterFetch(T entity)`: Transform entity after fetching

**Usage:**
```dart
class EncryptionMiddleware extends DatumMiddleware<MyEntity> {
  @override
  Future<MyEntity> transformBeforeSave(MyEntity entity) async {
    // Encrypt sensitive fields
    return entity.copyWith(encryptedData: encrypt(entity.data));
  }

  @override
  Future<MyEntity> transformAfterFetch(MyEntity entity) async {
    // Decrypt sensitive fields
    return entity.copyWith(data: decrypt(entity.encryptedData));
  }
}
```

### Migration

The Migration sub-module manages database schema and data migrations.

#### Migration

Abstract class for implementing schema migrations.

**Key Methods:**
- `execute(Map<String, dynamic> data)`: Transforms data for new schema
- `rollback(Map<String, dynamic> data)`: Reverses migration (optional)

#### MigrationExecutor

Executes migrations in order, handling errors and rollbacks.

#### ErrorBoundary

Provides error handling and recovery strategies for operations that might fail.

**Strategies:**
- `isolate`: Logs errors but allows operation to continue with fallback values
- `retry`: Automatically retries failed operations up to a maximum number of attempts
- `fallback`: Uses fallback values or operations when errors occur
- `escalate`: Re-throws errors for external handling

**Built-in Boundaries:**
```dart
// Sync operation isolation
final boundary = ErrorBoundaries.syncIsolation<Task>();

// Adapter operation retries
final boundary = ErrorBoundaries.adapterRetry(maxRetries: 3);

// Read operations with fallbacks
final boundary = ErrorBoundaries.readWithFallback(fallbackValue: []);

// Observer error isolation
final boundary = ErrorBoundaries.observerIsolation();
```

**Usage:**
```dart
final result = await boundary.execute(() async {
  // Operation that might fail
  return await riskyOperation();
});
```

#### PerformanceMonitor

Monitors operation performance and detects regressions.

**Features:**
- Automatic baseline calculation from operation timings
- Regression detection with configurable thresholds
- Memory usage tracking (optional)
- Performance event streaming

**Usage:**
```dart
// Time an async operation
final result = await performanceMonitor.timeAsync('sync_operation', () async {
  return await performSync();
});

// Time a sync operation
final result = performanceMonitor.timeSync('query_operation', () {
  return performQuery();
});

// Listen for performance events
performanceMonitor.events.listen((event) {
  if (event is PerformanceRegressionEvent) {
    print('Performance regression detected: ${event.operationName}');
  }
});
```

### DatumEither

A sealed class for handling success and failure results in a type-safe manner.

**Key Methods:**
- `fold<T>(onFailure, onSuccess)`: Transforms the Either into a single value
- `onSuccess(Function(R r) callback)`: Executes callback if successful
- `onFailure(Function(L l, StackTrace? s) callback)`: Executes callback if failed
- `getSuccess()`: Returns success value or throws StateError
- `getError()`: Returns tuple of error value and stack trace
- `successOrNull`: Returns success value or null
- `errorOrNull`: Returns error value or null
- `isSuccess()`: Returns true if this is a Success
- `isFailure()`: Returns true if this is a Failure

**Usage:**
```dart
// Initialization result handling
final result = await Datum.initialize(config: config, /* ... */);

result.fold(
  onFailure: (error, stackTrace) {
    print('Initialization failed: $error');
    // Handle error
  },
  onSuccess: (success) {
    print('Initialization successful');
    // Continue with app
  },
);

// Or using convenience methods
if (result.isSuccess()) {
  final successValue = result.getSuccess();
  // Use success value
} else {
  final (error, stackTrace) = result.getError();
  // Handle error
}
```

### Models

The Models sub-module defines the data structures and entities used throughout Datum.

#### DatumEntityInterface

Interface for all entities managed by Datum. Provides flexible entity implementation through either inheritance or mixins.

**Required Properties:**
- `id`: Unique identifier
- `userId`: Owner user ID
- `createdAt`: Creation timestamp
- `modifiedAt`: Last modification timestamp
- `version`: Optimistic concurrency version
- `isDeleted`: Soft delete flag

**Key Methods:**
- `toDatumMap({MapTarget target})`: Serializes entity
- `diff(DatumEntityInterface oldVersion)`: Computes changes
- `copyWith({...})`: Creates modified copy

**Implementation Options:**

**Using DatumEntityMixin (Recommended):**
```dart
class Task with DatumEntityMixin {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final int version;
  final bool isDeleted;
  final String title;
  final String description;

  Task({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.modifiedAt,
    required this.version,
    required this.isDeleted,
    required this.title,
    required this.description,
  });

  @override
  Task copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? modifiedAt,
    int? version,
    bool? isDeleted,
    String? title,
    String? description,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      version: version ?? this.version,
      isDeleted: isDeleted ?? this.isDeleted,
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }

  @override
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local}) {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'version': version,
      'isDeleted': isDeleted,
      'title': title,
      'description': description,
    };
  }
}
```

**Using DatumEntityBase (Legacy):**
```dart
class Task extends DatumEntityBase {
  final String title;
  final String description;

  Task({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.modifiedAt,
    required super.version,
    required super.isDeleted,
    required this.title,
    required this.description,
  });

  @override
  Task copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? modifiedAt,
    int? version,
    bool? isDeleted,
    String? title,
    String? description,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      version: version ?? this.version,
      isDeleted: isDeleted ?? this.isDeleted,
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }

  @override
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local}) {
    return {
      ...super.toDatumMap(target: target),
      'title': title,
      'description': description,
    };
  }
}
```

#### RelationalDatumEntity

Extends `DatumEntityInterface` with relationship support for connecting entities.

**Additional Features:**
- `relations`: Map of entity relationships (BelongsTo, HasMany, HasOne, ManyToMany)
- Support for eager and lazy loading of related data
- Automatic relationship resolution during queries

**Relationship Types:**
- `BelongsTo<T>`: Current entity holds foreign key pointing to related entity
- `HasMany<T>`: Other entities hold foreign key pointing to this entity (one-to-many)
- `HasOne<T>`: Other entity holds foreign key pointing to this entity (one-to-one)
- `ManyToMany<T>`: Many-to-many relationship using a pivot/junction table

#### DatumSyncOperation<T>

Represents a pending synchronization operation.

**Properties:**
- `id`: Operation ID
- `userId`: Target user
- `type`: Operation type (create, update, delete)
- `entityId`: Target entity ID
- `data`: Entity data (for create/update)
- `delta`: Change delta (for update)
- `timestamp`: Operation timestamp

### Query

The Query sub-module provides tools for querying and filtering data.

#### DatumQuery

Defines query parameters for filtering and sorting data.

**Components:**
- `filters`: List of filter conditions
- `sorting`: List of sort descriptors
- `limit/offset`: Pagination parameters
- `logicalOperator`: AND/OR combination logic
- `withRelated`: Eager loading of relationships

#### DatumQueryBuilder

Fluent API for building complex queries.

**Example:**
```dart
final query = DatumQueryBuilder()
  .where('status', equals, 'active')
  .where('createdAt', greaterThan, DateTime.now().subtract(Duration(days: 7)))
  .orderBy('createdAt', descending: true)
  .limit(50)
  .withRelated(['author', 'comments'])
  .build();
```

#### Filter Operators

- `equals`, `notEquals`: Equality comparisons
- `greaterThan`, `lessThan`, `greaterThanOrEqual`, `lessThanOrEqual`: Range comparisons
- `contains`, `startsWith`, `endsWith`: String matching
- `isIn`, `isNotIn`: Set membership
- `isNull`, `isNotNull`: Null checks
- `arrayContains`: Array membership

### Resolver

The Resolver sub-module handles conflict resolution strategies during data synchronization.

#### Conflict Resolution Strategies

**LastWriteWinsResolver**: Resolves conflicts by choosing the most recently modified version.

**LocalPriorityResolver**: Always prefers local changes over remote.

**RemotePriorityResolver**: Always prefers remote changes over local.

**MergeResolver**: Attempts to merge conflicting changes intelligently.

**UserPromptResolver**: Presents conflicts to user for manual resolution.

#### Custom Resolvers

Implement `DatumConflictResolver<T>` for custom resolution logic.

### Sync

The Sync sub-module manages the overall data synchronization process.

#### DatumSyncExecutionStrategy

Defines how sync operations are processed.

**SequentialStrategy**: Processes operations one by one (default).

**ParallelStrategy**: Processes multiple operations concurrently.

#### DatumSyncRequestStrategy

Handles concurrent synchronization requests.

**SequentialRequestStrategy**: Queues requests, processes one at a time.

**ConcurrentRequestStrategy**: Allows multiple concurrent syncs.

#### DatumSyncScope

Defines the scope of a synchronization operation, allowing for partial or filtered syncs.

**Key Properties:**
- `query`: A `DatumQuery` used to filter data fetched from the remote source

**Usage:**
```dart
// Sync only active tasks
final scope = DatumSyncScope(
  query: DatumQueryBuilder<Task>()
    .where('isCompleted', equals, false)
    .build(),
);

final result = await Datum.manager<Task>().synchronize(
  'user123',
  scope: scope,
);
```

#### DatumSyncOptions<T>

Configuration options for synchronization operations.

**Key Properties:**
- `forceFullSync`: When `true`, forces a complete sync regardless of metadata comparison results
- `resolveConflicts`: Whether conflicts should be resolved during sync (default: `true`)
- `includeDeletes`: Whether delete operations should be included in sync (default: `true`)
- `direction`: Sync direction (push-then-pull, pull-then-push, push-only, pull-only)
- `timeout`: Maximum time allowed for sync operations

**Usage:**
```dart
// Force a full sync bypassing metadata comparison
final result = await Datum.manager<Task>().synchronize(
  'user123',
  options: DatumSyncOptions<Task>(
    forceFullSync: true,
    resolveConflicts: true,
  ),
);
```

#### Sync Optimization Features

Datum includes several optimization features to improve sync performance and reduce unnecessary network requests.

##### Metadata Comparison

Datum compares local and remote metadata before performing sync operations to avoid unnecessary data transfer:

```dart
// Automatic metadata comparison (enabled by default)
// Sync is skipped if:
// 1. Local and remote data hashes match
// 2. Entity counts are identical
// 3. No pending local operations exist

final result = await Datum.manager<Task>().synchronize('user123');
// May return DatumSyncResult.skipped if no changes detected
```

**Metadata Fields Compared:**
- Data hash values
- Entity counts per type
- Pending local operation count

##### Force Full Sync

Override metadata comparison when a complete sync is required:

```dart
final result = await Datum.manager<Task>().synchronize(
  'user123',
  options: DatumSyncOptions<Task>(forceFullSync: true),
);
```

##### Batch Processing

Large datasets are processed in configurable batches to optimize memory usage:

```dart
final config = DatumConfig(
  remoteSyncBatchSize: 100,    // Process remote items in batches
  remoteStreamBatchSize: 50,   // Stream items for memory efficiency
);
```

#### Sync Results and Statistics

**DatumSyncResult<T>**: Contains sync outcome, statistics, and any errors.

**DatumSyncStatistics**: Detailed metrics about sync performance and data transfer.
