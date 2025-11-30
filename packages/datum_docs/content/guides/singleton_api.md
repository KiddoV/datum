---
title: Datum Singleton API
---


The `Datum` class provides a global singleton instance that offers convenient access to all Datum functionality. While you can access managers directly through `Datum.manager<T>()`, the singleton also provides high-level convenience methods for common operations.

## Initialization

Before using any Datum functionality, you must initialize the singleton:

```dart
final result = await Datum.initialize(
  config: DatumConfig(
    enableLogging: true,
    autoStartSync: true,
    autoSyncInterval: Duration(minutes: 5),
  ),
  connectivityChecker: MyConnectivityChecker(),
  registrations: [
    DatumRegistration<Task>(
      localAdapter: HiveTaskAdapter(),
      remoteAdapter: RestApiTaskAdapter(),
    ),
  ],
);

if (result.isSuccess) {
  // Datum is ready to use
} else {
  // Handle initialization error
  print('Failed to initialize Datum: ${result.error}');
}
```

## Accessing Managers

Get a manager for a specific entity type:

```dart
final taskManager = Datum.manager<Task>();
```

<Tip>
**Tip**: The singleton methods are perfect for simple operations. For advanced features like custom conflict resolution or detailed event monitoring, use the manager APIs directly.
</Tip>

## Convenience CRUD Methods

The singleton provides direct access to CRUD operations without needing to get managers first:

### Create Operations

```dart
// Create a single entity
final task = Task(id: '1', title: 'New Task', userId: 'user123');
await Datum.create(task);

// Create multiple entities
final tasks = [
  Task(id: '1', title: 'Task 1', userId: 'user123'),
  Task(id: '2', title: 'Task 2', userId: 'user123'),
];
await Datum.createMany<Task>(items: tasks, userId: 'user123');
```

### Read Operations

```dart
// Read a single entity
final task = await Datum.read<Task>('task-id', userId: 'user123');

// Read all entities for a user
final allTasks = await Datum.readAll<Task>(userId: 'user123');

// Query entities
final query = DatumQueryBuilder<Task>()
  .where('completed', isEqualTo: false)
  .orderBy('createdAt', descending: true)
  .build();

final pendingTasks = await Datum.query<Task>(
  query,
  source: DataSource.local,
  userId: 'user123',
);
```

### Update Operations

```dart
// Update a single entity
final updatedTask = existingTask.copyWith(title: 'Updated Title');
await Datum.update(updatedTask);

// Update multiple entities
final tasksToUpdate = [task1, task2, task3];
await Datum.updateMany<Task>(items: tasksToUpdate, userId: 'user123');
```

### Delete Operations

```dart
// Delete a single entity
await Datum.delete<Task>(id: 'task-id', userId: 'user123');
```

## Sync Operations

### Immediate Sync

```dart
// Create/update and immediately sync
final (savedTask, syncResult) = await Datum.pushAndSync(
  item: task,
  userId: 'user123',
);

// Update and immediately sync
final (updatedTask, syncResult) = await Datum.updateAndSync(
  item: task,
  userId: 'user123',
);

// Delete and immediately sync
final (deleted, syncResult) = await Datum.deleteAndSync<Task>(
  id: 'task-id',
  userId: 'user123',
);
```

### Global Sync

Synchronize all registered entity types for a user:

```dart
final syncResult = await Datum.instance.synchronize('user123');
print('Synced ${syncResult.syncedCount} items across all entities');
```

## User Change Streams

Datum provides reactive user change streams that automatically update data when users switch. This is particularly useful for multi-tenant applications where different users have separate data.

### Using Datum.userChangeStream

Listen to global user changes across all entity types:

```dart
// Listen to global user changes
final subscription = Datum.instance.userChangeStream.listen((userId) {
  print('User changed to: $userId');
  // Automatically refresh UI or data
});

// Emit user changes when authentication state changes
Datum.instance._userChangeController.add('new-user-id');
```

### Using Manager.onUserChanged

Listen to user changes for specific entity types:

```dart
// Get a specific manager
final taskManager = Datum.manager<Task>();

// Listen to user changes for this entity type
final userSubscription = taskManager.onUserChanged.listen((userId) {
  print('User changed for tasks: $userId');
  // Tasks will automatically refresh for the new user
});
```

### Integration with Authentication

```dart
class AuthService {
  void login(String userId) {
    // Update Datum's user change stream
    Datum.instance._userChangeController.add(userId);

    // Your authentication logic here
    // ...
  }

  void logout() {
    // Clear user (null indicates no user)
    Datum.instance._userChangeController.add(null);
  }

  void switchUser(String newUserId) {
    // Switch to different user
    Datum.instance._userChangeController.add(newUserId);
  }
}
```

### Reactive UI Updates

```dart
class TaskListWidget extends StatefulWidget {
  @override
  _TaskListWidgetState createState() => _TaskListWidgetState();
}

class _TaskListWidgetState extends State<TaskListWidget> {
  late StreamSubscription<String?> _userSubscription;
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();

    // Listen to user changes and refresh data
    _userSubscription = Datum.manager<Task>().onUserChanged.listen((userId) {
      _loadTasks();
    });

    _loadTasks(); // Initial load
  }

  Future<void> _loadTasks() async {
    final tasks = await Datum.manager<Task>().readAll();
    setState(() => _tasks = tasks);
  }

  @override
  void dispose() {
    _userSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        return ListTile(title: Text(_tasks[index].title));
      },
    );
  }
}
```

### Benefits

- **Automatic Data Isolation**: Each user's data is kept separate
- **Reactive Updates**: UI automatically refreshes when users switch
- **Memory Management**: Old user's data is cleaned up automatically
- **Performance**: Only active user's data is loaded in memory
- **Security**: Prevents data leakage between users

## Reactive Operations

Watch for real-time data changes:

```dart
// Watch all entities
final subscription = Datum.watchAll<Task>(userId: 'user123')
  ?.listen((tasks) {
    print('Tasks updated: ${tasks.length} items');
  });

// Watch a single entity
final singleSub = Datum.watchById<Task>('task-id', 'user123')
  ?.listen((task) {
    if (task != null) {
      print('Task updated: ${task.title}');
    } else {
      print('Task was deleted');
    }
  });

// Watch paginated results
final paginatedSub = Datum.watchAllPaginated<Task>(
  PaginationConfig(pageSize: 20),
  userId: 'user123',
)?.listen((result) {
  print('Page ${result.currentPage}: ${result.items.length} items');
});

// Watch query results
final query = DatumQueryBuilder<Task>()
  .where('completed', isEqualTo: false)
  .build();

final querySub = Datum.watchQuery<Task>(query, userId: 'user123')
  ?.listen((tasks) {
    print('Pending tasks: ${tasks.length}');
  });
```

## Relationship Operations

Work with related entities:

```dart
// Fetch related entities
final comments = await Datum.fetchRelated<Post, Comment>(
  post,
  'comments',
  source: DataSource.local,
);

// Watch related entities
final relatedSub = Datum.watchRelated<Post, Comment>(post, 'comments')
  ?.listen((comments) {
    print('Post has ${comments.length} comments');
  });
```

## Monitoring & Health

### Health Monitoring

```dart
// Check health of all managers
Datum.instance.allHealths.listen((healthMap) {
  healthMap.forEach((entityType, health) {
    print('$entityType: ${health.status}');
  });
});

// Check health of specific entity type
final health = await Datum.checkHealth<Task>();
print('Task health: ${health.status}');
```

### Metrics

```dart
// Monitor global metrics
Datum.instance.metrics.listen((metrics) {
  print('Total syncs: ${metrics.totalSyncOperations}');
  print('Successful: ${metrics.successfulSyncs}');
  print('Failed: ${metrics.failedSyncs}');
});
```

### User Status

```dart
// Monitor sync status for a user
Datum.instance.statusForUser('user123').listen((status) {
  if (status != null) {
    print('User sync status: ${status.status}');
    print('Pending operations: ${status.pendingOperationsCount}');
  }
});
```

## Utility Methods

### Pending Operations

```dart
// Get pending operation count
final count = await Datum.getPendingCount<Task>('user123');

// Get pending operations
final operations = await Datum.getPendingOperations<Task>('user123');
```

### Storage Information

```dart
// Get storage size
final size = await Datum.getStorageSize<Task>(userId: 'user123');

// Watch storage size changes
Datum.watchStorageSize<Task>(userId: 'user123')?.listen((size) {
  print('Storage size: ${size} bytes');
});
```

### Sync Results

```dart
// Get last sync result
final lastResult = await Datum.getLastSyncResult<Task>('user123');

// Get remote sync metadata
final metadata = await Datum.getRemoteSyncMetadata<Task>('user123');
```

## Global Sync Control

Control synchronization across all managers:

```dart
// Pause all sync operations
Datum.instance.pauseSync();

// Resume all sync operations
Datum.instance.resumeSync();

// Unsubscribe from remote changes
await Datum.instance.unsubscribeAllFromRemoteChanges();

// Resubscribe to remote changes
await Datum.instance.resubscribeAllToRemoteChanges();
```

## Best Practices

1. **Initialization**: Always initialize Datum before use
2. **Error Handling**: Check initialization results and handle sync errors
3. **Resource Management**: Cancel subscriptions when no longer needed
4. **Performance**: Use appropriate data sources (local vs remote) for your use case
5. **Monitoring**: Monitor health and metrics in production applications

## Comparison with Manager API

| Operation | Singleton Method | Manager Method |
|-----------|------------------|----------------|
| Create | `Datum.create(entity)` | `manager.push(item: entity)` |
| Read | `Datum.read<T>(id)` | `manager.read(id)` |
| Watch | `Datum.watchAll<T>()` | `manager.watchAll()` |
| Sync | `Datum.instance.synchronize()` | `manager.synchronize()` |

The singleton methods are convenient for simple operations, while manager methods provide more control and advanced features.

## Examples



```dart
// Initialize Datum
await Datum.initialize(
  config: DatumConfig(),
  connectivityChecker: MyConnectivityChecker(),
  registrations: [DatumRegistration<Task>(/* adapters */)],
);

// Use the singleton API
final task = Task(id: '1', title: 'My Task', userId: 'user123');
await Datum.create(task);

final tasks = await Datum.readAll<Task>(userId: 'user123');
print('Found ${tasks.length} tasks');
```


### Status Indicators

Current API Status: <Badge variant="success">Stable</Badge>

Available in: <Badge variant="info">v1.0.1+</Badge>

## Component Showcase

Here are some examples of the enhanced documentation components:

<Steps>
1. **Initialize Datum** with your configuration and adapters
2. **Use the singleton API** for convenient operations
3. **Monitor health** and performance metrics
4. **Handle sync conflicts** with built-in resolvers
</Steps>

<Card title="Advanced Features">
The singleton API provides powerful features beyond basic CRUD operations:

- **Real-time watching** with reactive streams
- **Batch operations** for multiple entities
- **Relationship queries** with eager loading
- **Global sync control** across all managers
- **Health monitoring** and metrics collection

These features make it easy to build sophisticated offline-first applications with minimal boilerplate code.
</Card>

<Warning>
**Performance Note**: While the singleton API is convenient, for high-frequency operations in performance-critical code paths, consider using manager instances directly to avoid the additional indirection.
</Warning>
