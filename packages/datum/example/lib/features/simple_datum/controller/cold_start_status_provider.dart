// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:datum/datum.dart';
import 'package:datum/source/core/models/cold_start_strategy.dart';
import 'package:example/data/task/entity/task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that exposes cold start sync status for the Task entity
final coldStartStatusProvider =
    StreamProvider.autoDispose.family<ColdStartStatus, String>((ref, userId) {
  final taskManager = Datum.manager<Task>();

  return Stream.value(ColdStartStatus(
    isColdStart: taskManager.coldStartManager.isColdStartForUser(userId),
    lastColdStartTime: taskManager.coldStartManager.getLastColdStartTimeForUser(userId),
    strategy: taskManager.config.coldStartConfig.strategy,
  ));
});

/// Simple data class to represent cold start status
class ColdStartStatus {
  final bool isColdStart;
  final DateTime? lastColdStartTime;
  final ColdStartStrategy strategy;

  const ColdStartStatus({
    required this.isColdStart,
    required this.lastColdStartTime,
    required this.strategy,
  });

  static const unknown = ColdStartStatus(
    isColdStart: false,
    lastColdStartTime: null,
    strategy: ColdStartStrategy.disabled,
  );

  String get statusText {
    if (isColdStart) {
      return 'Cold Start Active (${strategy.name})';
    } else {
      return 'Cold Start Completed (${strategy.name})';
    }
  }

  String get lastSyncText {
    if (lastColdStartTime == null) {
      return 'Never synced';
    }
    final duration = DateTime.now().difference(lastColdStartTime!);
    if (duration.inMinutes < 1) {
      return 'Just now';
    } else if (duration.inHours < 1) {
      return '${duration.inMinutes}m ago';
    } else if (duration.inDays < 1) {
      return '${duration.inHours}h ago';
    } else {
      return '${duration.inDays}d ago';
    }
  }

  @override
  bool operator ==(covariant ColdStartStatus other) {
    if (identical(this, other)) return true;

    return other.isColdStart == isColdStart &&
        other.lastColdStartTime == lastColdStartTime &&
        other.strategy == strategy;
  }

  @override
  int get hashCode =>
      isColdStart.hashCode ^ lastColdStartTime.hashCode ^ strategy.hashCode;
}
