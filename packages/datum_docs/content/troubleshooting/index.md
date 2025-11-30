---




title:  🔧 Troubleshooting Guide
description: Debug and resolve common Datum sync issues.
---




Common issues and solutions for Datum synchronization problems.

## Common Errors

### Generic Type & Entity Registration Issues
**Quick fixes for the most common errors:**
- ["Entity type DatumEntityInterface is not registered"](./common_errors#entity-type-datumentityinterface-is-not-registered)
- ["Cannot use DatumEntityInterface directly"](./common_errors#cannot-use-datumentityinterface-directly)
- [Choosing the right database adapter](./common_errors#choosing-local-database-adapters)

## Sync Not Working

### Issue: Initial sync fails
**Symptoms:** `synchronize()` throws exception on first call

**Solutions:**
```dart
// 1. Check connectivity
final isConnected = await Datum.instance.connectivityChecker.isConnected;
if (!isConnected) {
  print('No internet connection');
  return;
}

// 2. Verify adapter initialization
try {
  await localAdapter.initialize();
  await remoteAdapter.initialize();
} catch (e) {
  print('Adapter initialization failed: $e');
}

// 3. Check user permissions
if (currentUserId == null) {
  throw Exception('User not authenticated');
}
```

### Issue: Sync hangs indefinitely
**Symptoms:** `synchronize()` call never returns

**Debug Steps:**
```dart
// Add timeout to sync calls
final result = await Datum.instance.synchronize(userId)
    .timeout(Duration(seconds: 30), onTimeout: () {
  print('Sync timeout - check network and server');
  return null;
});

// Check for circular dependencies in relationships
// Ensure no self-referencing entities
```

## Conflict Resolution Issues

### Issue: Unexpected conflict behavior
**Symptoms:** Conflicts not resolving as expected

**Check conflict resolver configuration:**
```dart
final config = DatumConfig(
  defaultConflictResolver: LastWriteWinsResolver<Task>(),
  // Or custom resolver
  defaultConflictResolver: CustomResolver(),
);

// Verify resolver logic
class CustomResolver extends DatumConflictResolver<Task> {
  @override
  Future<DatumConflictResolution<Task>> resolve(...) async {
    // Add logging to debug resolution logic
    print('Resolving conflict: ${context.entityId}');
    return DatumConflictResolution.resolved(localEntity, 'Custom logic');
  }
}
```

### Issue: Conflict resolution UI not showing
**Symptoms:** Conflicts detected but no user prompt

**Ensure proper error handling:**
```dart
manager.onConflict.listen((event) async {
  // Show conflict resolution dialog
  final resolution = await showConflictDialog(event.conflict);
  await manager.resolveConflict(event.conflict.id, resolution);
});
```

## Adapter Problems

### Issue: Local adapter data corruption
**Symptoms:** Local data inconsistent or missing

**Recovery steps:**
```dart
// Clear corrupted local data
await localAdapter.clearAll(userId);

// Force full remote sync
final result = await manager.synchronize(userId, options: DatumSyncOptions(
  forceFullSync: true,
  direction: SyncDirection.pullThenPush,
));
```

### Issue: Remote adapter authentication errors
**Symptoms:** 401/403 errors from remote API

**Check authentication:**
```dart
// Verify auth token validity
final token = await getAuthToken();
if (token == null || isTokenExpired(token)) {
  await refreshAuthToken();
}

// Update adapter with fresh token
remoteAdapter.updateAuthToken(newToken);
```

## Performance Issues

### Issue: Sync too slow
**Symptoms:** Synchronization takes too long

**Optimization strategies:**
```dart
// 1. Use parallel processing
final config = DatumConfig(
  syncExecutionStrategy: ParallelStrategy(batchSize: 10),
);

// 2. Implement selective sync
final scope = DatumSyncScope(
  entityIds: importantEntityIds, // Only sync critical data
);

// 3. Adjust batch sizes
final config = DatumConfig(
  defaultBatchSize: 50, // Larger batches for better throughput
);
```

### Issue: Memory usage too high
**Symptoms:** App crashes with out-of-memory errors

**Memory optimization:**
```dart
// Process in smaller chunks
final entities = await manager.readAll(userId: userId);
for (final chunk in entities.chunks(100)) {
  await processChunk(chunk);
  // Allow garbage collection
  await Future.delayed(Duration(milliseconds: 10));
}
```

## Network Issues

### Issue: Intermittent connectivity
**Symptoms:** Sync fails randomly

**Implement retry logic:**
```dart
final config = DatumConfig(
  errorRecoveryStrategy: DatumErrorRecoveryStrategy(
    maxRetries: 3,
    backoffStrategy: ExponentialBackoffStrategy(
      initialDelay: Duration(seconds: 1),
      maxDelay: Duration(minutes: 2),
    ),
  ),
);
```

### Issue: Large payload failures
**Symptoms:** Sync fails with large datasets

**Chunk large operations:**
```dart
// Split large syncs into smaller operations
final allEntities = await manager.readAll(userId: userId);
for (final batch in allEntities.batches(20)) {
  await manager.saveMany(items: batch, userId: userId);
  await manager.synchronize(userId); // Sync each batch
}
```

## Database Issues

### Issue: Schema version conflicts
**Symptoms:** Migration errors during initialization

**Handle schema updates:**
```dart
final config = DatumConfig(
  schemaVersion: 2,
  migrations: [
    Migration1To2(
      execute: (data) async {
        // Transform data for new schema
        return migrateDataFormat(data);
      },
    ),
  ],
);
```

### Issue: Database locked errors
**Symptoms:** SQLite "database locked" errors

**Implement proper transaction handling:**
```dart
// Use transactions for batch operations
await localAdapter.transaction((txn) async {
  for (final entity in entities) {
    await txn.insert(entity);
  }
});
```

## Debugging Tools

### Enable detailed logging
```dart
final config = DatumConfig(
  logger: DatumLogger(
    enabled: true,
    level: LogLevel.debug,
  ),
);

// Monitor logs
Datum.instance.logger.onLog.listen((log) {
  print('${log.level}: ${log.message}');
});
```

### Health checks
```dart
// Regular health monitoring
Timer.periodic(Duration(minutes: 5), (_) async {
  final health = await manager.checkHealth();
  if (health.status == DatumHealthStatus.unhealthy) {
    reportIssue('Health check failed: ${health.message}');
  }
});
```

### Sync status monitoring
```dart
// Track sync progress
final subscription = manager.statusStream.listen((status) {
  print('Sync status: ${status.status}');
  if (status.hasError) {
    print('Sync error: ${status.error}');
  }
});
```

## Common Error Codes

| Error Code | Description | Solution |
|------------|-------------|----------|
| `network_error` | Network connectivity issues | Check internet connection |
| `auth_error` | Authentication failed | Refresh auth tokens |
| `schema_mismatch` | Database schema conflict | Run migrations |
| `conflict_detected` | Data conflicts found | Implement conflict resolution |
| `timeout_error` | Operation timed out | Increase timeout or reduce batch size |

## Getting Help

If these solutions don't resolve your issue:

1. **Check the logs** - Enable debug logging for detailed information
2. **Review your configuration** - Verify adapter setup and options
3. **Test with minimal example** - Isolate the problem
4. **Report on GitHub** - Include logs, configuration, and reproduction steps

---


*This guide covers the most common Datum issues. For more advanced debugging, check the [Advanced Sync Patterns](guides/advanced_sync) guide.*
