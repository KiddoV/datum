---
title: Supabase Remote Adapter
---
This guide shows how to use the production-ready Supabase remote adapter for Datum from the example project.

## Overview

The Datum example project provides a complete Supabase adapter implementation that includes real-time synchronization, relationship support, and comprehensive error handling. This adapter uses PostgreSQL's real-time capabilities through Supabase.

## Setup

Add Supabase dependencies to your `pubspec.yaml`:

```dart
dependencies:
  supabase_flutter: ^2.0.0
  recase: ^4.1.0
```

## Implementation

```dart
import 'dart:async';

import 'package:datum/datum.dart';
import 'package:example/bootstrap.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recase/recase.dart';

class SupabaseRemoteAdapter<T extends DatumEntityBase>
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

  // Authentication state monitoring
  StreamSubscription<AuthState>? _authSubscription;
  bool _isAuthenticated = false;
  final StreamController<bool> _authStateController = StreamController<bool>.broadcast();

  SupabaseClient get _client => _clientOverride ?? Supabase.instance.client;
  String get _metadataTableName => 'sync_metadata';

  Stream<bool> get authStateStream => _authStateController.stream;

  @override
  Future<void> delete(String id, {String? userId}) async {
    await _client.from(tableName).delete().eq(
          'id',
          id,
        );
  }

  @override
  Future<AdapterHealthStatus> checkHealth() async {
    final auth =
        Supabase.instance.client.auth.currentSession?.accessToken == null;
    return auth == true
        ? AdapterHealthStatus.unhealthy
        : AdapterHealthStatus.healthy;
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
    talker.debug("response readAll $response");
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
      throw Exception(
        'Failed to push item: upsert did not return the expected record. Check RLS policies.',
      );
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
      throw EntityNotFoundException(
        message:
            'Failed to patch item: record not found or RLS policy prevented selection.',
      );
    }
    return fromMap(_toCamelCase(response));
  }

  @override
  Future<void> updateSyncMetadata(
      DatumSyncMetadata metadata, String userId) async {
    // Check if user is authenticated before attempting to update sync metadata
    if (!_isAuthenticated) {
      talker.warning(
          "Skipping sync metadata update for user $userId: User is not authenticated");
      return;
    }

    talker
        .debug("Updating sync metadata for user: $userId with data: $metadata");
    final data = _toSnakeCase(metadata.toMap());
    data['user_id'] = userId;

    try {
      await _client.from(_metadataTableName).upsert(data);
    } catch (e) {
      // Handle RLS policy violations gracefully
      if (e is PostgrestException && e.code == '42501') {
        talker.warning(
            "Failed to update sync metadata due to RLS policy violation. User may have logged out.");
        // Mark as unauthenticated to prevent further attempts
        _updateAuthenticationState(false);
      } else {
        // Re-throw other exceptions
        rethrow;
      }
    }
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
    talker.info("Subscribing to Supabase changes for table: $tableName");
    _channel = _client
        .channel(
          'public:$tableName',
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          callback: (payload) {
            talker.info('Received Supabase change: ${payload.eventType}');
            talker.debug('Payload: $payload');

            DatumOperationType? type;
            Map<String, dynamic>? record;

            switch (payload.eventType) {
              case PostgresChangeEvent.insert:
                type = DatumOperationType.create;
                record = payload.newRecord;
                talker.debug('Insert event detected.');
                break;
              case PostgresChangeEvent.update:
                type = DatumOperationType.update;
                record = payload.newRecord;
                talker.debug('Update event detected.');
                break;
              case PostgresChangeEvent.delete:
                type = DatumOperationType.delete;
                record = payload.oldRecord;
                talker.debug('Delete event detected.');
                break;
              case PostgresChangeEvent.all:
                talker.debug('Received "all" event type, ignoring.');
                break;
            }

            if (type != null && record != null) {
              talker
                  .debug('Processing change of type $type for record: $record');
              final item = fromMap(_toCamelCase(record));
              // When a delete event comes from Supabase, the oldRecord might only
              // contain the ID. If the userId is missing, we assume the change
              // belongs to the currently authenticated user.
              final userId = item.userId.isNotEmpty
                  ? item.userId
                  : _client.auth.currentUser?.id;
              if (userId == null) {
                talker.warning(
                    'Could not determine userId for change, dropping event.');
                return;
              }
              _streamController?.add(
                DatumChangeDetail<T>(
                  type: type,
                  entityId: item.id,
                  userId: userId,
                  timestamp: item.modifiedAt,
                  data: item,
                ),
              );
              talker.info(
                  'Successfully processed and streamed change for ${item.id}');
            } else {
              talker.warning(
                  'Change event received but not processed (type or record was null).');
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
    talker.debug("Called Resub");
    unsubscribeFromChanges();
    _subscribeToChanges();
  }

  Future<void> clearSyncMetadata(String userId) async {
    await _client.from(_metadataTableName).delete().eq('user_id', userId);
  }

  // Authentication monitoring methods
  void startAuthMonitoring() {
    if (_authSubscription != null) return; // Already monitoring

    talker.info("Starting authentication state monitoring for $tableName adapter");
    _authSubscription = _client.auth.onAuthStateChange.listen(
      (AuthState authState) {
        final isAuthenticated = authState.session != null;
        _updateAuthenticationState(isAuthenticated);

        if (!isAuthenticated) {
          talker.info("User logged out, stopping sync for $tableName adapter");
          // Stop syncing when user logs out
          unsubscribeFromChanges();
        } else {
          talker.info("User logged in, resuming sync for $tableName adapter");
          // Resume syncing when user logs in
          if (_channel == null) {
            _subscribeToChanges();
          }
        }
      },
      onError: (error) {
        talker.error("Auth state monitoring error: $error");
      },
    );

    // Set initial state
    final currentSession = _client.auth.currentSession;
    _updateAuthenticationState(currentSession != null);
  }

  Future<void> _stopAuthMonitoring() async {
    if (_authSubscription != null) {
      await _authSubscription!.cancel();
      _authSubscription = null;
      talker.info("Stopped authentication state monitoring for $tableName adapter");
    }
  }

  void _updateAuthenticationState(bool isAuthenticated) {
    if (_isAuthenticated != isAuthenticated) {
      _isAuthenticated = isAuthenticated;
      _authStateController.add(isAuthenticated);
      talker.debug("Authentication state changed: $isAuthenticated for $tableName adapter");
    }
  }

  @override
  Future<void> dispose() async {
    await unsubscribeFromChanges();
    await _streamController?.close();
    await _stopAuthMonitoring();
    await _authStateController.close();
    return super.dispose();
  }

  @override
  Future<void> initialize() async {
    if (_channel == null) {
      await unsubscribeFromChanges();
      _subscribeToChanges();
    }

    // Start monitoring authentication state
    startAuthMonitoring();

    // The Supabase client is initialized globally, so no specific
    // initialization is needed for this adapter instance.
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
    // The sync engine calls `update` for full-data updates.
    // We can use `upsert` to handle both creating and replacing the entity.
    // This is simpler and more robust than calculating a diff here.
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
          talker.warning('Unsupported query operator: ${condition.operator}');
      }
    } else if (condition is CompositeFilter) {
      // Note: Supabase PostgREST builder doesn't directly support nested OR/AND
      // in this fluent way. This is a simplified implementation. For complex
      // nested logic, you might need to use `rpc` calls to database functions.
      final filters = condition.conditions.map((c) {
        // This is a simplified conversion and might not work for all cases.
        return '${(c as Filter).field.snakeCase}.${(c).operator.name}.${c.value}';
      }).join(',');
      return builder.filter(condition.operator.name, 'any', filters);
    }
    return builder;
  }

  @override
  Future<List<R>> fetchRelated<R extends DatumEntityBase>(
    RelationalDatumEntity parent,
    String relationName,
    RemoteAdapter<R> relatedAdapter,
  ) async {
    final relatedSupabaseAdapter = relatedAdapter as SupabaseRemoteAdapter<R>;
    final relatedTableName = relatedSupabaseAdapter.tableName;

    PostgrestFilterBuilder queryBuilder =
        _client.from(relatedTableName).select();

    final relation = parent.relations[relationName];

    switch (relation) {
      case BelongsTo(:var foreignKey, :var localKey):
        final relatedKeyValue = parent.toDatumMap()[localKey];
        if (relatedKeyValue == null) {
          return [];
        }
        queryBuilder = queryBuilder.eq(foreignKey.snakeCase, relatedKeyValue);
        break;
      case HasMany(:final foreignKey, :final localKey):
      case HasOne(:final foreignKey, :final localKey):
        // The foreign key is in the related table, pointing to the parent.
        final foreignKeyColumn = foreignKey.snakeCase;
        final localKeyValue = parent.toDatumMap()[localKey];
        if (localKeyValue == null) {
          return [];
        }
        queryBuilder = queryBuilder.eq(foreignKeyColumn, localKeyValue);
        break;
      case ManyToMany(
          :final otherForeignKey,
          :final otherLocalKey,
          :final thisForeignKey,
          :final thisLocalKey,
        ):
        // Get the pivot table name from the pivot entity
        final pivotAdapter = Datum.manager().remoteAdapter;
        if (pivotAdapter is! SupabaseRemoteAdapter) {
          throw ArgumentError('Pivot adapter must be a SupabaseRemoteAdapter');
        }
        final pivotTableName = pivotAdapter.tableName;

        // Get parent ID
        final parentIdValue = parent.toDatumMap()[thisLocalKey];
        if (parentIdValue == null) {
          return [];
        }

        // Query the junction table to find the IDs of related entities
        final junctionRecords = await _client
            .from(pivotTableName)
            .select(otherForeignKey.snakeCase)
            .eq(thisForeignKey.snakeCase, parentIdValue);

        if (junctionRecords.isEmpty) {
          return [];
        }

        // Extract the IDs of the related entities
        final relatedIds = junctionRecords
            .map((record) => record[otherForeignKey.snakeCase])
            .whereType<String>()
            .toList();

        if (relatedIds.isEmpty) {
          return [];
        }

        // Query the related table using the extracted IDs
        queryBuilder =
            queryBuilder.inFilter(otherLocalKey.snakeCase, relatedIds);
        break;
      case null:
        throw ArgumentError(
            'Relation "$relationName" not found for parent entity.');
    }

    final response = await queryBuilder;

    return response
        .map<R>((json) => relatedSupabaseAdapter.fromMap(_toCamelCase(json)))
        .toList();
  }

  Stream<List<R>> watchRelated<R extends DatumEntityBase>(
    RelationalDatumEntity parent,
    String relationName,
    RemoteAdapter<R> relatedAdapter,
  ) {
    final relatedSupabaseAdapter = relatedAdapter as SupabaseRemoteAdapter<R>;
    final relatedTableName = relatedSupabaseAdapter.tableName;
    final relation = parent.relations[relationName];

    if (relation == null) {
      throw ArgumentError(
          'Relation "$relationName" not found for parent entity.');
    }

    // Create a stream controller for this relationship
    late StreamController<List<R>> controller;
    RealtimeChannel? channel;

    Future<void> fetchAndEmit() async {
      try {
        final items =
            await fetchRelated<R>(parent, relationName, relatedAdapter);
        if (!controller.isClosed) {
          controller.add(items);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    void setupRealtimeSubscription() {
      final channelName =
          'related:$relatedTableName:${parent.id}:$relationName';

      channel = _client.channel(channelName).onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: relatedTableName,
            callback: (payload) {
              talker
                  .info('Related entity change detected in $relatedTableName');

              // Re-fetch and emit updated data when changes occur
              fetchAndEmit();
            },
          );

      // For ManyToMany relationships, also watch the pivot table
      if (relation is ManyToMany) {
        final pivotAdapter = Datum.manager().remoteAdapter;
        if (pivotAdapter is SupabaseRemoteAdapter) {
          final pivotTableName = pivotAdapter.tableName;
          final pivotChannelName =
              'pivot:$pivotTableName:${parent.id}:$relationName';

          final pivotChannel = _client
              .channel(pivotChannelName)
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: pivotTableName,
                callback: (payload) {
                  talker.info('Pivot table change detected in $pivotTableName');
                  fetchAndEmit();
                },
              );

          pivotChannel.subscribe();
          _relatedChannels[pivotChannelName] = pivotChannel;
        }
      }

      channel?.subscribe();
      if (channel != null) {
        _relatedChannels[channelName] = channel!;
      }
    }

    controller = StreamController<List<R>>.broadcast(
      onListen: () {
        // Fetch initial data
        fetchAndEmit();

        // Setup realtime subscription
        setupRealtimeSubscription();
      },
      onCancel: () async {
        if (channel != null) {
          await _client.removeChannel(channel!);
          _relatedChannels
              .remove('related:$relatedTableName:${parent.id}:$relationName');
        }

        // Clean up pivot channel if it exists
        if (relation is ManyToMany) {
          final pivotAdapter = Datum.manager().remoteAdapter;
          if (pivotAdapter is SupabaseRemoteAdapter) {
            final pivotTableName = pivotAdapter.tableName;
            final pivotChannelName =
                'pivot:$pivotTableName:${parent.id}:$relationName';
            final pivotChannel = _relatedChannels[pivotChannelName];
            if (pivotChannel != null) {
              await _client.removeChannel(pivotChannel);
              _relatedChannels.remove(pivotChannelName);
            }
          }
        }
      },
    );

    return controller.stream;
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

## Usage Example

```dart
// Create the adapter
final userAdapter = SupabaseRemoteAdapter<User>(
  tableName: 'users',
  fromMap: (map) => User.fromMap(map),
);

// Register with Datum
final registrations = [
  DatumRegistration<User>(
    localAdapter: HiveLocalAdapter<User>(
      boxName: 'users',
      fromMap: (map) => User.fromMap(map),
    ),
    remoteAdapter: userAdapter,
  ),
];
```

## Supabase Database Setup

### Enable Row Level Security

```dart
-- Enable RLS on all tables
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

### Real-time Configuration

Supabase automatically provides real-time capabilities. The adapter subscribes to PostgreSQL changes and converts them to Datum change events.

## Authentication State Management

The Supabase adapter includes built-in authentication state monitoring to prevent sync operations when users are not authenticated, avoiding Row Level Security (RLS) policy violations.

### Key Features

- **Automatic Sync Control**: Sync automatically stops when users log out and resumes when they log back in
- **RLS Violation Prevention**: Sync metadata updates are skipped when users are not authenticated
- **Graceful Error Handling**: RLS policy violations are caught and handled without crashing the app
- **Authentication State Stream**: External components can listen to authentication state changes

### How It Works

```dart
// Listen to authentication state changes
userAdapter.authStateStream.listen((isAuthenticated) {
  if (isAuthenticated) {
    print("User is authenticated, sync is active");
  } else {
    print("User logged out, sync is paused");
  }
});
```

### Authentication Flow

1. **Initialization**: `initialize()` starts authentication monitoring
2. **Login Detection**: When user logs in, sync channels are automatically subscribed
3. **Logout Detection**: When user logs out, all sync channels are unsubscribed
4. **Error Recovery**: If RLS errors occur, the adapter marks the user as unauthenticated
5. **Cleanup**: Authentication monitoring is properly disposed when the adapter is destroyed

### Benefits

- **No More RLS Errors**: Prevents the `42501` unauthorized errors when users log out
- **Resource Efficiency**: Stops unnecessary sync operations when users are not authenticated
- **Automatic Recovery**: Sync resumes automatically when users log back in
- **Observable State**: UI components can react to authentication state changes

## Features

- **Real-time Synchronization**: PostgreSQL change streams with automatic conversion
- **Relationship Support**: Built-in support for BelongsTo, HasMany, HasOne, and ManyToMany relationships
- **Row Level Security**: Automatic integration with Supabase RLS policies
- **Authentication State Management**: Prevents sync operations when users are not authenticated
- **Health Monitoring**: Authentication-based health checks
- **Error Handling**: Comprehensive error handling with detailed messages
- **Query Support**: Advanced filtering with PostgREST query builder
- **Sync Metadata**: Full sync state management with authentication checks

## Performance Considerations

- **Connection Pooling**: Supabase handles connection pooling automatically
- **Real-time Subscriptions**: Efficient PostgreSQL change streams
- **Query Optimization**: PostgREST provides optimized query execution
- **Batch Operations**: Support for bulk operations where applicable
- **Memory Management**: Proper cleanup of channels and controllers</content>
