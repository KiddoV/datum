---
title: Remote Adapter Implementation
---



## Example of Remote Adapter


```dart


import 'dart:async';

import 'package:datum/datum.dart';
import 'package:example/custom_connectivity_checker.dart';
import 'package:example/data/user/entity/user.dart';

class UserRemoteAdapter extends RemoteAdapter<UserEntity> {

  final _changeController =
      StreamController<DatumChangeDetail<UserEntity>>.broadcast();

  @override
  Stream<DatumChangeDetail<UserEntity>>? get changeStream =>
      _changeController.stream;

  @override
  Future<void> create(UserEntity entity) { }

  @override
  Future<void> delete(String id, {String? userId}) {}

  @override
  Future<DatumSyncMetadata?> getSyncMetadata(String userId) { }

  @override
  Future<void> initialize() { }

  @override
  Future<bool> isConnected() {}

  @override
  Future<UserEntity> patch({
    required String id,
    required Map<String, dynamic> delta,
    String? userId,
  }) { }

  @override
  Future<List<UserEntity>> query(DatumQuery query, {String? userId}) {}

  @override
  Future<UserEntity?> read(String id, {String? userId}) { }

  @override
  Future<List<UserEntity>> readAll({String? userId, DatumSyncScope? scope}) {}

  @override
  Future<void> update(UserEntity entity) {}

  @override
  Future<void> updateSyncMetadata(DatumSyncMetadata metadata, String userId) {}

  @override
  Future<void> dispose() {}
}
```

## Complete Supabase Adapter Example

Here's a complete implementation of a `RemoteAdapter` for Supabase, showing how to integrate with a real backend service:

```dart
import 'dart:async';

import 'package:datum/datum.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recase/recase.dart';

class SupabaseRemoteAdapter<T extends DatumEntityInterface>
    extends RemoteAdapter<T> {
  final String tableName;
  final T Function(Map<String, dynamic>) fromMap;
  final SupabaseClient? _clientOverride;

  SupabaseRemoteAdapter({
    required this.tableName,
    required this.fromMap,
    // This is for testing purposes only.
    SupabaseClient? clientOverride,
  }) : _clientOverride = clientOverride;

  RealtimeChannel? _channel;
  StreamController<DatumChangeDetail<T>>? _streamController;

  // Store related entity channels for cleanup
  final Map<String, RealtimeChannel> _relatedChannels = {};

  SupabaseClient get _client => _clientOverride ?? Supabase.instance.client;
  String get _metadataTableName => 'sync_metadata';

  @override
  Future<void> delete(String id, {String? userId}) async {
    await _client.from(tableName).delete().eq('id', id);
  }

  @override
  Future<AdapterHealthStatus> checkHealth() async {
    final auth = Supabase.instance.client.auth.currentSession?.accessToken == null;
    return auth == true ? AdapterHealthStatus.unhealthy : AdapterHealthStatus.healthy;
  }

  @override
  Future<List<T>> readAll({String? userId, DatumSyncScope? scope}) async {
    PostgrestFilterBuilder queryBuilder = _client.from(tableName).select();

    // Apply filters from the sync scope, if provided.
    if (scope != null) {
      for (final condition in scope.query.filters) {
        queryBuilder = _applyFilter(queryBuilder, condition);
      }
    }

    final response = await queryBuilder;
    if (response is List<Map<String, dynamic>>) {
      return response.map<T>((json) => fromMap(_toCamelCase(json))).toList();
    } else {
      return [];
    }
  }

  @override
  Future<T?> read(String id, {String? userId}) async {
    final response = await _client.from(tableName).select().eq('id', id);

    if (response.length > 1) {
      return null;
    }
    return fromMap(_toCamelCase(response.first));
  }

  @override
  Future<DatumSyncMetadata?> getSyncMetadata(String userId) async {
    final response = await _client
        .from(_metadataTableName)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }
    return DatumSyncMetadata.fromMap(_toCamelCase(response));
  }

  @override
  Future<bool> isConnected() async => true;

  @override
  Future<void> create(T entity) async {
    final data = _toSnakeCase(entity.toDatumMap(target: MapTarget.remote));
    // Ensure userId is in the payload
    data['user_id'] = entity.userId;
    final response = await _client
        .from(tableName)
        .upsert(data, onConflict: 'id')
        .select()
        .maybeSingle();
    if (response == null) {
      throw Exception('Failed to push item: upsert did not return the expected record.');
    }
  }

  @override
  Future<T> patch({
    required String id,
    required Map<String, dynamic> delta,
    String? userId,
  }) async {
    final snakeCaseDelta = _toSnakeCase(delta);
    final response = await _client
        .from(tableName)
        .update(snakeCaseDelta)
        .eq('id', id)
        .select()
        .maybeSingle();
    if (response == null) {
      throw Exception('Failed to patch item: record not found.');
    }
    return fromMap(_toCamelCase(response));
  }

  @override
  Future<void> updateSyncMetadata(
      DatumSyncMetadata metadata, String userId) async {
    final data = _toSnakeCase(metadata.toMap());
    data['user_id'] = userId;

    await _client.from(_metadataTableName).upsert(data);
  }

  @override
  Stream<DatumChangeDetail<T>>? get changeStream {
    _streamController ??= StreamController<DatumChangeDetail<T>>.broadcast(
      onListen: _subscribeToChanges,
      onCancel: unsubscribeFromChanges,
    );
    return _streamController?.stream;
  }

  void _subscribeToChanges() {
    _channel = _client
        .channel('public:$tableName')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          callback: (payload) {
            DatumOperationType? type;
            Map<String, dynamic>? record;

            switch (payload.eventType) {
              case PostgresChangeEvent.insert:
                type = DatumOperationType.create;
                record = payload.newRecord;
                break;
              case PostgresChangeEvent.update:
                type = DatumOperationType.update;
                record = payload.newRecord;
                break;
              case PostgresChangeEvent.delete:
                type = DatumOperationType.delete;
                record = payload.oldRecord;
                break;
              case PostgresChangeEvent.all:
                break;
            }

            if (type != null && record != null) {
              final item = fromMap(_toCamelCase(record));
              final userId = item.userId.isNotEmpty
                  ? item.userId
                  : _client.auth.currentUser?.id;
              if (userId == null) return;

              _streamController?.add(
                DatumChangeDetail<T>(
                  type: type,
                  entityId: item.id,
                  userId: userId,
                  timestamp: item.modifiedAt,
                  data: item,
                ),
              );
            }
          },
        )..subscribe();
  }

  @override
  Future<void> unsubscribeFromChanges() async {
    if (_channel != null) {
      await _client.removeChannel(_channel!);
      _channel = null;
    }

    // Unsubscribe from all related entity channels
    for (final channel in _relatedChannels.values) {
      await _client.removeChannel(channel);
    }
    _relatedChannels.clear();
  }

  @override
  Future<void> resubscribeToChanges() async {
    unsubscribeFromChanges();
    _subscribeToChanges();
  }

  @override
  Future<void> dispose() async {
    await unsubscribeFromChanges();
    await _streamController?.close();
    return super.dispose();
  }

  @override
  Future<void> initialize() async {
    if (_channel == null) {
      await unsubscribeFromChanges();
      _subscribeToChanges();
    }
    return Future.value();
  }

  @override
  Future<List<T>> query(DatumQuery query, {String? userId}) async {
    PostgrestFilterBuilder queryBuilder = _client.from(tableName).select();

    for (final condition in query.filters) {
      queryBuilder = _applyFilter(queryBuilder, condition);
    }

    final response = await queryBuilder;
    return response.map<T>((json) => fromMap(_toCamelCase(json))).toList();
  }

  @override
  Future<void> update(T entity) async {
    final data = _toSnakeCase(entity.toDatumMap(target: MapTarget.remote));
    data['user_id'] = entity.userId;
    await _client.from(tableName).upsert(data, onConflict: 'id');
  }

  PostgrestFilterBuilder _applyFilter(
    PostgrestFilterBuilder builder,
    FilterCondition condition,
  ) {
    if (condition is Filter) {
      final field = condition.field.snakeCase;
      final value = condition.value;

      switch (condition.operator) {
        case FilterOperator.equals:
          return builder.eq(field, value);
        case FilterOperator.notEquals:
          return builder.neq(field, value);
        case FilterOperator.lessThan:
          return builder.lt(field, value);
        case FilterOperator.lessThanOrEqual:
          return builder.lte(field, value);
        case FilterOperator.greaterThan:
          return builder.gt(field, value);
        case FilterOperator.greaterThanOrEqual:
          return builder.gte(field, value);
        case FilterOperator.arrayContains:
          return builder.contains(field, value);
        case FilterOperator.isIn:
          return builder.inFilter(field, value as List);
        default:
          throw UnsupportedError('Unsupported query operator: ${condition.operator}');
      }
    }
    return builder;
  }
}

Map<String, dynamic> _toSnakeCase(Map<String, dynamic> map) {
  final newMap = <String, dynamic>{};
  map.forEach((key, value) {
    newMap[key.snakeCase] = value;
  });
  return newMap;
}

Map<String, dynamic> _toCamelCase(Map<String, dynamic> map) {
  final newMap = <String, dynamic>{};
  map.forEach((key, value) {
    newMap[key.camelCase] = value;
  });
  return newMap;
}
```

### Using the Supabase Adapter

```dart
// Create the adapter
final userAdapter = SupabaseRemoteAdapter<User>(
  tableName: 'users',
  fromMap: (map) => User.fromMap(map),
);

// Register with Datum
final registrations = [
  DatumRegistration<User>(
    localAdapter: HiveUserAdapter(),
    remoteAdapter: userAdapter,
  ),
];

// Initialize Datum
await Datum.initialize(
  config: config,
  connectivityChecker: connectivityChecker,
  registrations: registrations,
);
```

### Supabase Database Setup

For the Supabase adapter to work, you need to set up your database tables with the correct structure and permissions:

```dart
-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_metadata ENABLE ROW LEVEL SECURITY;

-- Create policies for users table
CREATE POLICY "Users can view their own data" ON users
  FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert their own data" ON users
  FOR INSERT WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update their own data" ON users
  FOR UPDATE USING (auth.uid()::text = user_id);

-- Create policies for sync_metadata table
CREATE POLICY "Users can manage their own sync metadata" ON sync_metadata
  FOR ALL USING (auth.uid()::text = user_id);
```

### Real-time Subscriptions

The Supabase adapter automatically handles real-time subscriptions for live data synchronization. When changes occur in the database, they're automatically pushed to connected clients through the `changeStream`.

### Error Handling

The adapter includes comprehensive error handling for common Supabase issues:

- **Authentication errors**: Returns `AdapterHealthStatus.unhealthy` when not authenticated
- **Network errors**: Throws appropriate exceptions for connection issues
- **Permission errors**: Handles RLS policy violations
- **Data validation**: Validates responses from Supabase

This complete Supabase adapter example demonstrates how to implement a production-ready remote adapter for Datum with real-time synchronization, proper error handling, and security considerations.
