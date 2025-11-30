---




title:  🚨 Common Errors & Solutions
description: Fix frequent errors with generics, entity registration, and database selection.
---




Common errors developers encounter when working with Datum's type system and database adapters.

## Generic Type Errors

### Issue: "Entity type DatumEntityInterface is not registered"

**Symptoms:** Getting this error when calling `Datum.instance.watchAll<DatumEntityInterface>()` or similar methods.

**Cause:** Attempting to use the base `DatumEntityInterface` directly instead of a concrete entity type.

**Solution:** Always use concrete entity classes that implement `DatumEntityInterface`:

```dart
// ❌ Wrong - Using base interface
final stream = Datum.instance.watchAll<DatumEntityInterface>(userId: 'user1');

// ✅ Correct - Using concrete entity type
class Task extends DatumEntity {
  final String title;
  final bool completed;

  Task({
    required super.id,
    required super.userId,
    required this.title,
    this.completed = false,
  });

  // ... implement required methods
}

// Now use the concrete type
final stream = Datum.instance.watchAll<Task>(userId: 'user1');
final manager = Datum.manager<Task>();
```

**Prevention:** The framework prevents using `DatumEntityInterface` directly to maintain type safety.

### Issue: "Cannot use DatumEntityInterface directly"

**Symptoms:** Compilation or runtime error when trying to access managers with the base interface.

**Cause:** Attempting to call `Datum.manager<DatumEntityInterface>()` or similar generic methods.

**Solution:** Use concrete entity types:

```dart
// ❌ Wrong
final manager = Datum.manager<DatumEntityInterface>();

// ✅ Correct
final taskManager = Datum.manager<Task>();
final userManager = Datum.manager<User>();
```

### Issue: Type mismatch in conflict resolvers

**Symptoms:** Compilation errors when implementing `DatumConflictResolver<T>`.

**Cause:** Using wrong generic type parameter in conflict resolver.

**Solution:** Ensure the conflict resolver type matches the entity type:

```dart
// ✅ Correct - Resolver type matches entity type
class TaskConflictResolver extends DatumConflictResolver<Task> {
  @override
  Future<DatumConflictResolution<Task>> resolve(...) async {
    // Resolve conflicts for Task entities
    return DatumConflictResolution.resolved(localTask, 'Resolved');
  }
}

// Use in configuration
final config = DatumConfig<Task>(
  defaultConflictResolver: TaskConflictResolver(),
);
```

## Entity Registration Issues

### Issue: "Entity type X is not registered"

**Symptoms:** Runtime error when trying to access a manager for an unregistered entity type.

**Cause:** Entity type not included in Datum initialization registrations.

**Solution:** Register all entity types during Datum initialization:

```dart
await Datum.initialize(
  config: DatumConfig(),
  connectivityChecker: connectivityChecker,
  registrations: [
    // ✅ Register all your entity types
    DatumRegistration<Task>(
      localAdapter: TaskHiveAdapter(),
      remoteAdapter: TaskSupabaseAdapter(),
    ),
    DatumRegistration<User>(
      localAdapter: UserHiveAdapter(),
      remoteAdapter: UserSupabaseAdapter(),
    ),
    DatumRegistration<Project>(
      localAdapter: ProjectHiveAdapter(),
      remoteAdapter: ProjectSupabaseAdapter(),
    ),
  ],
);
```

**Prevention:** Create a central registry of all entity types used in your app.

### Issue: Manager creation fails

**Symptoms:** `Datum.initialize()` throws errors about missing adapters.

**Cause:** Incomplete registration - missing local or remote adapter.

**Solution:** Ensure both adapters are provided for each entity type:

```dart
// ✅ Complete registration
DatumRegistration<Task>(
  localAdapter: TaskLocalAdapter(),      // Required
  remoteAdapter: TaskRemoteAdapter(),    // Required
  conflictResolver: TaskResolver(),      // Optional
  middlewares: [TaskValidationMiddleware()], // Optional
  observers: [TaskLogger()],             // Optional
),

// ❌ Incomplete - missing remote adapter
DatumRegistration<Task>(
  localAdapter: TaskLocalAdapter(),
  // Missing remoteAdapter!
),
```

## Choosing Local Database Adapters

### When to Use Hive

**Best for:**
- **Simple data structures** - Plain objects without complex relationships
- **High performance** - Fast read/write operations
- **Offline-first apps** - Excellent for cached data
- **Small to medium datasets** - Handles thousands of records efficiently

```dart
// Use Hive for simple entities
class Task extends DatumEntity {
  final String title;
  final DateTime dueDate;

  // Simple fields, no complex relationships
}

// Registration
DatumRegistration<Task>(
  localAdapter: HiveLocalAdapter<Task>(
    boxName: 'tasks',
    fromJson: Task.fromJson,
    toJson: (task) => task.toJson(),
  ),
  remoteAdapter: TaskRemoteAdapter(),
),
```

**Pros:**
- ⚡ Very fast (microseconds for operations)
- 📦 Small bundle size
- 🔒 Type-safe with code generation
- 💾 Efficient storage

**Cons:**
- 🔗 Limited relationship support
- 📊 No advanced querying (SQL-like)
- 🔄 Schema changes require migrations

### When to Use SQLite

**Best for:**
- **Complex relationships** - Foreign keys, joins, complex queries
- **Large datasets** - Millions of records
- **Advanced querying** - SQL-like operations, aggregations
- **Data integrity** - ACID compliance, transactions
- **Relational data** - Normalized schemas

```dart
// Use SQLite for complex entities
class Project extends RelationalDatumEntity {
  final String name;
  final List<Task> tasks; // Complex relationships

  @override
  Map<String, Relation> get relations => {
    'tasks': HasMany<Task>('projectId'),
  };
}

// Registration
DatumRegistration<Project>(
  localAdapter: SQLiteLocalAdapter<Project>(
    tableName: 'projects',
    fromMap: Project.fromMap,
    toMap: (project) => project.toMap(),
  ),
  remoteAdapter: ProjectRemoteAdapter(),
),
```

**Pros:**
- 🔗 Full relationship support
- 📊 Advanced SQL querying
- 🏗️ ACID transactions
- 📈 Scales to large datasets
- 🔍 Complex filtering and sorting

**Cons:**
- 🐌 Slower than Hive for simple operations
- 📦 Larger bundle size
- ⚙️ More complex setup
- 🔧 Schema management required

### When to Use In-Memory Adapter

**Best for:**
- **Testing** - Fast, isolated test environments
- **Temporary data** - Data that doesn't need persistence
- **Prototyping** - Quick development without database setup
- **Caching layers** - Short-lived cached data

```dart
// Use in-memory for testing
DatumRegistration<Task>(
  localAdapter: InMemoryLocalAdapter<Task>(),
  remoteAdapter: MockRemoteAdapter<Task>(),
),
```

**Pros:**
- ⚡ Fastest possible operations
- 🔧 No setup required
- 🧪 Perfect for testing
- 💾 No persistence concerns

**Cons:**
- 💨 Data lost on app restart
- 🔍 No persistence
- 🧪 Only for development/testing

## Adapter Selection Guide

| Use Case | Recommended Adapter | Reasoning |
|----------|-------------------|-----------|
| Simple CRUD app | Hive | Fast, simple, good for most apps |
| Task management | Hive | Simple entities, good performance |
| E-commerce catalog | SQLite | Complex queries, large datasets |
| Social media app | SQLite | Relationships, user-generated content |
| IoT sensor data | SQLite | Time-series data, aggregations |
| Chat application | SQLite | Message threads, relationships |
| Testing | In-Memory | Fast, isolated, no setup |
| Prototyping | In-Memory/Hive | Quick development |



### Performance Comparison

| Operation | Hive | SQLite | In-Memory |
|-----------|------|--------|-----------|
| Simple Read | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Simple Write | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Complex Query | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Relationships | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Large Datasets | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| Setup Complexity | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| Bundle Size | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

## Best Practices

### 1. Choose the Right Adapter Early

```dart
// Consider your data model complexity
class SimpleEntity extends DatumEntity {
  // Use Hive - simple, fast
}

class ComplexEntity extends RelationalDatumEntity {
  // Use SQLite - relationships, complex queries
}
```

### 2. Plan for Growth

```dart
// Start with Hive for simplicity, plan migration path to SQLite
const useSQLite = false; // Feature flag for migration

final adapter = useSQLite
  ? SQLiteLocalAdapter<Entity>()
  : HiveLocalAdapter<Entity>();
```

### 3. Test with Multiple Adapters

```dart
// Use different adapters in different test groups
@Tags(['hive'])
test('Works with Hive', () {
  // Test with Hive adapter
});

@Tags(['sqlite'])
test('Works with SQLite', () {
  // Test with SQLite adapter
});
```

### 4. Handle Adapter-Specific Features

```dart
// Use adapter capabilities appropriately
if (adapter is SQLiteLocalAdapter) {
  // Use SQL queries, transactions
  await adapter.transaction((txn) async {
    // Complex multi-table operations
  });
} else if (adapter is HiveLocalAdapter) {
  // Use Hive-specific features
  await adapter.compact(); // Optimize storage
}
```

## Real-World Adapter Examples

For complete, working implementations, check out these examples in the Datum codebase:

### **Hive Local Adapter Example**
📁 `packages/datum/example/lib/data/task/adapters/hive_adapter.dart`

This file contains a comprehensive `HiveLocalAdapter<T>` implementation that:
- Handles entity serialization/deserialization
- Implements reactive streams with `watchAll()`, `watchById()`, `watchQuery()`
- Manages pending operations and sync metadata
- Provides transaction support and health checks
- Includes user data isolation and cleanup

**Key Features:**
- Full reactive query support
- User-specific data management
- Schema versioning
- Error handling and recovery

### **Supabase Remote Adapter Example**
📁 `packages/datum/example/lib/data/user/adapters/supabase_adapter.dart`

This file contains a production-ready `SupabaseRemoteAdapter<T>` implementation featuring:
- Real-time subscriptions with automatic retry logic
- Authentication state monitoring
- Complex query filtering and pagination
- Relationship fetching (BelongsTo, HasMany, ManyToMany)
- Reactive streams for related entities
- Error handling and connection recovery

**Key Features:**
- Real-time data synchronization
- Advanced relationship support
- Authentication-aware operations
- Robust error recovery
- Performance optimizations

### **Usage in Your App**

Reference these implementations when building your own adapters:

```dart
// Based on the Hive adapter example
class MyEntityHiveAdapter extends HiveLocalAdapter<MyEntity> {
  MyEntityHiveAdapter()
      : super(
          entityBoxName: 'my_entities',
          fromMap: MyEntity.fromMap,
        );
}

// Based on the Supabase adapter example
class MyEntitySupabaseAdapter extends SupabaseRemoteAdapter<MyEntity> {
  MyEntitySupabaseAdapter()
      : super(
          tableName: 'my_entities',
          fromMap: MyEntity.fromMap,
        );
}
```

## Getting Help

If you're still encountering issues:

1. **Check your entity definitions** - Ensure they properly extend `DatumEntity` or `RelationalDatumEntity`
2. **Verify adapter setup** - Test adapters independently before integration
3. **Review type parameters** - Ensure all generic types match correctly
4. **Check the logs** - Enable debug logging for detailed error information
5. **Test with minimal example** - Isolate the problem to specific components
6. **Study the examples** - Review the complete adapter implementations in the example folder

For more advanced patterns, see the [Advanced Sync Patterns](../guides/advanced_sync) guide.


---

*This guide covers the most common generic type and adapter selection issues. For API-specific questions, check the [API Reference](../modules/api_reference) or [Getting Started](../getting_started) guides.*
