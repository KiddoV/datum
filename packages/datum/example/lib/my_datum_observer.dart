import 'package:datum/datum.dart';
import 'package:example/bootstrap.dart';

/// A custom global observer to log key Datum events throughout the app.
class MyDatumObserver extends GlobalDatumObserver {
  @override
  void onSyncStart() {
    talker.info('🔄 Global sync cycle starting...');
  }

  @override
  void onSyncEnd(DatumSyncResult result) {
    if (result.isSuccess) {
      talker.info(
        '✅ Global sync finished. Synced: ${result.syncedCount}, Conflicts: ${result.conflictsResolved}, Duration: ${result.duration.inMilliseconds}ms',
      );
    } else if (result.wasSkipped) {
      talker.warning(
        '🟡 Sync was skipped (e.g., offline or already in progress).',
      );
    } else {
      talker.error(
        '❌ Global sync failed. Synced: ${result.syncedCount}, Failed: ${result.failedCount}',
      );
    }
  }

  @override
  void onConflictDetected(
    DatumEntityInterface local,
    DatumEntityInterface remote,
    DatumConflictContext context,
  ) {
    talker.warning(
      '⚔️  Conflict detected for ${context.entityId} of type ${local.runtimeType}',
    );
  }

  @override
  void onUserSwitchStart(
    String? oldUserId,
    String newUserId,
    UserSwitchStrategy strategy,
  ) {
    talker.info(
      '👤 User switch starting from "$oldUserId" to "$newUserId" with strategy: ${strategy.name}',
    );
  }

  @override
  void onUserSwitchEnd(DatumUserSwitchResult result) {
    talker.info('👤 User switch finished. Success: ${result.success}');
  }
}
