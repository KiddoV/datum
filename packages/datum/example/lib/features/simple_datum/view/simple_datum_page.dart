import 'dart:async';

import 'package:datum/datum.dart';
import 'package:example/bootstrap.dart';
import 'package:example/data/task/entity/task.dart';
import 'package:example/data/user/adapters/supabase_adapter.dart';
import 'package:example/features/simple_datum/controller/last_sync_result_notifier.dart';
import 'package:example/features/simple_datum/controller/simple_datum_provider.dart';
import 'package:example/features/simple_datum/view/task.dart';
import 'package:example/features/simple_datum/view/task_list.dart';
import 'package:example/shared/helper/global_helper.dart';
import 'package:example/shared/riverpod_ext/asynvalue_easy_when.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:example/core/router/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

// ============================================================================
// PROVIDERS
// ============================================================================

final simpleDatumControllerProvider =
    NotifierProvider.autoDispose<SimpleDatumController, void>(
  SimpleDatumController.new,
  name: 'simpleDatumControllerProvider',
);

final syncResultEventProvider =
    StateProvider<DatumSyncResult<DatumEntityInterface>?>(
  (ref) => null,
  name: "syncResultEventProvider",
);

final tasksStreamProvider =
    StreamProvider.autoDispose.family<List<Task>, String>(
  (ref, userId) async* {
    yield* Datum.manager<Task>()
            .watchAll(userId: userId, includeInitialData: true) ??
        const Stream.empty();
  },
  name: 'tasksStreamProvider',
);

final syncStatusProvider =
    StreamProvider.autoDispose.family<DatumSyncStatusSnapshot?, String>(
  (ref, userId) async* {
    final datum = ref.watch(simpleDatumProvider);
    yield* datum.statusForUser(userId);
  },
  name: 'syncStatusProvider',
);

// ============================================================================
// CONTROLLER
// ============================================================================

class SimpleDatumController extends AutoDisposeNotifier<void> {
  SimpleDatumController();

  void _notifySyncResult(DatumSyncResult<DatumEntityInterface> result) {
    ref.read(syncResultEventProvider.notifier).state = result;
  }

  Future<void> createTask({
    required String title,
    String? description,
  }) async {
    final newTask = Task.create(title: title, description: description);
    final (_, syncResult) =
        await Datum.instance.pushAndSync(item: newTask, userId: newTask.userId);
    _notifySyncResult(syncResult);
  }

  Future<void> updateTask(Task task) async {
    final (_, syncResult) =
        await Datum.instance.updateAndSync(item: task, userId: task.userId);
    _notifySyncResult(syncResult);
  }

  Future<void> deleteTask(Task task) async {
    final (_, syncResult) = await Datum.instance
        .deleteAndSync<Task>(id: task.id, userId: task.userId);
    _notifySyncResult(syncResult);
  }

  @override
  void build() {
    return;
  }
}

// ============================================================================
// REUSABLE WIDGETS
// ============================================================================

/// Reusable sync button widget
class SyncButton extends ConsumerWidget {
  final String userId;
  final VoidCallback onSyncStart;
  final Function(DatumSyncResult<DatumEntityInterface>) onSyncComplete;
  final Function(dynamic) onSyncError;

  const SyncButton({
    super.key,
    required this.userId,
    required this.onSyncStart,
    required this.onSyncComplete,
    required this.onSyncError,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(syncStatusProvider(userId)).easyWhen(
          data: (status) {
            if (status?.status == DatumSyncStatus.syncing) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: Tooltip(
                    message:
                        'Syncing... ${(status!.progress * 100).toStringAsFixed(0)}%',
                    child: CircularProgressIndicator(
                      value: status.progress > 0 ? status.progress : null,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              );
            }
            return Tooltip(
              message: 'Push and pull changes with remote',
              child: IconButton(
                icon: const Icon(Icons.sync),
                onPressed: () => _handleSync(ref),
              ),
            );
          },
          loadingWidget: () => const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
  }

  Future<void> _handleSync(WidgetRef ref) async {
    ref.invalidate(syncStatusProvider(userId));
    onSyncStart();
    try {
      final result = await Datum.instance.synchronize(userId);
      onSyncComplete(result);
    } catch (e) {
      onSyncError(e);
    }
  }
}

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

/// Reusable task dialog
class TaskDialog extends StatelessWidget {
  final Task? task;
  final String title;
  final String confirmText;
  final Function(String title, String description) onConfirm;

  const TaskDialog({
    super.key,
    this.task,
    required this.title,
    required this.confirmText,
    required this.onConfirm,
  });

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

// ============================================================================
// MAIN PAGE
// ============================================================================

@RoutePage()
class SimpleDatumPage extends ConsumerStatefulWidget {
  const SimpleDatumPage({super.key});

  @override
  ConsumerState<SimpleDatumPage> createState() => _SimpleDatumPageState();
}

class _SimpleDatumPageState extends ConsumerState<SimpleDatumPage>
    with GlobalHelper {
  late final AppLifecycleListener _appLifecycleListener;
  late ProviderSubscription _syncResultSubscription;
  late ProviderSubscription _syncStatusSubscription;
  late StreamSubscription<AuthState> _authSubscription;
  bool _waitingForInitialSync = false;

  @override
  void initState() {
    super.initState();
    _initializeLifecycleListener();
    _initializeSyncResultListener();

    _initializeAuthListener();
  }

  void _initializeLifecycleListener() {
    _appLifecycleListener = AppLifecycleListener(
      onStateChange: (value) async {
        talker.debug("State $value");
      },
    );
  }

  void _initializeSyncResultListener() {
    _syncResultSubscription = ref.listenManual(
      syncResultEventProvider,
      (previous, next) {
        if (next != null) {
          _handleSyncResult(next);
        }
      },
    );
    // Initialize sync status subscription as a dummy listener
    _syncStatusSubscription = ref.listenManual(
      syncResultEventProvider, // Dummy provider, will be replaced
      (previous, next) {},
    );
  }

  void _updateSyncStatusListener(String userId) {
    _syncStatusSubscription.close();
    _syncStatusSubscription = ref.listenManual(
      syncStatusProvider(userId),
      (previous, next) {
        if (_waitingForInitialSync &&
            next != null &&
            next.hasValue &&
            next.value != null &&
            (next.value!.status == DatumSyncStatus.completed ||
                next.value!.status == DatumSyncStatus.idle ||
                next.value!.status == DatumSyncStatus.failed)) {
          setState(() {
            _waitingForInitialSync = false;
          });
        }
      },
    );
  }

  void _initializeAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (authState) async {
        if (!Datum.isInitialized) return;

        if (authState.event == AuthChangeEvent.signedOut) {
          Datum.instance.pauseSync();
          // Automatically navigate to login screen when user logs out
          if (mounted) {
            context.router.replaceAll([const LoginRoute()]);
          }
        } else if (authState.event == AuthChangeEvent.signedIn) {
          final userId = authState.session?.user.id;
          if (userId != null) {
            // User logged in (including relogin after logout), wait for initial sync to complete
            setState(() {
              _waitingForInitialSync = true;
            });
            _updateSyncStatusListener(userId);

            // Resume sync first (in case it was paused during logout)
            Datum.instance.resumeSync();

            // Clear sync metadata to force fresh data from server
            final remoteAdapter = Datum.manager<Task>().remoteAdapter;
            if (remoteAdapter is SupabaseRemoteAdapter<Task>) {
              await remoteAdapter.clearSyncMetadata(userId);
            }

            // Handle cold start sync for the newly authenticated user
            final coldStartPerformed = await Datum.instance.handleColdStartIfNeeded<Task>(
              userId,
              (options) => Datum.manager<Task>().synchronize(userId, options: options),
            );

            if (!coldStartPerformed) {
              // If cold start wasn't performed, do regular initial sync
              Datum.instance.synchronize(
                userId,
                options: const DatumSyncOptions(
                  direction: SyncDirection.pullThenPush,
                  forceFullSync: true, // Ensure we get all remote data
                ),
              );
            }

            // Start auto-sync for the authenticated user
            Datum.instance.startAutoSync(userId);
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _syncResultSubscription.close();
    _syncStatusSubscription.close();
    _authSubscription.cancel();
    _appLifecycleListener.dispose();
    super.dispose();
  }

  // ============================================================================
  // TASK OPERATIONS
  // ============================================================================

  Future<void> _createTask() async {
    if (!mounted) return;

    await TaskDialog.show(
      context: context,
      title: 'Create Task',
      confirmText: 'Create',
      onConfirm: (title, description) async {
        try {
          await ref
              .read(simpleDatumControllerProvider.notifier)
              .createTask(title: title, description: description);
        } catch (e) {
          if (mounted) {
            showErrorSnack(child: Text('Error creating task: $e'));
          }
        }
      },
    );
  }

  Future<void> _updateTask(Task task) async {
    if (!mounted) return;

    await TaskDialog.show(
      context: context,
      task: task,
      title: 'Update Task',
      confirmText: 'Update',
      onConfirm: (title, description) async {
        final updatedTask = task.copyWith(
          title: title,
          description: description,
          modifiedAt: DateTime.now(),
        );
        try {
          await ref
              .read(simpleDatumControllerProvider.notifier)
              .updateTask(updatedTask);
        } catch (e) {
          if (mounted) {
            showErrorSnack(child: Text('Error updating task: $e'));
          }
        }
      },
    );
  }

  Future<void> _deleteTask(Task task) async {
    try {
      await ref.read(simpleDatumControllerProvider.notifier).deleteTask(task);
    } catch (e) {
      if (mounted) {
        showErrorSnack(child: Text('Error deleting task: $e'));
      }
    }
  }

  // ============================================================================
  // SYNC HANDLERS
  // ============================================================================

  void _handleSyncResult(
    DatumSyncResult<DatumEntityInterface> result, {
    String operation = 'Sync',
  }) {
    ref.read(lastSyncResultProvider.notifier).update(result);

    if (!mounted) return;

    if (result.wasSkipped) {
      showInfoSnack(child: Text('$operation skipped.'));
      return;
    }

    if (result.isSuccess) {
      final message = _buildSuccessMessage(result, operation);
      showSuccessSnack(child: Text(message));
    } else {
      showErrorSnack(
        child: Text(
          '$operation failed. ${result.failedCount} item(s) failed to sync.',
        ),
      );
    }
  }

  String _buildSuccessMessage(
    DatumSyncResult<DatumEntityInterface> result,
    String operation,
  ) {
    final itemsSynced = result.syncedCount > 0
        ? '${result.syncedCount} item(s) pushed. '
        : 'No local changes to push. ';

    final bytesPushed = result.bytesPushedInCycle > 0
        ? '↑${(result.bytesPushedInCycle / 1024).toStringAsFixed(2)}KB'
        : '';

    final bytesPulled = result.bytesPulledInCycle > 0
        ? '↓${(result.bytesPulledInCycle / 1024).toStringAsFixed(2)}KB'
        : '';

    final dataTransferMessage =
        [bytesPushed, bytesPulled].where((s) => s.isNotEmpty).join(' ');

    final message = [
      '$operation complete. $itemsSynced',
      if (dataTransferMessage.isNotEmpty) dataTransferMessage,
    ].join(' ').replaceAll(' .', '.');

    return message.trim();
  }

  // ============================================================================
  // UI BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: _buildAppBar(userId),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTask,
        child: const Icon(Icons.add),
      ),
      body: userId != null
          ? _buildAuthenticatedBody(userId)
          : const _LoggedOutView(),
    );
  }

  PreferredSizeWidget _buildAppBar(String? userId) {
    return AppBar(
      title: const Text('Simple Datum'),
      actions: [
        if (userId != null) ...[
          PullButton(
            userId: userId,
            onPullStart: () =>
                showInfoSnack(child: const Text('Refreshing...')),
            onPullComplete: (result) =>
                _handleSyncResult(result, operation: 'Refresh'),
            onPullError: (e) =>
                showErrorSnack(child: Text('Refresh failed: $e')),
          ),
          SyncButton(
            userId: userId,
            onSyncStart: () => showInfoSnack(child: const Text('Syncing...')),
            onSyncComplete: (result) =>
                _handleSyncResult(result, operation: 'Sync'),
            onSyncError: (e) => showErrorSnack(child: Text('Sync failed: $e')),
          ),
        ],
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _handleLogout,
        ),
      ],
    );
  }

  Widget _buildAuthenticatedBody(String userId) {
    if (_waitingForInitialSync) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Syncing latest data...'),
          ],
        ),
      );
    }

    final tasksAsync = ref.watch(tasksStreamProvider(userId));

    return RefreshIndicator(
      onRefresh: () {
        talker.debug(userId);
        return ref.refresh(tasksStreamProvider(userId).future);
      },
      child: TaskList(
        tasksAsync: tasksAsync,
        onUpdate: _updateTask,
        onDelete: _deleteTask,
      ),
    );
  }

  Future<void> _handleLogout() async {
    await Supabase.instance.client.auth.signOut(
      scope: SignOutScope.global,
    );
  }
}

// ============================================================================
// LOGGED OUT VIEW
// ============================================================================

class _LoggedOutView extends StatelessWidget {
  const _LoggedOutView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("User logged out"),
    );
  }
}
