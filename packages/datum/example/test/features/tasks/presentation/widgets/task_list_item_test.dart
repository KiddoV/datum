import 'package:example/features/tasks/data/entities/task.dart';
import 'package:example/features/tasks/presentation/controllers/entity_sync_status_provider.dart';
import 'package:example/features/tasks/presentation/controllers/simple_datum_controller.dart';
import 'package:example/features/tasks/presentation/widgets/task_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

// Mock SimpleDatumController
class MockSimpleDatumController extends Mock implements SimpleDatumController {
  @override
  void build() {}

  @override
  Future<void> createTask({required String title, String? description}) async {}

  @override
  Future<void> updateTask(Task task) async {}

  @override
  Future<void> deleteTask(Task task) async {}
}

void main() {
  late MockSimpleDatumController mockController;

  setUp(() {
    mockController = MockSimpleDatumController();
  });

  Widget createSubject({
    required Task task,
    required Function(Task) onUpdate,
    required Function(Task) onDelete,
    DateTime? lastSyncTime,
  }) {
    return ProviderScope(
      overrides: [
        simpleDatumControllerProvider.overrideWith(() => mockController),
        lastSyncTimeProvider(task.userId)
            .overrideWith((ref) => Stream.value(lastSyncTime)),
      ],
      child: ShadApp(
        home: Scaffold(
          body: TaskListItem(
            task: task,
            onUpdate: onUpdate,
            onDelete: onDelete,
          ),
        ),
      ),
    );
  }

  testWidgets('TaskListItem displays correctly with active task',
      (tester) async {
    final task = Task(
      id: '1',
      title: 'Active Task',
      description: 'Description',
      isCompleted: false,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      userId: 'user1',
    );

    await tester.pumpWidget(createSubject(
      task: task,
      onUpdate: (_) {},
      onDelete: (_) {},
      lastSyncTime: DateTime.now().add(const Duration(minutes: 1)),
    ));

    expect(find.text('Active Task'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);

    // Checkbox should be unchecked
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, false);

    // Actions are present
    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);
  });

  testWidgets('TaskListItem displays correctly with completed task',
      (tester) async {
    final task = Task(
      id: '2',
      title: 'Completed Task',
      isCompleted: true,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      userId: 'user1',
    );

    await tester.pumpWidget(createSubject(
      task: task,
      onUpdate: (_) {},
      onDelete: (_) {},
    ));

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, true);

    // Title should be struck through (decoration logic in widget)
    final textWidget = tester.widget<Text>(find.text('Completed Task'));
    expect(textWidget.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('Clicking edit invokes onUpdate', (tester) async {
    final task = Task(
      id: '1',
      title: 'Task',
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      userId: 'user1',
    );
    bool updated = false;

    await tester.pumpWidget(createSubject(
      task: task,
      onUpdate: (t) {
        updated = true;
        expect(t.id, '1');
      },
      onDelete: (_) {},
    ));

    await tester.tap(find.byIcon(Icons.edit));
    expect(updated, true);
  });

  testWidgets('Clicking delete invokes onDelete', (tester) async {
    final task = Task(
      id: '1',
      title: 'Task',
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      userId: 'user1',
    );
    bool deleted = false;

    await tester.pumpWidget(createSubject(
      task: task,
      onUpdate: (_) {},
      onDelete: (t) {
        deleted = true;
        expect(t.id, '1');
      },
    ));

    await tester.tap(find.byIcon(Icons.delete));
    expect(deleted, true);
  });

  testWidgets('Shows pending sync icon when not synced', (tester) async {
    final task = Task(
      id: '1',
      title: 'Pending Task',
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      userId: 'user1',
    );

    // Sync time is before modified time -> pending
    final lastSyncTime = task.modifiedAt.subtract(const Duration(minutes: 5));

    await tester.pumpWidget(createSubject(
      task: task,
      onUpdate: (_) {},
      onDelete: (_) {},
      lastSyncTime: lastSyncTime,
    ));
    await tester.pump(); // Allow stream to emit

    expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
  });

  testWidgets('Hides pending sync icon when synced', (tester) async {
    final task = Task(
      id: '1',
      title: 'Synced Task',
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      userId: 'user1',
    );

    // Sync time is after modified time -> synced
    final lastSyncTime = task.modifiedAt.add(const Duration(minutes: 5));

    await tester.pumpWidget(createSubject(
      task: task,
      onUpdate: (_) {},
      onDelete: (_) {},
      lastSyncTime: lastSyncTime,
    ));

    expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing);
  });
}
