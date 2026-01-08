import 'package:example/features/tasks/data/entities/task.dart';
import 'package:example/features/tasks/presentation/controllers/entity_sync_status_provider.dart';
import 'package:example/features/tasks/presentation/controllers/simple_datum_controller.dart';
import 'package:example/shared/helper/global_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class TaskListItem extends ConsumerStatefulWidget {
  const TaskListItem({
    super.key,
    required this.task,
    required this.onUpdate,
    required this.onDelete,
  });

  final Task task;
  final void Function(Task) onUpdate;
  final void Function(Task) onDelete;

  @override
  ConsumerState<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends ConsumerState<TaskListItem> with GlobalHelper {
  @override
  Widget build(BuildContext context) {
    // Get last sync time
    final lastSyncTimeAsync =
        ref.watch(lastSyncTimeProvider(widget.task.userId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ShadCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            Transform.scale(
              scale: 1.2,
              child: Checkbox(
                value: widget.task.isCompleted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                activeColor: Colors.black,
                onChanged: (isCompleted) async {
                  if (isCompleted == null) return;
                  final updatedTask = widget.task.copyWith(
                    isCompleted: isCompleted,
                    modifiedAt: DateTime.now(),
                  );
                  try {
                    await ref
                        .read(simpleDatumControllerProvider.notifier)
                        .updateTask(updatedTask);
                  } catch (e) {
                    if (context.mounted) {
                      showErrorSnack(child: Text('Error: $e'));
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8), // Align with checkbox roughly
                  Text(
                    widget.task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      decoration: widget.task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: widget.task.isCompleted
                          ? Colors.grey.shade500
                          : Colors.black87,
                    ),
                  ),
                  if (widget.task.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.task.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        decoration: widget.task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Actions & Sync Status
            Column(
              children: [
                _buildSyncStatus(lastSyncTimeAsync),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShadButton.ghost(
                      width: 32,
                      height: 32,
                      padding: EdgeInsets.zero,
                      onPressed: () => widget.onUpdate(widget.task),
                      child: const Icon(Icons.edit, size: 16),
                    ),
                    ShadButton.ghost(
                      width: 32,
                      height: 32,
                      padding: EdgeInsets.zero,
                      hoverBackgroundColor: Colors.red.withValues(alpha: 0.1),
                      foregroundColor: Colors.red,
                      onPressed: () => widget.onDelete(widget.task),
                      child:
                          const Icon(Icons.delete, size: 16, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatus(AsyncValue<DateTime?> lastSyncTimeAsync) {
    return lastSyncTimeAsync.when(
      data: (lastSyncTime) {
        final isPending = lastSyncTime == null ||
            widget.task.modifiedAt.isAfter(lastSyncTime);
        if (!isPending) return const SizedBox.shrink();

        return Tooltip(
          message: 'Pending sync',
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Icon(
              Icons.cloud_upload_outlined,
              size: 14,
              color: Colors.orange.shade700,
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) =>
          const Icon(Icons.error_outline, size: 14, color: Colors.red),
    );
  }
}
