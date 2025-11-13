import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:datum/source/core/models/datum_sync_status_snapshot.dart';
import 'package:example/features/simple_datum/controller/entity_sync_status_provider.dart';

/// Widget that displays sync status for a specific entity
class EntitySyncStatusWidget extends ConsumerWidget {
  final Type entityType;
  final String userId;

  const EntitySyncStatusWidget({
    super.key,
    required this.entityType,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entityStatusAsync = ref.watch(
        entitySyncStatusProvider((userId: userId, entityType: entityType)));

    return entityStatusAsync.when(
      data: (status) => _buildStatusChip(context, status),
      loading: () => _buildLoadingChip(context),
      error: (error, stack) => _buildErrorChip(context),
    );
  }

  Widget _buildStatusChip(
      BuildContext context, DatumSyncStatusSnapshot status) {
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            _getEntityName(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (status.pendingOperations > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${status.pendingOperations}',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 4),
          Text(
            _getEntityName(),
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error, size: 16, color: Colors.red),
          const SizedBox(width: 4),
          Text(
            _getEntityName(),
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(DatumSyncStatusSnapshot status) {
    switch (status.status) {
      case DatumSyncStatus.syncing:
        return Colors.blue;
      case DatumSyncStatus.completed:
        return Colors.green;
      case DatumSyncStatus.failed:
        return Colors.red;
      case DatumSyncStatus.paused:
        return Colors.orange;
      case DatumSyncStatus.cancelled:
        return Colors.grey;
      case DatumSyncStatus.idle:
        return status.pendingOperations > 0 ? Colors.orange : Colors.green;
    }
  }

  IconData _getStatusIcon(DatumSyncStatusSnapshot status) {
    switch (status.status) {
      case DatumSyncStatus.syncing:
        return Icons.sync;
      case DatumSyncStatus.completed:
        return Icons.check_circle;
      case DatumSyncStatus.failed:
        return Icons.error;
      case DatumSyncStatus.paused:
        return Icons.pause;
      case DatumSyncStatus.cancelled:
        return Icons.cancel;
      case DatumSyncStatus.idle:
        return status.pendingOperations > 0
            ? Icons.schedule
            : Icons.check_circle;
    }
  }

  String _getEntityName() {
    final typeName = entityType.toString();
    // Remove generic type parameters if present
    final baseName = typeName.split('<').first;
    // Convert PascalCase to Title Case
    return baseName.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => match.group(1) == baseName[0]
          ? match.group(1)!
          : ' ${match.group(1)!}',
    );
  }
}
