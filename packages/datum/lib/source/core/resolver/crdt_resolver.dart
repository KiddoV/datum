import 'dart:async';

import 'package:datum/datum.dart';

/// A resolver that use the entity's built-in merge logic.
///
/// This is specifically designed for entities with CRDT fields that handle
/// their own merge logic, allowing for merge-less conflict resolution.
class CRDTResolver<T extends DatumEntityInterface> implements DatumConflictResolver<T> {
  const CRDTResolver();

  @override
  String get name => 'CRDTMerge';

  @override
  Future<DatumConflictResolution<T>> resolve({
    T? local,
    T? remote,
    required DatumConflictContext context,
  }) async {
    if (local == null && remote == null) {
      return DatumConflictResolution.abort(
        'No entities supplied to CRDT resolver.',
      );
    }

    if (local == null || remote == null) {
      return DatumConflictResolution.abort(
        'CRDT merge requires both local and remote data to be available.',
      );
    }

    final merged = local.merge(remote) as T;

    return DatumConflictResolution.merge(merged);
  }
}
