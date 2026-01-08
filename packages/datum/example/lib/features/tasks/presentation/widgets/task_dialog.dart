import 'package:example/features/tasks/data/entities/task.dart';
import 'package:example/features/tasks/presentation/widgets/task_form.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Reusable task dialog
class TaskDialog extends StatelessWidget {
  const TaskDialog({super.key});

  static Future<void> show({
    required BuildContext context,
    Task? task,
    required String title,
    required String confirmText,
    required Function(String title, String description) onConfirm,
  }) async {
    final titleController = TextEditingController(text: task?.title ?? '');
    final descriptionController =
        TextEditingController(text: task?.description ?? '');

    final didConfirm = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: Text(title),
        actions: [
          ShadButton.ghost(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ShadButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                Navigator.of(context).pop(true);
              }
            },
            child: Text(confirmText),
          ),
        ],
        child: TaskForm(
          task: task,
          titleController: titleController,
          descriptionController: descriptionController,
        ),
      ),
    );

    if (didConfirm == true && titleController.text.isNotEmpty) {
      onConfirm(titleController.text, descriptionController.text);
    }

    titleController.dispose();
    descriptionController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('Use TaskDialog.show() instead');
  }
}
