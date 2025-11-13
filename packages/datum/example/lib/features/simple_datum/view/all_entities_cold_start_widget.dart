import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:example/features/simple_datum/controller/cold_start_status_provider.dart';

/// Widget that displays cold start status for all entities
class AllEntitiesColdStartWidget extends ConsumerWidget {
  const AllEntitiesColdStartWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(userIdProvider);
    if (userId == null) return const SizedBox.shrink();

    final coldStartStatusesAsync =
        ref.watch(allEntitiesColdStartStatusProvider(userId));

    return coldStartStatusesAsync.when(
      data: (statuses) => _buildColdStartChips(context, statuses),
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildColdStartChips(
      BuildContext context, Map<Type, ColdStartStatus> statuses) {
    final activeColdStarts =
        statuses.entries.where((entry) => entry.value.isColdStart).toList();

    if (activeColdStarts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      children: activeColdStarts
          .map((entry) => _buildColdStartChip(context, entry.key, entry.value))
          .toList(),
    );
  }

  Widget _buildColdStartChip(
      BuildContext context, Type entityType, ColdStartStatus status) {
    final color = Colors.orange;
    final icon = Icons.sync;

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
            _getEntityName(entityType),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Cold Start',
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _getEntityName(Type entityType) {
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

/// Provider to get current user ID from Supabase
final userIdProvider = Provider<String?>((ref) {
  // Get user ID from Supabase auth
  try {
    return Supabase.instance.client.auth.currentUser?.id;
  } catch (e) {
    return null;
  }
});
