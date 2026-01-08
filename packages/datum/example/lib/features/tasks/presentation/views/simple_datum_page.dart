import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:datum/datum.dart';
import 'package:example/bootstrap.dart';
import 'package:example/core/router/router.gr.dart';
import 'package:example/features/auth/data/adapters/supabase_adapter.dart';
import 'package:example/features/tasks/data/entities/task.dart';
import 'package:example/features/tasks/presentation/controllers/last_sync_result_notifier.dart';
import 'package:example/features/tasks/presentation/controllers/simple_datum_controller.dart';
import 'package:example/features/tasks/presentation/widgets/pull_button.dart';
import 'package:example/features/tasks/presentation/widgets/sync_button.dart';
import 'package:example/features/tasks/presentation/widgets/task_dialog.dart';
import 'package:example/features/tasks/presentation/widgets/task_list.dart';
import 'package:example/shared/helper/global_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

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
            setState(() {
              _waitingForInitialSync = true;
            });
            _updateSyncStatusListener(userId);

            // Resume sync first
            Datum.instance.resumeSync();

            // Clear sync metadata to force fresh data from server
            final remoteAdapter = Datum.manager<Task>().remoteAdapter;
            if (remoteAdapter is SupabaseRemoteAdapter<Task>) {
              await remoteAdapter.clearSyncMetadata(userId);
            }

            // Cold start sync
            final coldStartPerformed =
                await Datum.instance.handleColdStartIfNeeded<Task>(
              userId,
              (options) =>
                  Datum.manager<Task>().synchronize(userId, options: options),
            );

            if (!coldStartPerformed) {
              Datum.instance.synchronize(
                userId,
                options: const DatumSyncOptions(
                  direction: SyncDirection.pullThenPush,
                  forceFullSync: true,
                ),
              );
            }

            // Start auto-sync
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
          if (mounted) showErrorSnack(child: Text('Error creating task: $e'));
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
          if (mounted) showErrorSnack(child: Text('Error updating task: $e'));
        }
      },
    );
  }

  Future<void> _deleteTask(Task task) async {
    try {
      await ref.read(simpleDatumControllerProvider.notifier).deleteTask(task);
    } catch (e) {
      if (mounted) showErrorSnack(child: Text('Error deleting task: $e'));
    }
  }

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
      showSuccessSnack(
          child:
              Text('$operation complete. ${result.syncedCount} items synced.'));
    } else {
      showErrorSnack(
          child: Text('$operation failed. ${result.failedCount} failed.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text("User logged out")));
    }

    if (_waitingForInitialSync) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Syncing latest data...'),
            ],
          ),
        ),
      );
    }

    final tasksAsync = ref.watch(tasksStreamProvider(userId));

    final theme = ShadTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _createTask,
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            title: Text(
              'Tasks',
              style: theme.textTheme.h4,
            ),
            centerTitle: false,
            backgroundColor: theme.colorScheme.background,
            elevation: 0,
            floating: true,
            snap: true,
            actions: [
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
                onSyncStart: () =>
                    showInfoSnack(child: const Text('Syncing...')),
                onSyncComplete: (result) =>
                    _handleSyncResult(result, operation: 'Sync'),
                onSyncError: (e) =>
                    showErrorSnack(child: Text('Sync failed: $e')),
              ),
            ],
          ),
        ],
        body: RefreshIndicator(
          onRefresh: () {
            return ref.refresh(tasksStreamProvider(userId).future);
          },
          child: Column(
            children: [
              _buildSummaryCard(tasksAsync),
              Expanded(
                child: TaskList(
                  tasksAsync: tasksAsync,
                  onUpdate: _updateTask,
                  onDelete: _deleteTask,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(AsyncValue<List<Task>> tasksAsync) {
    return tasksAsync.maybeWhen(
      data: (tasks) {
        if (tasks.isEmpty) return const SizedBox.shrink();
        final completed = tasks.where((t) => t.isCompleted).length;
        final total = tasks.length;
        final pending = total - completed;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildStatCard(
                title: 'Pending',
                value: pending.toString(),
                color: Colors.blue.shade50,
                textColor: Colors.blue.shade900,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                title: 'Completed',
                value: completed.toString(),
                color: Colors.green.shade50,
                textColor: Colors.green.shade900,
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required Color textColor,
  }) {
    return Expanded(
      child: ShadCard(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
