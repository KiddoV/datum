# Adapter Module




The Adapter module provides the abstraction layer that allows Datum to work with any local database and remote backend. This module defines the interfaces and base implementations for adapters.

## Local Adapters

Local adapters handle data persistence on the device. Datum provides built-in adapters for popular databases and a framework for creating custom ones.

### Built-in Local Adapters

#### HiveAdapter

A high-performance, lightweight key-value database adapter for Hive.

**Features:**
- Fast read/write operations
- Type-safe storage with generated type adapters
- Automatic JSON serialization
- Box management per user/entity

**Usage:**
```dart
class TaskAdapter extends HiveAdapter<Task> {
  TaskAdapter() : super(
    boxName: 'tasks',
    fromJson: Task.fromJson,
    toJson: (task) => task.toJson(),
  );
}
```

#### IsarAdapter

An adapter for the Isar database, offering advanced querying and relationships.

**Features:**
- Advanced querying capabilities
- Built-in indexing support
- Multi-platform support
- Schema migration support

**Usage:**
```dart
class TaskAdapter extends IsarAdapter<Task> {
  TaskAdapter(Isar isar) : super(
    isar: isar,
    collectionName: 'Task',
    fromJson: Task.fromJson,
    toJson: (task) => task.toJson(),
  );
}
```

### Custom Local Adapters

Implement `LocalAdapter<T>` to create adapters for other databases.

**Required Methods:**
- `initialize()`: Set up the adapter
- `create(T entity)`: Insert new entity
- `read(String id, {String? userId})`: Retrieve entity by ID
- `readAll({String? userId})`: Retrieve all entities
- `patch(String id, Map<String, dynamic> delta, {String? userId})`: Update entity
- `delete(String id, {String? userId})`: Delete entity
- `query(DatumQuery query, {String? userId})`: Execute queries
- `getAllUserIds()`: Get all user IDs with data
- `clearUserData(String userId)`: Remove all data for a user
- `changeStream()`: Stream of data changes
- `watchAll({String? userId, bool includeInitialData})`: Reactive all entities
- `watchById(String id, {String? userId})`: Reactive single entity
- `watchQuery(DatumQuery query, {String? userId})`: Reactive queries
- `getStorageSize({String? userId})`: Get storage size
- `watchStorageSize({String? userId})`: Watch storage size changes

## Remote Adapters

Remote adapters handle communication with backend services and APIs.

### Built-in Remote Adapters

#### RestApiAdapter

A flexible REST API adapter for HTTP-based backends.

**Features:**
- Configurable endpoints and HTTP methods
- Automatic retry logic
- Custom headers and authentication
- JSON serialization

**Usage:**
```dart
class TaskApiAdapter extends RestApiAdapter<Task> {
  TaskApiAdapter(Dio dio) : super(
    dio: dio,
    baseUrl: 'https://api.example.com',
    endpoints: ApiEndpoints(
      create: '/tasks',
      read: '/tasks/:id',
      readAll: '/tasks',
      update: '/tasks/:id',
      delete: '/tasks/:id',
    ),
    fromJson: Task.fromJson,
    toJson: (task) => task.toJson(),
  );
}
```

#### SupabaseAdapter

Specialized adapter for Supabase backend services.

**Features:**
- Real-time subscriptions
- Built-in authentication
- Row Level Security (RLS) support
- Automatic conflict detection

#### FirebaseAdapter

Adapter for Firebase Firestore with offline persistence.

**Features:**
- Real-time listeners
- Offline queue management
- Batch operations
- Document/collection mapping

### Custom Remote Adapters

Implement `RemoteAdapter<T>` to connect to any backend service.

**Required Methods:**
- `initialize()`: Set up the adapter
- `create(T entity)`: Create entity on remote
- `read(String id, {String? userId})`: Retrieve from remote
- `readAll({String? userId})`: Retrieve all from remote
- `patch(String id, Map<String, dynamic> delta, {String? userId})`: Update on remote
- `delete(String id, {String? userId})`: Delete from remote
- `query(DatumQuery query, {String? userId})`: Execute remote queries
- `changeStream()`: Stream of remote changes
- `getSyncMetadata(String userId)`: Get sync metadata
- `unsubscribeFromChanges()`: Stop listening to changes
- `resubscribeToChanges()`: Resume listening to changes

## Adapter Configuration

### DatumConfig

Configuration options that affect adapter behavior:

```dart
DatumConfig<Task>(
  // Schema and migrations
  schemaVersion: 1,
  migrations: [Migration1To2()],

  // Sync behavior
  autoStartSync: true,
  autoSyncInterval: Duration(minutes: 5),
  defaultSyncDirection: SyncDirection.pushThenPull,

  // Conflict resolution
  defaultConflictResolver: LastWriteWinsResolver<Task>(),

  // Performance tuning
  syncExecutionStrategy: SequentialStrategy(),
  syncRequestStrategy: SequentialRequestStrategy(),
  remoteEventDebounceTime: Duration(milliseconds: 100),

  // Error handling
  errorRecoveryStrategy: DatumErrorRecoveryStrategy(
    maxRetries: 3,
    backoffStrategy: ExponentialBackoffStrategy(),
  ),

  // User switching
  defaultUserSwitchStrategy: UserSwitchStrategy.syncThenSwitch,
);
```

### Adapter Registration

Register adapters during Datum initialization:

```dart
await Datum.initialize(
  registrations: [
    DatumRegistration<Task>(
      localAdapter: HiveTaskAdapter(),
      remoteAdapter: RestApiTaskAdapter(),
      config: DatumConfig<Task>(
        // Entity-specific config
      ),
      conflictResolver: CustomConflictResolver(),
      middlewares: [EncryptionMiddleware()],
      observers: [AuditObserver()],
    ),
  ],
);
```

<Warning>
**Adapter Compatibility**: Ensure your local and remote adapters work together. For example, if your remote adapter expects JSON data, your local adapter should also handle JSON serialization consistently.
</Warning>

## Adapter Best Practices

### Local Adapter Guidelines

1. **Performance**: Optimize for fast local operations
2. **Indexing**: Use appropriate indexes for query performance
3. **Memory Management**: Implement efficient caching strategies
4. **Error Handling**: Gracefully handle storage failures
5. **Migration Support**: Implement schema migration logic

### Remote Adapter Guidelines

1. **Network Efficiency**: Minimize requests and payload sizes
2. **Authentication**: Securely handle auth tokens and refresh
3. **Retry Logic**: Implement exponential backoff for failures
4. **Change Detection**: Efficiently detect remote changes
5. **Rate Limiting**: Respect API rate limits and implement throttling

### Testing Adapters

```dart
void main() {
  group('TaskAdapter', () {
    late LocalAdapter<Task> adapter;

    setUp(() async {
      adapter = HiveTaskAdapter();
      await adapter.initialize();
    });

    tearDown(() async {
      await adapter.dispose();
    });

    test('should create and read task', () async {
      final task = Task(id: '1', title: 'Test', userId: 'user1');
      await adapter.create(task);
      final readTask = await adapter.read('1', userId: 'user1');
      expect(readTask?.title, equals('Test'));
    });
  });
}
```
