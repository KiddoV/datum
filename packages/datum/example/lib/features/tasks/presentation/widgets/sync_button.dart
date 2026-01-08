import 'package:datum/datum.dart';
import 'package:example/features/tasks/presentation/controllers/simple_datum_controller.dart';
import 'package:example/shared/riverpod_ext/asynvalue_easy_when.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reusable sync button widget
class SyncButton extends ConsumerWidget {
  final String userId;
  final VoidCallback onSyncStart;
  final Function(DatumSyncResult<DatumEntityInterface>) onSyncComplete;
  final Function(dynamic) onSyncError;

  const SyncButton({
    super.key,
    required this.userId,
    required this.onSyncStart,
    required this.onSyncComplete,
    required this.onSyncError,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(syncStatusProvider(userId)).easyWhen(
          data: (status) {
            if (status?.status == DatumSyncStatus.syncing) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: Tooltip(
                    message:
                        'Syncing... ${(status!.progress * 100).toStringAsFixed(0)}%',
                    child: CircularProgressIndicator(
                      value: status.progress > 0 ? status.progress : null,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              );
            }
            return Tooltip(
              message: 'Push and pull changes with remote',
              child: IconButton(
                icon: const Icon(Icons.sync),
                onPressed: () => _handleSync(ref),
              ),
            );
          },
          loadingWidget: () => const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
  }

  Future<void> _handleSync(WidgetRef ref) async {
    ref.invalidate(syncStatusProvider(userId));
    onSyncStart();
    try {
      final result = await Datum.instance.synchronize(userId);
      onSyncComplete(result);
    } catch (e) {
      onSyncError(e);
    }
  }
}
