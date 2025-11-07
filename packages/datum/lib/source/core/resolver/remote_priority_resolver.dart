import 'dart:async';

import 'package:datum/datum.dart';

/// Resolves conflicts by always preferring the remote version of the entity.
/// If the remote version does not exist, it will use the local version.
class RemotePriorityResolver<T extends DatumEntityInterface> implements DatumConflictResolver<T> {
  @override
  String get name => 'RemotePriority';

  @override
  FutureOr<DatumConflictResolution<T>> resolve({
    T? local,
    T? remote,
    required DatumConflictContext context,
  }) {
    if (remote != null) {
      return DatumConflictResolution.useRemote(remote);
    }

    if (local != null) {
      return DatumConflictResolution.useLocal(local);
    }

    return const DatumConflictResolution.abort(
      'No data available to resolve conflict.',
    );
  }
}
