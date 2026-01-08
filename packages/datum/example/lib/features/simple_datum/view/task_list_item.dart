import 'package:example/data/task/entity/task.dart';
import 'package:example/features/simple_datum/controller/entity_sync_status_provider.dart';
import 'package:example/features/simple_datum/view/simple_datum_page.dart';
import 'package:example/shared/helper/global_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    // Get last sync time to compare with task modification time
    final lastSyncTimeAsync =
        ref.watch(lastSyncTimeProvider(widget.task.userId));

    return CheckboxListTile(
      title: Row(
        children: [
          Expanded(
            child: Text(
              widget.task.title,
              style: widget.task.isCompleted
                  ? const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey)
                  : null,
            ),
          ),
          // Sync status indicator based on last sync time vs task modification time
          lastSyncTimeAsync.when(
            data: (lastSyncTime) {
              final isPendingSync = lastSyncTime == null ||
                  widget.task.modifiedAt.isAfter(lastSyncTime);
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
        widget.task.description ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      value: widget.task.isCompleted,
      onChanged: (isCompleted) async {
        final updatedTask = widget.task
            .copyWith(isCompleted: isCompleted, modifiedAt: DateTime.now());
        try {
          await ref
              .read(simpleDatumControllerProvider.notifier)
              .updateTask(updatedTask);
        } catch (e) {
          if (!context.mounted) {
            return;
          }
          showErrorSnack(
            child: Text('Error updating task: $e'),
          );
        }
      },
      secondary: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => widget.onUpdate(widget.task),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => widget.onDelete(widget.task),
          ),
        ],
      ),
    );
  }
}
