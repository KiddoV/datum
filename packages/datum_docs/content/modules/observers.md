---



title: Observers & Middleware
---


The Observers & Middleware module provides hooks for customizing and monitoring Datum operations through observers and middleware.

## Overview

Observers and middleware allow you to intercept, modify, and monitor data operations throughout the Datum system. They provide powerful extension points for logging, validation, transformation, and custom business logic.

## Middleware

### DatumMiddleware<T>

Middleware intercepts and can modify data operations during create, read, update, and delete operations.

**Key Methods:**
- `transformBeforeSave(T entity)`: Modify entity before saving
- `transformAfterFetch(T entity)`: Modify entity after fetching

### Creating Middleware

```dart
class EncryptionMiddleware extends DatumMiddleware<Task> {
  @override
  Future<Task> transformBeforeSave(Task entity) async {
    // Encrypt sensitive data before saving
    final encryptedDescription = await encrypt(entity.description ?? '');
    return entity.copyWith(description: encryptedDescription);
  }

  @override
  Future<Task> transformAfterFetch(Task entity) async {
    // Decrypt sensitive data after fetching
    final decryptedDescription = await decrypt(entity.description ?? '');
    return entity.copyWith(description: decryptedDescription);
  }
}

class ValidationMiddleware extends DatumMiddleware<User> {
  @override
  Future<User> transformBeforeSave(User entity) async {
    // Validate user data
    if (entity.email.isEmpty) {
      throw ValidationException('Email is required');
    }
    if (!isValidEmail(entity.email)) {
      throw ValidationException('Invalid email format');
    }
    return entity;
  }
}

class AuditMiddleware extends DatumMiddleware<Task> {
  @override
  Future<Task> transformBeforeSave(Task entity) async {
    // Add audit information
    final auditData = {
      'lastModifiedBy': currentUserId,
      'lastModifiedAt': DateTime.now(),
      'changeType': 'update',
    };
    return entity.copyWith(auditData: auditData);
  }
}
```

### Registering Middleware

```dart
final registrations = [
  DatumRegistration<Task>(
    localAdapter: HiveTaskAdapter(),
    remoteAdapter: SupabaseTaskAdapter(),
    middlewares: [
      EncryptionMiddleware(),
      ValidationMiddleware(),
      AuditMiddleware(),
    ],
  ),
];
```

### Middleware Execution Order

Middleware executes in registration order:

1. **Before Save**: `transformBeforeSave` methods run in order
2. **Save Operation**: Entity saved to adapters
3. **After Fetch**: `transformAfterFetch` methods run in reverse order

```dart
// Execution flow for saving:
// 1. EncryptionMiddleware.transformBeforeSave
// 2. ValidationMiddleware.transformBeforeSave
// 3. AuditMiddleware.transformBeforeSave
// 4. Save to local adapter
// 5. Save to remote adapter
// 6. AuditMiddleware.transformAfterFetch (if fetching)
// 7. ValidationMiddleware.transformAfterFetch (if fetching)
// 8. EncryptionMiddleware.transformAfterFetch (if fetching)
```

## Observers

### DatumObserver<T>

Observers monitor data operations without modifying them. They receive notifications about operation lifecycle events.

**Key Methods:**
- `onCreate(T entity)`: Called before creating an entity
- `onUpdate(T oldEntity, T newEntity)`: Called before updating an entity
- `onDelete(T entity)`: Called before deleting an entity
- `onRead(T entity)`: Called after reading an entity

### Creating Observers

```dart
class LoggingObserver extends DatumObserver<Task> {
  @override
  Future<void> onCreate(Task entity) async {
    logger.info('Creating task: ${entity.title}');
  }

  @override
  Future<void> onUpdate(Task oldEntity, Task newEntity) async {
    logger.info('Updating task ${oldEntity.id}: ${oldEntity.title} -> ${newEntity.title}');
  }

  @override
  Future<void> onDelete(Task entity) async {
    logger.warn('Deleting task: ${entity.title}');
  }

  @override
  Future<void> onRead(Task entity) async {
    logger.debug('Reading task: ${entity.title}');
  }
}

class NotificationObserver extends DatumObserver<Task> {
  @override
  Future<void> onCreate(Task entity) async {
    if (entity.assignedTo != currentUserId) {
      await sendNotification(
        userId: entity.assignedTo,
        message: 'New task assigned: ${entity.title}',
      );
    }
  }

  @override
  Future<void> onUpdate(Task oldEntity, Task newEntity) async {
    if (oldEntity.isCompleted != newEntity.isCompleted && newEntity.isCompleted) {
      await sendNotification(
        userId: newEntity.createdBy,
        message: 'Task completed: ${newEntity.title}',
      );
    }
  }
}

class CacheInvalidationObserver extends DatumObserver<Post> {
  @override
  Future<void> onCreate(Post entity) async {
    await cache.invalidate('posts_list');
    await cache.invalidate('user_${entity.userId}_posts');
  }

  @override
  Future<void> onUpdate(Post oldEntity, Post newEntity) async {
    await cache.invalidate('post_${oldEntity.id}');
    if (oldEntity.userId != newEntity.userId) {
      await cache.invalidate('user_${oldEntity.userId}_posts');
    }
  }

  @override
  Future<void> onDelete(Post entity) async {
    await cache.invalidate('post_${entity.id}');
    await cache.invalidate('posts_list');
    await cache.invalidate('user_${entity.userId}_posts');
  }
}
```

### Registering Observers

```dart
final registrations = [
  DatumRegistration<Task>(
    localAdapter: HiveTaskAdapter(),
    remoteAdapter: SupabaseTaskAdapter(),
    observers: [
      LoggingObserver(),
      NotificationObserver(),
    ],
  ),
  DatumRegistration<Post>(
    localAdapter: HivePostAdapter(),
    remoteAdapter: SupabasePostAdapter(),
    observers: [
      CacheInvalidationObserver(),
    ],
  ),
];
```

## Global Observers

### GlobalDatumObserver

Global observers monitor system-wide events across all entities.

**Key Methods:**
- `onSyncStart()`: Called when global sync starts
- `onSyncEnd(DatumSyncResult result)`: Called when global sync ends

### Creating Global Observers

```dart
class GlobalAnalyticsObserver extends GlobalDatumObserver {
  @override
  Future<void> onSyncStart() async {
    analytics.track('sync_started', properties: {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> onSyncEnd(DatumSyncResult result) async {
    analytics.track('sync_completed', properties: {
      'duration': result.duration.inMilliseconds,
      'syncedCount': result.syncedCount,
      'failedCount': result.failedCount,
      'conflictsResolved': result.conflictsResolved,
    });
  }
}

class GlobalHealthObserver extends GlobalDatumObserver {
  @override
  Future<void> onSyncStart() async {
    // Record sync start for health monitoring
    await healthMonitor.recordSyncStart();
  }

  @override
  Future<void> onSyncEnd(DatumSyncResult result) async {
    // Update health metrics
    await healthMonitor.recordSyncEnd(result);

    // Alert on sync failures
    if (result.failedCount > 0) {
      await alertSystem.sendAlert(
        'Sync completed with failures',
        'Failed operations: ${result.failedCount}',
      );
    }
  }
}
```

### Registering Global Observers

```dart
await Datum.initialize(
  config: config,
  connectivityChecker: connectivityChecker,
  registrations: registrations,
  observers: [
    GlobalAnalyticsObserver(),
    GlobalHealthObserver(),
  ],
);
```

## Advanced Patterns

### Conditional Middleware

```dart
class ConditionalEncryptionMiddleware extends DatumMiddleware<Task> {
  @override
  Future<Task> transformBeforeSave(Task entity) async {
    // Only encrypt sensitive tasks
    if (entity.isSensitive) {
      final encryptedDescription = await encrypt(entity.description ?? '');
      return entity.copyWith(description: encryptedDescription);
    }
    return entity;
  }

  @override
  Future<Task> transformAfterFetch(Task entity) async {
    if (entity.isSensitive) {
      final decryptedDescription = await decrypt(entity.description ?? '');
      return entity.copyWith(description: decryptedDescription);
    }
    return entity;
  }
}
```

### Composite Observers

```dart
class CompositeObserver extends DatumObserver<Task> {
  final List<DatumObserver<Task>> _observers;

  CompositeObserver(this._observers);

  @override
  Future<void> onCreate(Task entity) async {
    for (final observer in _observers) {
      await observer.onCreate(entity);
    }
  }

  @override
  Future<void> onUpdate(Task oldEntity, Task newEntity) async {
    for (final observer in _observers) {
      await observer.onUpdate(oldEntity, newEntity);
    }
  }

  @override
  Future<void> onDelete(Task entity) async {
    for (final observer in _observers) {
      await observer.onDelete(entity);
    }
  }

  @override
  Future<void> onRead(Task entity) async {
    for (final observer in _observers) {
      await observer.onRead(entity);
    }
  }
}
```

### Async Middleware

```dart
class AsyncValidationMiddleware extends DatumMiddleware<User> {
  @override
  Future<User> transformBeforeSave(User entity) async {
    // Perform async validation (e.g., check uniqueness)
    final existingUser = await userService.findByEmail(entity.email);
    if (existingUser != null && existingUser.id != entity.id) {
      throw ValidationException('Email already exists');
    }

    // Perform external API validation
    final isValid = await externalApi.validateUser(entity);
    if (!isValid) {
      throw ValidationException('User validation failed');
    }

    return entity;
  }
}
```

### Error Handling in Middleware/Observers

```dart
class ResilientObserver extends DatumObserver<Task> {
  @override
  Future<void> onCreate(Task entity) async {
    try {
      await notificationService.sendWelcomeNotification(entity);
    } catch (e) {
      // Log error but don't fail the operation
      logger.error('Failed to send welcome notification: $e');
      // Consider sending to error tracking service
      await errorTracker.report(e, context: {'operation': 'create', 'entityId': entity.id});
    }
  }
}

class SafeMiddleware extends DatumMiddleware<Task> {
  @override
  Future<Task> transformBeforeSave(Task entity) async {
    try {
      return await performTransformation(entity);
    } catch (e) {
      logger.error('Middleware transformation failed: $e');
      // Return original entity to allow operation to continue
      return entity;
    }
  }

  Future<Task> performTransformation(Task entity) async {
    // Actual transformation logic here
    return entity;
  }
}
```

## Performance Considerations

### Middleware Performance

1. **Keep transformations fast**: Avoid heavy computations in middleware
2. **Use async carefully**: Async operations can impact performance
3. **Cache results**: Cache expensive operations when possible
4. **Batch operations**: Process multiple entities together when possible

### Observer Performance

1. **Make observers lightweight**: Avoid blocking operations
2. **Use async observers**: Don't block main operations
3. **Batch notifications**: Send batched notifications when possible
4. **Conditional execution**: Only execute when necessary

### Memory Management

1. **Clean up resources**: Dispose of resources in observers/middleware
2. **Avoid memory leaks**: Be careful with stream subscriptions
3. **Limit concurrent operations**: Control concurrency in middleware

## Testing

### Testing Middleware

```dart
void main() {
  test('EncryptionMiddleware encrypts data', () async {
    final middleware = EncryptionMiddleware();
    final task = Task(description: 'secret data');

    final transformed = await middleware.transformBeforeSave(task);

    expect(transformed.description, isNot(equals('secret data')));
    expect(await decrypt(transformed.description!), equals('secret data'));
  });

  test('ValidationMiddleware rejects invalid data', () async {
    final middleware = ValidationMiddleware();
    final invalidUser = User(email: '');

    expect(
      () => middleware.transformBeforeSave(invalidUser),
      throwsA(isA<ValidationException>()),
    );
  });
}
```

### Testing Observers

```dart
void main() {
  test('LoggingObserver logs operations', () async {
    final logger = MockLogger();
    final observer = LoggingObserver(logger);

    await observer.onCreate(testTask);

    verify(logger.info('Creating task: ${testTask.title}')).called(1);
  });

  test('NotificationObserver sends notifications', () async {
    final notificationService = MockNotificationService();
    final observer = NotificationObserver(notificationService);

    await observer.onCreate(testTask);

    verify(notificationService.sendNotification(
      userId: testTask.assignedTo,
      message: 'New task assigned: ${testTask.title}',
    )).called(1);
  });
}
```

## Best Practices

### Middleware Best Practices

1. **Keep it focused**: Each middleware should have a single responsibility
2. **Make it idempotent**: Running multiple times should be safe
3. **Handle errors gracefully**: Don't break operations due to middleware failures
4. **Document transformations**: Clearly document what each middleware does
5. **Test thoroughly**: Test edge cases and error conditions

### Observer Best Practices

1. **Don't modify data**: Observers should only observe, not modify
2. **Handle failures**: Don't let observer failures break operations
3. **Be efficient**: Keep observers lightweight and fast
4. **Use appropriate scope**: Choose between entity-specific and global observers

### General Best Practices

1. **Order matters**: Consider the order of middleware and observers
2. **Avoid dependencies**: Minimize dependencies between middleware/observers
3. **Monitor performance**: Track the impact of middleware on performance
4. **Version carefully**: Consider versioning when changing middleware behavior
5. **Document behavior**: Clearly document what each component does

## Common Use Cases

### Authentication & Authorization

```dart
class AuthorizationMiddleware extends DatumMiddleware<Document> {
  @override
  Future<Document> transformBeforeSave(Document entity) async {
    if (!await permissionService.canEdit(entity, currentUser)) {
      throw AuthorizationException('Not authorized to edit document');
    }
    return entity;
  }
}
```

### Data Enrichment

```dart
class EnrichmentMiddleware extends DatumMiddleware<Post> {
  @override
  Future<Post> transformAfterFetch(Post entity) async {
    // Add computed fields
    final author = await userService.getById(entity.userId);
    final commentCount = await commentService.countByPostId(entity.id);

    return entity.copyWith(
      authorName: author.name,
      commentCount: commentCount,
    );
  }
}
```

### Audit Trail

```dart
class AuditObserver extends DatumObserver<Task> {
  @override
  Future<void> onUpdate(Task oldEntity, Task newEntity) async {
    await auditService.logChange(
      entityType: 'Task',
      entityId: oldEntity.id,
      userId: currentUserId,
      changes: oldEntity.diff(newEntity),
      timestamp: DateTime.now(),
    );
  }
}
```

### Caching

```dart
class CacheObserver extends DatumObserver<Product> {
  @override
  Future<void> onUpdate(Product oldEntity, Product newEntity) async {
    await cache.invalidate('product_${oldEntity.id}');
    await cache.invalidate('products_list');

    // Update cache with new data
    await cache.set('product_${newEntity.id}', newEntity, ttl: Duration(hours: 1));
  }
}
```</content>
