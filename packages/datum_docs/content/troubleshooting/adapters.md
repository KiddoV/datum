---




title: 🔌 Adapter Troubleshooting
description: Debug and resolve adapter-specific issues in Datum.
---


Debug and resolve issues specific to Datum adapters (local and remote).

## Local Adapter Issues

### Issue: Hive adapter initialization failure

**Symptoms:** `Hive.initFlutter()` or box opening fails

**Common Causes:**
- Incorrect path configuration
- Permission issues on device storage
- Concurrent access conflicts

**Resolution Steps:**
```dart
// 1. Check storage permissions
final hasPermission = await Permission.storage.request();
if (!hasPermission) {
  throw Exception('Storage permission required for Hive');
}

// 2. Proper initialization order
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive first
  final appDir = await getApplicationDocumentsDirectory();
  Hive.init(appDir.path);

  // Register adapters
  Hive.registerAdapter(TaskAdapter());

  // Open boxes
  final taskBox = await Hive.openBox<Task>('tasks');

  // Then initialize Datum
  final datum = await Datum.initialize(/* config */);
}

// 3. Handle box opening errors
Future<Box<Task>> openTaskBox() async {
  try {
    return await Hive.openBox<Task>('tasks');
  } catch (e) {
    // Try opening with different encryption or recovery
    await Hive.deleteBoxFromDisk('tasks'); // Clear corrupted box
    return await Hive.openBox<Task>('tasks');
  }
}
```

### Issue: Isar database corruption

**Symptoms:** Isar queries fail with corruption errors

**Recovery Strategies:**
```dart
class IsarRecoveryManager {
  static Future<void> recoverCorruptedDatabase(
    String databasePath,
  ) async {
    try {
      // Close existing instance
      await Isar.getInstance()?.close();

      // Delete corrupted files
      final dir = Directory(databasePath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }

      // Reinitialize
      final isar = await Isar.open(
        schemas: [TaskSchema],
        directory: databasePath,
      );

      print('Database recovered successfully');
    } catch (e) {
      print('Recovery failed: $e');
      rethrow;
    }
  }
}
```

### Issue: SQLite database locked

**Symptoms:** "Database locked" errors during concurrent operations

**Transaction Management:**
```dart
class SQLiteAdapter extends LocalAdapter<Task> {
  final Database _db;

  @override
  Future<void> saveMany(List<Task> items, String userId) async {
    // Use transactions to prevent locking
    await _db.transaction((txn) async {
      for (final item in items) {
        await txn.insert(
          'tasks',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<List<Task>> readAll({String? userId}) async {
    // Use read-only transactions for queries
    return _db.transaction((txn) async {
      final maps = await txn.query('tasks');
      return maps.map((map) => Task.fromMap(map)).toList();
    });
  }
}
```

## Remote Adapter Issues

### Issue: Supabase connection and authentication failures

**Symptoms:** Supabase operations fail with connection or auth errors

**Common Issues & Solutions:**

**Connection Setup:**
```dart
// 1. Verify Supabase configuration
void main() async {
  await Supabase.initialize(
    url: 'https://your-project.supabase.co',
    anonKey: 'your-anon-key',
    // Add auth options for better error handling
    authOptions: const AuthClientOptions(
      autoRefreshToken: true,
      persistSession: true,
    ),
  );
}

// 2. Check connection status
class SupabaseHealthCheck {
  static Future<bool> isConnected() async {
    try {
      // Test connection with a simple query
      final response = await Supabase.instance.client
          .from('health_check')
          .select('status')
          .limit(1)
          .single();

      return response != null;
    } catch (e) {
      print('Supabase connection failed: $e');
      return false;
    }
  }
}
```

**Authentication Issues:**
```dart
// Handle auth state changes
class SupabaseAuthManager {
  StreamSubscription<AuthState>? _authSubscription;

  void initializeAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (event) {
        switch (event.event) {
          case AuthChangeEvent.signedIn:
            print('User signed in: ${event.session?.user.id}');
            // Initialize Datum sync
            break;
          case AuthChangeEvent.signedOut:
            print('User signed out');
            // Pause sync and clear data
            Datum.instance.pauseSync();
            break;
          case AuthChangeEvent.tokenRefreshed:
            print('Token refreshed');
            // Update adapter with new token
            break;
        }
      },
      onError: (error) {
        print('Auth error: $error');
        // Handle auth errors (network issues, expired tokens, etc.)
      },
    );
  }

  void dispose() {
    _authSubscription?.cancel();
  }
}
```

**RLS (Row Level Security) Issues:**
```dart
// Debug RLS policies
class SupabaseRLSDebugger {
  static Future<void> testRLSPolicies(String userId) async {
    try {
      // Test read access
      final readTest = await Supabase.instance.client
          .from('tasks')
          .select('*')
          .eq('user_id', userId)
          .limit(1);

      print('Read access: ✅');

      // Test write access
      final writeTest = await Supabase.instance.client
          .from('tasks')
          .insert({
            'id': const Uuid().v4(),
            'user_id': userId,
            'title': 'RLS Test',
            'created_at': DateTime.now().toIso8601String(),
          });

      print('Write access: ✅');

    } catch (e) {
      print('RLS Error: $e');
      print('Check your RLS policies in Supabase dashboard');
      print('Example policy:');
      print('CREATE POLICY "Users can access their own tasks"');
      print('ON tasks FOR ALL USING (auth.uid()::text = user_id);');
    }
  }
}
```

**Real-time Subscription Issues:**
```dart
class SupabaseRealtimeManager {
  RealtimeChannel? _channel;
  StreamSubscription? _subscription;

  void setupRealtimeSubscription(String userId) {
    // Clean up existing subscription
    _channel?.unsubscribe();
    _subscription?.cancel();

    // Create new channel
    _channel = Supabase.instance.client.channel('tasks_$userId');

    // Subscribe to changes
    _channel!.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: '*',
        schema: 'public',
        table: 'tasks',
        filter: 'user_id=eq.$userId',
      ),
      (payload, [ref]) {
        print('Realtime event: ${payload['eventType']}');
        handleRealtimeEvent(payload);
      },
    ).subscribe(
      (status, [err]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          print('Successfully subscribed to realtime updates');
        } else {
          print('Realtime subscription failed: $err');
          // Retry logic
          Future.delayed(Duration(seconds: 5), () {
            setupRealtimeSubscription(userId);
          });
        }
      },
    );
  }

  void handleRealtimeEvent(Map<String, dynamic> payload) {
    final eventType = payload['eventType'];
    final newRecord = payload['new'] as Map<String, dynamic>?;
    final oldRecord = payload['old'] as Map<String, dynamic>?;

    switch (eventType) {
      case 'INSERT':
        if (newRecord != null) {
          final task = Task.fromJson(newRecord);
          // Update local cache
        }
        break;
      case 'UPDATE':
        if (newRecord != null) {
          final task = Task.fromJson(newRecord);
          // Update local cache
        }
        break;
      case 'DELETE':
        if (oldRecord != null) {
          final taskId = oldRecord['id'] as String;
          // Remove from local cache
        }
        break;
    }
  }

  void dispose() {
    _channel?.unsubscribe();
    _subscription?.cancel();
  }
}
```

**Storage and File Upload Issues:**
```dart
class SupabaseStorageManager {
  static Future<String?> uploadFile(
    String bucket,
    String fileName,
    Uint8List fileData,
  ) async {
    try {
      final fileExt = fileName.split('.').last;
      final filePath = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      final response = await Supabase.instance.client.storage
          .from(bucket)
          .uploadBinary(filePath, fileData);

      if (response != null) {
        // Get public URL
        final publicUrl = Supabase.instance.client.storage
            .from(bucket)
            .getPublicUrl(filePath);

        return publicUrl;
      }
    } catch (e) {
      print('File upload failed: $e');

      // Check storage permissions
      if (e.toString().contains('permission')) {
        print('Check storage bucket policies in Supabase dashboard');
      }
    }
    return null;
  }
}
```

### Issue: REST API authentication failures

**Symptoms:** 401/403 errors from API endpoints

**Authentication Handling:**
```dart
class AuthenticatedRestAdapter extends RemoteAdapter<Task> {
  final Dio _dio;
  String? _authToken;

  AuthenticatedRestAdapter(this._dio) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expired, try refresh
            try {
              _authToken = await refreshAuthToken();
              // Retry the request
              final response = await _dio.request(
                error.requestOptions.path,
                options: Options(
                  method: error.requestOptions.method,
                  headers: {
                    ...error.requestOptions.headers,
                    'Authorization': 'Bearer $_authToken',
                  },
                ),
                data: error.requestOptions.data,
              );
              return handler.resolve(response);
            } catch (e) {
              // Refresh failed, logout user
              await logoutUser();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<String?> refreshAuthToken() async {
    try {
      final response = await _dio.post('/auth/refresh');
      return response.data['token'];
    } catch (e) {
      return null;
    }
  }
}
```

### Issue: GraphQL adapter query failures

**Symptoms:** GraphQL queries return errors or null data

**Query Debugging:**
```dart
class GraphQLAdapter extends RemoteAdapter<Task> {
  final GraphQLClient _client;

  @override
  Future<List<Task>> readAll({String? userId, DatumSyncScope? scope}) async {
    const query = '''
      query GetTasks($userId: ID!, $limit: Int) {
        tasks(userId: $userId, limit: $limit) {
          id
          title
          description
          isCompleted
          createdAt
          modifiedAt
        }
      }
    ''';

    final options = QueryOptions(
      document: gql(query),
      variables: {
        'userId': userId,
        'limit': scope?.limit ?? 100,
      },
    );

    final result = await _client.query(options);

    if (result.hasException) {
      print('GraphQL Error: ${result.exception}');
      // Log detailed error information
      for (final error in result.exception!.graphqlErrors) {
        print('GraphQL Error: ${error.message}');
        print('Path: ${error.path}');
        print('Extensions: ${error.extensions}');
      }
      throw result.exception!;
    }

    final tasks = result.data?['tasks'] as List? ?? [];
    return tasks.map((json) => Task.fromJson(json)).toList();
  }
}
```

### Issue: Supabase real-time subscription failures

**Symptoms:** Real-time updates not working

**Subscription Management:**
```dart
class SupabaseAdapter extends RemoteAdapter<Task> {
  final SupabaseClient _client;
  StreamSubscription? _subscription;

  void setupRealtimeSync(String userId) {
    _subscription?.cancel();

    _subscription = _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((data) {
          // Handle real-time updates
          for (final change in data) {
            switch (change.eventType) {
              case PostgresChangeEvent.insert:
                _handleInsert(change.newRecord);
                break;
              case PostgresChangeEvent.update:
                _handleUpdate(change.newRecord);
                break;
              case PostgresChangeEvent.delete:
                _handleDelete(change.oldRecord);
                break;
            }
          }
        });
  }

  void _handleInsert(Map<String, dynamic> record) {
    final task = Task.fromJson(record);
    // Update local cache
    localAdapter.create(task);
  }

  void _handleUpdate(Map<String, dynamic> record) {
    final task = Task.fromJson(record);
    localAdapter.update(task);
  }

  void _handleDelete(Map<String, dynamic> record) {
    final taskId = record['id'] as String;
    localAdapter.delete(taskId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

## Firebase Adapter Issues

### Issue: Firestore permission errors

**Symptoms:** Firestore operations fail with permission-denied

**Security Rules Debugging:**
```dart
// Debug security rules locally
class FirestoreDebugAdapter extends RemoteAdapter<Task> {
  final FirebaseFirestore _firestore;

  @override
  Future<void> create(Task item) async {
    try {
      await _firestore.collection('tasks').doc(item.id).set(item.toMap());
    } catch (e) {
      print('Firestore create error: $e');
      // Check if it's a permission error
      if (e is FirebaseException && e.code == 'permission-denied') {
        print('Check Firestore security rules for tasks collection');
        print('Current user: ${FirebaseAuth.instance.currentUser?.uid}');
      }
      rethrow;
    }
  }
}

// Firestore Security Rules Example
/*
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /tasks/{taskId} {
      allow read, write: if request.auth != null &&
        request.auth.uid == resource.data.userId;
    }
  }
}
*/
```

### Issue: Firebase offline persistence conflicts

**Symptoms:** Local changes conflict with server state

**Offline Persistence Configuration:**
```dart
class FirebaseAdapter extends RemoteAdapter<Task> {
  final FirebaseFirestore _firestore;

  FirebaseAdapter() : _firestore = FirebaseFirestore.instance {
    // Configure offline persistence
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Enable network calls
    _firestore.enableNetwork();
  }

  @override
  Future<List<Task>> readAll({String? userId, DatumSyncScope? scope}) async {
    // Force server data for critical reads
    final source = scope?.forceServer ?? false
        ? Source.server
        : Source.cache;

    final snapshot = await _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .get(GetOptions(source: source));

    return snapshot.docs
        .map((doc) => Task.fromMap(doc.data()))
        .toList();
  }
}
```

## Adapter Testing

### Unit Testing Adapters

```dart
class AdapterTestSuite {
  static Future<void> testLocalAdapter(LocalAdapter<Task> adapter) async {
    // Test basic CRUD operations
    final testTask = Task.create(title: 'Test Task');

    // Create
    await adapter.create(testTask);
    expect(await adapter.read(testTask.id), equals(testTask));

    // Update
    final updatedTask = testTask.copyWith(title: 'Updated Task');
    await adapter.update(updatedTask);
    expect(await adapter.read(testTask.id), equals(updatedTask));

    // Delete
    await adapter.delete(testTask.id);
    expect(await adapter.read(testTask.id), isNull);
  }

  static Future<void> testRemoteAdapter(RemoteAdapter<Task> adapter) async {
    // Mock HTTP responses for testing
    final mockTasks = [
      Task.create(title: 'Mock Task 1'),
      Task.create(title: 'Mock Task 2'),
    ];

    // Test read operations
    final tasks = await adapter.readAll(userId: 'test-user');
    expect(tasks.length, greaterThan(0));

    // Test create operations
    final newTask = Task.create(title: 'New Task');
    await adapter.create(newTask);

    // Verify creation
    final readTask = await adapter.read(newTask.id);
    expect(readTask?.title, equals(newTask.title));
  }
}
```

## Performance Optimization

### Connection Pooling

```dart
class PooledHttpAdapter extends RemoteAdapter<Task> {
  final List<Dio> _clients;
  int _currentClient = 0;

  PooledHttpAdapter(int poolSize) : _clients = List.generate(
    poolSize,
    (i) => Dio(BaseOptions(
      baseUrl: 'https://api.example.com',
      connectTimeout: Duration(seconds: 5),
      receiveTimeout: Duration(seconds: 10),
    )),
  );

  Dio get _client {
    final client = _clients[_currentClient];
    _currentClient = (_currentClient + 1) % _clients.length;
    return client;
  }

  @override
  Future<List<Task>> readAll({String? userId, DatumSyncScope? scope}) async {
    final response = await _client.get('/tasks', queryParameters: {
      'userId': userId,
      'limit': scope?.limit,
    });
    return (response.data as List)
        .map((json) => Task.fromJson(json))
        .toList();
  }
}
```

### Caching Strategies

```dart
class CachedAdapter extends RemoteAdapter<Task> {
  final RemoteAdapter<Task> _remoteAdapter;
  final Map<String, CachedItem<Task>> _cache = {};

  @override
  Future<List<Task>> readAll({String? userId, DatumSyncScope? scope}) async {
    final cacheKey = 'tasks_$userId';

    // Check cache first
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.data;
    }

    // Fetch from remote
    final data = await _remoteAdapter.readAll(userId: userId, scope: scope);

    // Cache the result
    _cache[cacheKey] = CachedItem(data, Duration(minutes: 5));

    return data;
  }
}

class CachedItem<T> {
  final T data;
  final DateTime expiry;

  CachedItem(this.data, Duration ttl) : expiry = DateTime.now().add(ttl);

  bool get isExpired => DateTime.now().isAfter(expiry);
}
```

## Best Practices

### 1. Error Handling
```dart
class ResilientAdapter extends RemoteAdapter<Task> {
  @override
  Future<List<Task>> readAll({String? userId, DatumSyncScope? scope}) async {
    const maxRetries = 3;
    var attempt = 0;

    while (attempt < maxRetries) {
      try {
        return await _performReadAll(userId, scope);
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) rethrow;

        // Exponential backoff
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    throw Exception('Failed after $maxRetries attempts');
  }
}
```

### 2. Logging and Monitoring
```dart
class MonitoredAdapter extends RemoteAdapter<Task> {
  @override
  Future<void> create(Task item) async {
    final stopwatch = Stopwatch()..start();
    try {
      await super.create(item);
      stopwatch.stop();
      await logOperation('create', stopwatch.elapsed, success: true);
    } catch (e) {
      stopwatch.stop();
      await logOperation('create', stopwatch.elapsed, success: false, error: e);
      rethrow;
    }
  }

  Future<void> logOperation(
    String operation,
    Duration duration, {
    required bool success,
    Object? error,
  }) async {
    // Send to monitoring service
    await monitoringService.logOperation({
      'adapter': runtimeType.toString(),
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'success': success,
      'error': error?.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
```

### 3. Resource Cleanup
```dart
class DisposableAdapter extends RemoteAdapter<Task> implements Disposable {
  StreamSubscription? _subscription;
  Timer? _healthCheckTimer;

  @override
  void dispose() {
    _subscription?.cancel();
    _healthCheckTimer?.cancel();
    // Close connections, clean up resources
  }
}
```

---


*For adapter implementation details, check the [Adapter Module](../../modules/adapter.md) documentation.*
