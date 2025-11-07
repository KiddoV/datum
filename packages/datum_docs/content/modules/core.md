# Core Module

The Core module is the heart of the Datum ecosystem, encompassing the fundamental functionalities and architectural components. It orchestrates data management, synchronization, event handling, and conflict resolution.

## Sub-modules

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

### Models

The Models sub-module defines the data structures and entities used throughout Datum.

#### DatumEntityInterface

Base class for all entities managed by Datum.

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

#### Sync Results and Statistics

**DatumSyncResult<T>**: Contains sync outcome, statistics, and any errors.

**DatumSyncStatistics**: Detailed metrics about sync performance and data transfer.
