import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:example/features/tasks/presentation/controllers/cold_start_status_provider.dart';

/// Widget that displays cold start sync status
class ColdStartStatusWidget extends ConsumerWidget {
  const ColdStartStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      return const SizedBox.shrink();
    }

    final coldStartAsync = ref.watch(coldStartStatusProvider(userId));

    return coldStartAsync.when(
      data: (status) => _buildStatusChip(context, status),
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatusChip(BuildContext context, ColdStartStatus status) {
    final color = status.isColdStart ? Colors.orange : Colors.green;
    final icon = status.isColdStart ? Icons.sync : Icons.check_circle;

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
            status.statusText,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!status.isColdStart && status.lastColdStartTime != null) ...[
            const SizedBox(width: 8),
            Text(
              status.lastSyncText,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
