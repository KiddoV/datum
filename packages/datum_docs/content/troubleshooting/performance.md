---




title: ⚡ Performance Troubleshooting
description: Debug and optimize Datum performance issues.
---



Identify and resolve performance bottlenecks in Datum applications.

## Slow Sync Performance

### Issue: Large dataset sync taking too long

**Symptoms:** Sync operations taking minutes instead of seconds

**Diagnostic Steps:**
```dart
// 1. Measure current performance
final stopwatch = Stopwatch()..start();
final result = await manager.synchronize(userId);
stopwatch.stop();
print('Sync took: ${stopwatch.elapsed.inSeconds}s');

// 2. Check dataset size
final localCount = await manager.getLocalEntityCount(userId);
final remoteCount = await manager.getRemoteEntityCount(userId);
print('Local: $localCount, Remote: $remoteCount');
```

**Optimization Strategies:**
```dart
// Use parallel processing for large datasets
final config = DatumConfig(
  syncExecutionStrategy: ParallelStrategy(
    batchSize: 20,  // Process 20 items concurrently
    failFast: false, // Continue on individual failures
  ),
);

// Implement selective sync for critical data only
final criticalEntities = await manager.query(
  DatumQuery(
    filters: [Filter('priority', FilterOperator.equals, 'high')],
  ),
  userId: userId,
);

final scope = DatumSyncScope(
  entityIds: criticalEntities.map((e) => e.id).toList(),
);

await manager.synchronize(userId, scope: scope);
```

### Issue: Memory spikes during sync

**Symptoms:** App memory usage spikes, potential crashes

**Memory Monitoring:**
```dart
// Track memory usage during sync
final initialMemory = await getCurrentMemoryUsage();
print('Initial memory: ${initialMemory}MB');

final result = await manager.synchronize(userId);

final finalMemory = await getCurrentMemoryUsage();
print('Final memory: ${finalMemory}MB');
print('Memory delta: ${finalMemory - initialMemory}MB');
```

**Memory Optimization:**
```dart
// Process in smaller chunks
const chunkSize = 50;
final allEntities = await manager.readAll(userId: userId);

for (var i = 0; i < allEntities.length; i += chunkSize) {
  final end = (i + chunkSize < allEntities.length) ? i + chunkSize : allEntities.length;
  final chunk = allEntities.sublist(i, end);

  await manager.saveMany(items: chunk, userId: userId);
  await manager.synchronize(userId);

  // Allow garbage collection
  await Future.delayed(Duration(milliseconds: 100));
}
```

## Database Performance Issues

### Issue: Slow local database queries

**Symptoms:** Local read/write operations are slow

**Query Optimization:**
```dart
// 1. Check query execution time
final stopwatch = Stopwatch()..start();
final results = await manager.query(complexQuery, userId: userId);
stopwatch.stop();
print('Query took: ${stopwatch.elapsed.inMilliseconds}ms');

// 2. Analyze query complexity
print('Filters: ${complexQuery.filters.length}');
print('Sorting: ${complexQuery.sorting.length}');
print('Limit: ${complexQuery.limit}');
```

**Indexing Strategies:**
```dart
// Ensure proper indexing in local adapter
class OptimizedHiveAdapter extends LocalAdapter<Task> {
  @override
  Future<void> initialize() async {
    // Create indexes for frequently queried fields
    await _createIndex('userId');
    await _createIndex('status');
    await _createIndex('priority');
    await _createIndex('dueDate');
  }
}
```

### Issue: Remote API rate limiting

**Symptoms:** 429 Too Many Requests errors

**Rate Limiting Solutions:**
```dart
// Implement exponential backoff
final config = DatumConfig(
  errorRecoveryStrategy: DatumErrorRecoveryStrategy(
    maxRetries: 5,
    backoffStrategy: ExponentialBackoffStrategy(
      initialDelay: Duration(seconds: 2),
      maxDelay: Duration(minutes: 5),
      multiplier: 2.0,
    ),
  ),
);

// Add request throttling
class ThrottledRemoteAdapter extends RemoteAdapter<Task> {
  static const _minRequestInterval = Duration(milliseconds: 100);
  DateTime _lastRequestTime = DateTime.now();

  @override
  Future<List<Task>> readAll({String? userId, DatumSyncScope? scope}) async {
    final now = DateTime.now();
    final timeSinceLastRequest = now.difference(_lastRequestTime);

    if (timeSinceLastRequest < _minRequestInterval) {
      await Future.delayed(_minRequestInterval - timeSinceLastRequest);
    }

    _lastRequestTime = DateTime.now();
    return super.readAll(userId: userId, scope: scope);
  }
}
```

## Network Performance

### Issue: High latency sync operations

**Symptoms:** Sync operations delayed by network latency

**Network Optimization:**
```dart
// 1. Check network quality
final connectivity = await Connectivity().checkConnectivity();
print('Network type: $connectivity');

// 2. Measure network latency
final latency = await measureNetworkLatency();
print('Network latency: ${latency.inMilliseconds}ms');

// 3. Adjust sync strategy based on network
if (latency > Duration(seconds: 1)) {
  // Use smaller batches for poor connections
  final config = DatumConfig(
    syncExecutionStrategy: ParallelStrategy(batchSize: 5),
  );
} else {
  // Use larger batches for good connections
  final config = DatumConfig(
    syncExecutionStrategy: ParallelStrategy(batchSize: 25),
  );
}
```

### Issue: Large payload transmission failures

**Symptoms:** Sync fails with large datasets due to payload size limits

**Payload Optimization:**
```dart
// Compress data before transmission
class CompressedRemoteAdapter extends RemoteAdapter<Task> {
  @override
  Future<void> create(Task item) async {
    final jsonData = item.toDatumMap(target: MapTarget.remote);
    final compressed = await compressJson(jsonData);
    await _sendCompressedData('/tasks', compressed);
  }
}

// Split large syncs into smaller operations
final largeDataset = await manager.readAll(userId: userId);
const batchSize = 10;

for (var i = 0; i < largeDataset.length; i += batchSize) {
  final batch = largeDataset.skip(i).take(batchSize).toList();
  await manager.saveMany(items: batch, userId: userId);
  await manager.synchronize(userId);
}
```

## UI Responsiveness Issues

### Issue: UI freezing during sync

**Symptoms:** App becomes unresponsive during synchronization

**Background Processing Solutions:**
```dart
// Use isolate strategy for heavy operations
final config = DatumConfig(
  syncExecutionStrategy: IsolateStrategy(
    ParallelStrategy(batchSize: 10),
  ),
);

// Show progress indicators
class SyncProgressWidget extends StatefulWidget {
  @override
  _SyncProgressWidgetState createState() => _SyncProgressWidgetState();
}

class _SyncProgressWidgetState extends State<SyncProgressWidget> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    manager.onSyncProgress.listen((event) {
      setState(() => _progress = event.progress);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(value: _progress);
  }
}
```

### Issue: Reactive streams causing UI lag

**Symptoms:** UI updates are slow or choppy

**Stream Optimization:**
```dart
// Debounce rapid updates
final debouncedStream = manager.watchAll<Task>(userId: userId)
    ?.debounceTime(Duration(milliseconds: 100));

// Use distinct to avoid duplicate emissions
final distinctStream = manager.watchAll<Task>(userId: userId)
    ?.distinct((prev, next) => prev.length == next.length);
```

## Monitoring and Profiling

### Performance Metrics Collection

```dart
class PerformanceMonitor {
  final Map<String, Duration> _operationTimes = {};

  Future<T> measureOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      _operationTimes[operationName] = stopwatch.elapsed;
      return result;
    } finally {
      stopwatch.stop();
    }
  }

  void printReport() {
    print('=== Performance Report ===');
    _operationTimes.forEach((name, duration) {
      print('$name: ${duration.inMilliseconds}ms');
    });
  }
}
```

### Automated Performance Testing

```dart
class PerformanceTest {
  static Future<void> runSyncPerformanceTest(
    DatumManager manager,
    String userId,
    int entityCount,
  ) async {
    // Create test data
    final testEntities = List.generate(
      entityCount,
      (i) => Task(
        id: 'perf-test-$i',
        userId: userId,
        title: 'Performance Test Task $i',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      ),
    );

    // Measure save performance
    final saveStopwatch = Stopwatch()..start();
    await manager.saveMany(items: testEntities, userId: userId);
    saveStopwatch.stop();

    // Measure sync performance
    final syncStopwatch = Stopwatch()..start();
    await manager.synchronize(userId);
    syncStopwatch.stop();

    print('Performance Test Results:');
    print('Entities: $entityCount');
    print('Save Time: ${saveStopwatch.elapsed.inSeconds}s');
    print('Sync Time: ${syncStopwatch.elapsed.inSeconds}s');
    print('Avg per entity: ${(syncStopwatch.elapsed.inMilliseconds / entityCount).round()}ms');
  }
}
```

## Best Practices

### 1. Profile Regularly
```dart
// Add performance monitoring to your app
Timer.periodic(Duration(minutes: 30), (_) async {
  final metrics = await collectPerformanceMetrics();
  await reportMetrics(metrics);
});
```

### 2. Optimize for Your Use Case
```dart
// Choose the right sync strategy for your app
final config = DatumConfig(
  // For real-time apps: frequent small syncs
  autoSyncInterval: Duration(minutes: 2),
  syncExecutionStrategy: ParallelStrategy(batchSize: 5),

  // For batch processing apps: larger infrequent syncs
  autoSyncInterval: Duration(hours: 1),
  syncExecutionStrategy: ParallelStrategy(batchSize: 50),
);
```

### 3. Monitor Resource Usage
```dart
// Track memory and CPU usage
final memoryUsage = await getMemoryUsage();
final cpuUsage = await getCpuUsage();

if (memoryUsage > 100 * 1024 * 1024) { // 100MB
  print('Warning: High memory usage detected');
}
```

---


*For more performance optimization techniques, check the [Advanced Sync Patterns](../guides/advanced_sync.md) guide.*
