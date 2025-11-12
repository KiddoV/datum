import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:datum/datum.dart';
import 'package:rxdart/rxdart.dart' show Rx;

class MockRemoteAdapter<T extends DatumEntityInterface>
    implements RemoteAdapter<T> {
  MockRemoteAdapter({this.fromJson});

  final Map<String, Map<String, T>> _remoteStorage = {};
  final Map<String, DatumSyncMetadata> _remoteMetadata = {};
  bool isConnectedValue = true;
  Duration _processingDelay = Duration.zero;
  final _changeController = StreamController<DatumChangeDetail<T>>.broadcast();
  final List<String> _failedIds = [];

  /// When true, prevents push/patch/delete from emitting changes.
  bool silent = false;

  /// A function to deserialize JSON into an entity of type T.
  final T Function(Map<String, dynamic>)? fromJson;

  bool isSubscribed = true;

  @override
  Future<void> unsubscribeFromChanges() async {
    isSubscribed = false;
  }

  @override
  Future<void> resubscribeToChanges() async {
    isSubscribed = true;
  }

  @override
  String get name => 'MockRemoteAdapter';

  @override
  Future<void> initialize() async {
    // No-op for mock
  }

  void setFailedIds(List<String> ids) => _failedIds
    ..clear()
    ..addAll(ids);

  void setProcessingDelay(Duration delay) {
    _processingDelay = delay;
  }

  @override
  Future<List<T>> readAll({String? userId, DatumSyncScope? scope}) async {
    if (!isConnectedValue) throw Exception('No connection');
    var items = (userId != null
            ? _remoteStorage[userId]?.values.toList()
            : _remoteStorage.values.expand((map) => map.values).toList()) ??
        [];
    if (scope != null) {
      // Find if a 'minModifiedDate' filter exists in the query.
      final minDateFilter = scope.query.filters.firstWhereOrNull(
        (f) => f is Filter && f.field == 'minModifiedDate',
      ) as Filter?;

      if (minDateFilter != null) {
        final minDate = DateTime.parse(minDateFilter.value as String);
        items =
            items.where((item) => item.modifiedAt.isAfter(minDate)).toList();
      }
    }
    return items;
  }

  @override
  Future<T?> read(String id, {String? userId}) async {
    if (!isConnectedValue) throw Exception('No connection');
    if (userId != null) {
      return _remoteStorage[userId]?[id];
    }
    for (final userStorage in _remoteStorage.values) {
      if (userStorage.containsKey(id)) return userStorage[id];
    }
    return null;
  }

  @override
  Future<void> create(T entity) async {
    await _push(entity);
  }

  @override
  Future<void> update(T entity) async {
    await _push(entity);
  }

  Future<void> _push(T item) async {
    if (!isConnectedValue) {
      throw const NetworkException(message: 'No connection', isRetryable: true);
    }
    await Future<void>.delayed(_processingDelay);
    if (_failedIds.contains(item.id)) {
      throw NetworkException(message: 'Simulated push failure for ${item.id}');
    }
    final bool exists =
        _remoteStorage[item.userId]?.containsKey(item.id) ?? false;
    _remoteStorage.putIfAbsent(item.userId, () => {})[item.id] = item;
    if (!silent) {
      _changeController.add(
        DatumChangeDetail(
          entityId: item.id,
          userId: item.userId,
          type: exists ? DatumOperationType.update : DatumOperationType.create,
          timestamp: DateTime.now(),
          data: item,
        ),
      );
    }
  }

  @override
  Future<T> patch({
    required String id,
    required Map<String, dynamic> delta,
    String? userId,
  }) async {
    if (!isConnectedValue) {
      throw const NetworkException(message: 'No connection', isRetryable: true);
    }
    await Future<void>.delayed(_processingDelay);
    if (_failedIds.contains(id)) {
      throw NetworkException(message: 'Simulated patch failure for $id');
    }
    if (fromJson == null) {
      throw StateError(
        'MockRemoteAdapter needs a fromJson constructor to handle patch.',
      );
    }

    final existing = _remoteStorage[userId ?? '']?[id];
    if (existing == null) {
      throw Exception('Entity not found for patching in mock remote adapter.');
    }

    final json = existing.toDatumMap()..addAll(delta);
    final patchedItem = fromJson!(json);
    _remoteStorage.putIfAbsent(userId ?? '', () => {})[id] = patchedItem;
    return patchedItem;
  }

  @override
  Future<void> delete(String id, {String? userId}) async {
    if (!isConnectedValue) {
      throw const NetworkException(message: 'No connection');
    }
    await Future<void>.delayed(_processingDelay);
    final item = _remoteStorage[userId ?? '']?.remove(id);
    if (item != null) {
      if (!silent) {
        _changeController.add(
          DatumChangeDetail(
            entityId: id,
            userId: userId ?? '',
            type: DatumOperationType.delete,
            timestamp: DateTime.now(),
          ),
        );
      }
    }
  }

  @override
  Future<DatumSyncMetadata?> getSyncMetadata(String userId) async {
    return _remoteMetadata[userId];
  }

  @override
  Future<void> updateSyncMetadata(
    DatumSyncMetadata metadata,
    String userId,
  ) async {
    _remoteMetadata[userId] = metadata;
  }

  DatumSyncMetadata? metadataFor(String userId) => _remoteMetadata[userId];

  @override
  Future<bool> isConnected() async => isConnectedValue;

  void addRemoteItem(String userId, T item) {
    _remoteStorage.putIfAbsent(item.userId, () => {})[item.id] = item;
  }

  void setRemoteMetadata(String userId, DatumSyncMetadata metadata) {
    _remoteMetadata[userId] = metadata;
  }

  @override
  Future<List<T>> query(DatumQuery query, {String? userId}) async {
    if (!isConnectedValue) {
      throw const NetworkException(message: 'No connection');
    }
    // Pass the userId to readAll. If it's null, readAll will correctly
    // fetch from all users, which is the desired behavior for relational queries.
    final allItems = await readAll(userId: userId);
    return applyQuery(allItems, query);
  }

  @override
  Stream<DatumChangeDetail<T>>? get changeStream => _changeController.stream;

  /// Helper to simulate an external change for testing.
  void emitChange(DatumChangeDetail<T> change) {
    _changeController.add(change);
  }

  /// Closes the stream controller. Call this in test tearDown.
  @override
  Future<void> dispose() async {
    if (!_changeController.isClosed) await _changeController.close();
  }

  @override
  Stream<List<T>>? watchAll({String? userId, DatumSyncScope? scope}) {
    final initialDataStream = Stream.fromFuture(
      readAll(userId: userId, scope: scope),
    );
    final updateStream = changeStream!
        .where((event) => userId == null || event.userId == userId)
        .asyncMap((_) => readAll(userId: userId, scope: scope));

    return Rx.concat([initialDataStream, updateStream]);
  }

  @override
  Stream<T?>? watchById(String id, {String? userId}) {
    final initialDataStream = Stream.fromFuture(read(id, userId: userId));
    final updateStream = changeStream!
        .where(
          (event) => event.userId == (userId ?? '') && event.entityId == id,
        )
        .asyncMap((_) => read(id, userId: userId));

    return Rx.concat([initialDataStream, updateStream]);
  }

  @override
  Stream<List<T>>? watchQuery(DatumQuery query, {String? userId}) {
    // This mock remote adapter doesn't have a local query engine,
    // so we'll apply the query logic after fetching all items.
    // This simulates how a simple REST API adapter might work with client-side filtering.
    Future<List<T>> getFiltered() async {
      final allItems = await readAll(userId: userId);
      // We can use the query logic from the MockLocalAdapter for this.
      // In a real remote adapter (e.g., Firestore), this logic would be
      // translated into a server-side query.
      return applyQuery(allItems, query);
    }

    final initialDataStream = Stream.fromFuture(getFiltered());
    final updateStream = changeStream!
        .where((event) => userId == null || event.userId == userId)
        .asyncMap((_) => getFiltered());

    return Rx.concat([initialDataStream, updateStream]);
  }

  @override
  Future<List<R>> fetchRelated<R extends DatumEntityInterface>(
    RelationalDatumEntity parent,
    String relationName,
    RemoteAdapter<R> relatedAdapter,
  ) async {
    final relation = parent.relations[relationName];
    if (relation == null) {
      throw Exception(
        'Relation "$relationName" not found on ${parent.runtimeType}.',
      );
    }

    switch (relation) {
      case BelongsTo():
        final foreignKeyField = relation.foreignKey;
        final parentMap = parent.toDatumMap();
        final foreignKeyValue = parentMap[foreignKeyField] as String?;

        if (foreignKeyValue == null) {
          return [];
        }

        final relatedItem = await relatedAdapter.read(foreignKeyValue);
        return relatedItem != null ? [relatedItem] : [];
      case HasMany():
        final foreignKeyField = relation.foreignKey;
        final parentId = parent.id;
        final query = DatumQuery(
          filters: [Filter(foreignKeyField, FilterOperator.equals, parentId)],
        );
        return relatedAdapter.query(query);
      case ManyToMany():
        // 1. Get the manager for the pivot entity.
        final pivotManager = Datum.managerByType(
          relation.pivotEntity.runtimeType,
        );
        // 2. Query the pivot table to find all entries matching the parent's local key.
        final pivotQuery = DatumQuery(
          filters: [
            Filter(
              relation.thisForeignKey,
              FilterOperator.equals,
              parent.toDatumMap()[relation.thisLocalKey],
            ),
          ],
        );
        final pivotEntries = await pivotManager.remoteAdapter.query(pivotQuery);

        if (pivotEntries.isEmpty) {
          return [];
        }

        // 3. Extract the IDs of the "other" side of the relationship.
        final otherIds = pivotEntries
            .map((e) => e.toDatumMap()[relation.otherForeignKey] as String?)
            .where((id) => id != null && id.isNotEmpty)
            .cast<String>()
            .toList();

        if (otherIds.isEmpty) return [];

        // 4. Fetch the related entities using the extracted IDs.
        return relatedAdapter.query(
          DatumQuery(
            filters: [
              Filter(relation.otherLocalKey, FilterOperator.isIn, otherIds),
            ],
          ),
        );
      case HasOne():
        final foreignKeyField = relation.foreignKey;
        final localKeyValue = parent.toDatumMap()[relation.localKey];
        final query = DatumQuery(
          filters: [
            Filter(foreignKeyField, FilterOperator.equals, localKeyValue),
          ],
        );
        return relatedAdapter.query(query);
    }
  }

  @override
  Future<AdapterHealthStatus> checkHealth() async {
    return AdapterHealthStatus.healthy;
  }
}

/// A helper function to apply query filters and sorting to a list of items.
List<T> applyQuery<T extends DatumEntityInterface>(
    List<T> items, DatumQuery query) {
  var filteredItems = items.where((item) {
    final json = item.toDatumMap();
    if (query.logicalOperator == LogicalOperator.and) {
      return query.filters.every((filter) => _matches(json, filter));
    } else {
      return query.filters.any((filter) => _matches(json, filter));
    }
  }).toList();

  if (query.sorting.isNotEmpty) {
    filteredItems.sort((a, b) {
      for (final sort in query.sorting) {
        final valA = a.toDatumMap()[sort.field];
        final valB = b.toDatumMap()[sort.field];

        if (valA == null && valB == null) continue;
        if (valA == null) {
          return sort.nullSortOrder == NullSortOrder.first ? -1 : 1;
        }
        if (valB == null) {
          return sort.nullSortOrder == NullSortOrder.first ? 1 : -1;
        }

        if (valA is Comparable && valB is Comparable) {
          final comparison = valA.compareTo(valB);
          if (comparison != 0) {
            return sort.descending ? -comparison : comparison;
          }
        }
      }
      return 0;
    });
  }

  if (query.offset != null) {
    filteredItems = filteredItems.skip(query.offset!).toList();
  }
  if (query.limit != null) {
    filteredItems = filteredItems.take(query.limit!).toList();
  }

  return filteredItems;
}

bool _matches(Map<String, dynamic> json, FilterCondition condition) {
  if (condition is Filter) {
    final value = json[condition.field];
    if (value == null &&
        condition.operator != FilterOperator.isNull &&
        condition.operator != FilterOperator.isNotNull) {
      return false;
    }

    switch (condition.operator) {
      case FilterOperator.equals:
        return value == condition.value;
      case FilterOperator.notEquals:
        return value != condition.value;
      case FilterOperator.greaterThan:
        return value is Comparable && value.compareTo(condition.value) > 0;
      case FilterOperator.greaterThanOrEqual:
        return value is Comparable && value.compareTo(condition.value) >= 0;
      case FilterOperator.lessThan:
        return value is Comparable && value.compareTo(condition.value) < 0;
      case FilterOperator.lessThanOrEqual:
        return value is Comparable && value.compareTo(condition.value) <= 0;
      case FilterOperator.contains:
        return value is String && value.contains(condition.value as String);
      case FilterOperator.isIn:
        return condition.value is List &&
            (condition.value as List).contains(value);
      case FilterOperator.isNotIn:
        return condition.value is List &&
            !(condition.value as List).contains(value);
      case FilterOperator.isNull:
        return value == null;
      case FilterOperator.isNotNull:
        return value != null;
      case FilterOperator.containsIgnoreCase:
        return value is String &&
            condition.value is String &&
            value.toLowerCase().contains(
                  (condition.value as String).toLowerCase(),
                );
      case FilterOperator.startsWith:
        return value is String &&
            condition.value is String &&
            value.startsWith(condition.value as String);
      case FilterOperator.endsWith:
        return value is String &&
            condition.value is String &&
            value.endsWith(condition.value as String);
      case FilterOperator.arrayContains:
        return value is List && value.contains(condition.value);
      case FilterOperator.arrayContainsAny:
        if (value is! List || condition.value is! List) return false;
        final valueSet = value.toSet();
        return (condition.value as List).any(valueSet.contains);
      case FilterOperator.matches:
        return value is String &&
            condition.value is String &&
            RegExp(condition.value as String).hasMatch(value);
      case FilterOperator.withinDistance:
        if (value is! Map || condition.value is! Map) return false;
        final point = value as Map<String, dynamic>;
        final params = condition.value as Map<String, dynamic>;
        final center = params['center'] as Map<String, double>?;
        final radius = params['radius'] as double?;
        if (point['latitude'] == null ||
            point['longitude'] == null ||
            center == null ||
            radius == null) {
          return false;
        }
        final distance = _haversineDistance(
          point['latitude'] as double,
          point['longitude'] as double,
          center['latitude']!,
          center['longitude']!,
        );
        return distance <= radius;
      case FilterOperator.between:
        if (value is! Comparable || condition.value is! List) return false;
        final bounds = condition.value as List;
        if (bounds.length != 2) return false;
        return value.compareTo(bounds[0]) >= 0 &&
            value.compareTo(bounds[1]) <= 0;
    }
  } else if (condition is CompositeFilter) {
    if (condition.operator == LogicalOperator.and) {
      return condition.conditions.every((c) => _matches(json, c));
    } else {
      return condition.conditions.any((c) => _matches(json, c));
    }
  }
  return false;
}

double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371e3; // Earth's radius in metres
  final phi1 = lat1 * pi / 180;
  final phi2 = lat2 * pi / 180;
  final deltaPhi = (lat2 - lat1) * pi / 180;
  final deltaLambda = (lon2 - lon1) * pi / 180;

  final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
      cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return r * c;
}
