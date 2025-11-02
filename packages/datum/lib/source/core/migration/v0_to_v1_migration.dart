import 'package:datum/datum.dart';

/// Migration from schema version 0 to 1.
/// Adds the 'conflictCount', 'devices', 'lastSuccessfulSyncTime', 'syncStatus',
/// 'syncVersion', 'serverTimestamp', 'errorMessage', 'retryCount', 'syncDuration'
/// fields to DatumSyncMetadata.
class V0toV1Migration extends Migration {
  @override
  int get fromVersion => 0;

  @override
  int get toVersion => 1;

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> data) {
    // Check if this is a DatumSyncMetadata entity
    if (data['__typename'] == 'DatumSyncMetadata') {
      if (!data.containsKey('conflictCount')) {
        data['conflictCount'] = 0;
      }
      if (!data.containsKey('devices')) {
        data['devices'] = null; // Or an empty map if preferred
      }
      if (!data.containsKey('lastSuccessfulSyncTime')) {
        data['lastSuccessfulSyncTime'] = null;
      }
      if (!data.containsKey('syncStatus')) {
        data['syncStatus'] = SyncStatus.neverSynced.toString().split('.').last;
      }
      if (!data.containsKey('syncVersion')) {
        data['syncVersion'] = 1;
      }
      if (!data.containsKey('serverTimestamp')) {
        data['serverTimestamp'] = null;
      }
      if (!data.containsKey('errorMessage')) {
        data['errorMessage'] = null;
      }
      if (!data.containsKey('retryCount')) {
        data['retryCount'] = 0;
      }
      if (!data.containsKey('syncDuration')) {
        data['syncDuration'] = null;
      }
    }
    return data;
  }
}