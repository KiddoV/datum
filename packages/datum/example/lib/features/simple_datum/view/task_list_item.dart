import 'package:example/data/task/entity/task.dart';
import 'package:example/features/simple_datum/controller/entity_sync_status_provider.dart';
import 'package:example/features/simple_datum/view/simple_datum_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskListItem extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    // Get last sync time to compare with task modification time
    final lastSyncTimeAsync = ref.watch(lastSyncTimeProvider(task.userId));

    return CheckboxListTile(
      title: Row(
        children: [
          Expanded(
            child: Text(
              task.title,
              style: task.isCompleted
                  ? const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey)
                  : null,
            ),
          ),
          // Sync status indicator based on last sync time vs task modification time
          lastSyncTimeAsync.when(
            data: (lastSyncTime) {
              final isPendingSync =
                  lastSyncTime == null || task.modifiedAt.isAfter(lastSyncTime);
              return Container(
                margin: const EdgeInsets.only(left: 8),
                child: Tooltip(
                  message: isPendingSync
                      ? 'Modified after last sync - pending remote update'
                      : 'Synced with remote',
                  child: Icon(
                    isPendingSync ? Icons.sync : Icons.check_circle,
                    size: 16,
                    color: isPendingSync ? Colors.orange : Colors.green,
                  ),
                ),
              );
            },
            loading: () => Container(
              margin: const EdgeInsets.only(left: 8),
              width: 16,
              height: 16,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (error, stack) => Container(
              margin: const EdgeInsets.only(left: 8),
              child: Tooltip(
                message: 'Sync status unknown',
                child: Icon(
                  Icons.help,
                  size: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        task.description ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      value: task.isCompleted,
      onChanged: (isCompleted) async {
        final updatedTask =
            task.copyWith(isCompleted: isCompleted, modifiedAt: DateTime.now());
        try {
          await ref
              .read(simpleDatumControllerProvider.notifier)
              .updateTask(updatedTask);
        } catch (e) {
          if (!context.mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating task: $e')),
          );
        }
      },
      secondary: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => onUpdate(task),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => onDelete(task),
          ),
        ],
      ),
    );
  }
}
