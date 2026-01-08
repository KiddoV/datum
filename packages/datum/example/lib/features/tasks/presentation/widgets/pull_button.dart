import 'package:datum/datum.dart';
import 'package:flutter/material.dart';

/// Reusable pull/refresh button widget
class PullButton extends StatelessWidget {
  final String userId;
  final VoidCallback onPullStart;
  final Function(DatumSyncResult<DatumEntityInterface>) onPullComplete;
  final Function(dynamic) onPullError;

  const PullButton({
    super.key,
    required this.userId,
    required this.onPullStart,
    required this.onPullComplete,
    required this.onPullError,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Pull latest changes from remote',
      child: IconButton(
        icon: const Icon(Icons.cloud_download_outlined),
        onPressed: _handlePull,
      ),
    );
  }

  Future<void> _handlePull() async {
    onPullStart();
    try {
      final result = await Datum.instance.synchronize(
        userId,
        options: const DatumSyncOptions(
          direction: SyncDirection.pullOnly,
        ),
      );
      onPullComplete(result);
    } catch (e) {
      onPullError(e);
    }
  }
}
