import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:datum/source/core/models/datum_sync_status_snapshot.dart';
import 'package:example/features/simple_datum/controller/entity_sync_status_provider.dart';

/// Widget that displays detailed entity-level data for sync operations
class EntityDetailedDataWidget extends ConsumerWidget {
  final Type entityType;
  final String userId;

  const EntityDetailedDataWidget({
    super.key,
    required this.entityType,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entityStatusAsync = ref.watch(
        entitySyncStatusProvider((userId: userId, entityType: entityType)));

    return entityStatusAsync.when(
      data: (status) => _buildDetailedCard(context, status),
      loading: () => _buildLoadingCard(context),
      error: (error, stack) => _buildErrorCard(context),
    );
  }

  Widget _buildDetailedCard(
      BuildContext context, DatumSyncStatusSnapshot status) {
    final entityName = _getEntityName();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with entity name and status
            Row(
              children: [
                Text(
                  entityName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 8),

            // Progress bar if syncing
            if (status.status == DatumSyncStatus.syncing) ...[
              LinearProgressIndicator(
                value: status.progress,
                backgroundColor: Colors.grey[300],
                valueColor:
                    AlwaysStoppedAnimation<Color>(_getStatusColor(status)),
              ),
              const SizedBox(height: 8),
            ],

            // Key metrics in a grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Synced',
                    status.syncedCount.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Pending',
                    status.pendingOperations.toString(),
                    Icons.schedule,
                    status.pendingOperations > 0 ? Colors.orange : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Conflicts',
                    status.conflictsResolved.toString(),
                    Icons.warning,
                    status.conflictsResolved > 0 ? Colors.amber : Colors.grey,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Failed',
                    status.failedOperations.toString(),
                    Icons.error,
                    status.failedOperations > 0 ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),

            // Last sync information
            if (status.lastCompletedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Last sync: ${_formatDateTime(status.lastCompletedAt!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],

            // Health status
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.health_and_safety,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Health: ${status.health.status.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(DatumSyncStatusSnapshot status) {
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);
    final text = _getStatusText(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error, size: 16, color: Colors.red),
              SizedBox(width: 4),
              Text(
                'Failed to load data',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
        ),
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

  String _getStatusText(DatumSyncStatusSnapshot status) {
    switch (status.status) {
      case DatumSyncStatus.syncing:
        return 'Syncing';
      case DatumSyncStatus.completed:
        return 'Completed';
      case DatumSyncStatus.failed:
        return 'Failed';
      case DatumSyncStatus.paused:
        return 'Paused';
      case DatumSyncStatus.cancelled:
        return 'Cancelled';
      case DatumSyncStatus.idle:
        return status.pendingOperations > 0 ? 'Pending' : 'Idle';
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
