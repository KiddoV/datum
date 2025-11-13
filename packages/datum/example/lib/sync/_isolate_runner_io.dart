import 'dart:async';
import 'dart:isolate';

import 'package:datum/source/core/models/datum_entity.dart';
import 'package:datum/source/core/models/datum_sync_operation.dart';
import 'package:datum/source/core/sync/datum_sync_execution_strategy.dart';
import 'package:datum/source/utils/datum_logger.dart';
import 'package:example/isolate_logger.dart';

/// Spawns an isolate to run the sync process. This is for non-web platforms.
Future<void> spawnIsolate<T extends DatumEntityInterface>(
  List<DatumSyncOperation<T>> operations,
  Future<void> Function(DatumSyncOperation<T> operation) processOperation,
  bool Function() isCancelled,
  void Function(int completed, int total) onProgress,
  DatumSyncExecutionStrategy wrappedStrategy,
  DatumLogger logger,
) {
  final completer = Completer<void>();
  final mainReceivePort = ReceivePort();

  final isolateInitMessage = _IsolateInitMessage<T>(
    mainToIsolateSendPort: mainReceivePort.sendPort,
    operations: operations,
    wrappedStrategy: wrappedStrategy,
    logger: logger,
  );

  unawaited(
    Isolate.spawn(_isolateEntryPoint, isolateInitMessage).then((isolate) async {
      try {
        final mainPortSubscription = mainReceivePort.listen((message) {
          if (isCancelled() && !completer.isCompleted) {
            isolate.kill(priority: Isolate.immediate);
            completer.complete();
            return;
          }

          if (message is _ProcessOperationRequest) {
            final operation = operations.firstWhere(
              (op) => op.id == message.id,
            );
            processOperation(operation)
                .then((_) => message.responsePort.send(null))
                .catchError((Object e, StackTrace s) {
              message.responsePort.send(_IsolateError(e, s));
            });
          } else if (message is _ProgressUpdate) {
            onProgress(message.completed, message.total);
          } else if (message is _SyncComplete) {
            if (!completer.isCompleted) completer.complete();
          } else if (message is _SyncError) {
            if (!completer.isCompleted) {
              completer.completeError(message.error, message.stackTrace);
            }
          }
        });

        await completer.future.whenComplete(() {
          isolate.kill(priority: Isolate.immediate);
          mainPortSubscription.cancel();
        });
      } finally {
        mainReceivePort.close();
      }
    }).catchError((Object e, StackTrace s) {
      if (!completer.isCompleted) completer.completeError(e, s);
      mainReceivePort.close();
    }),
  );

  return completer.future;
}

// --- Isolate Communication Models ---

class _IsolateInitMessage<T extends DatumEntityInterface> {
  _IsolateInitMessage({
    required this.mainToIsolateSendPort,
    required this.operations,
    required this.wrappedStrategy,
    required this.logger,
  });

  final SendPort mainToIsolateSendPort;
  final List<DatumSyncOperation<T>> operations;
  final DatumSyncExecutionStrategy wrappedStrategy;
  final DatumLogger logger;
}

class _ProcessOperationRequest {
  _ProcessOperationRequest(this.id, this.responsePort);
  final String id;
  final SendPort responsePort;
}

class _IsolateError {
  _IsolateError(this.error, this.stackTrace);
  final Object error;
  final StackTrace stackTrace;
}

class _ProgressUpdate {
  _ProgressUpdate(this.completed, this.total);
  final int completed;
  final int total;
}

class _SyncComplete {}

class _SyncError {
  _SyncError(this.error, this.stackTrace);
  final Object error;
  final StackTrace stackTrace;
}

/// The entry point for the background isolate.
void _isolateEntryPoint<T extends DatumEntityInterface>(
    _IsolateInitMessage<T> initMessage) {
  final mainSendPort = initMessage.mainToIsolateSendPort;
  final operations = initMessage.operations;

  // Create a worker logger for this isolate
  final workerLogger = initMessage.logger is IsolateLogger
      ? (initMessage.logger as IsolateLogger).createWorkerLogger()
      : IsolateLogger(initMessage.logger).createWorkerLogger();

  // Only log at info level for isolate start to reduce overhead
  workerLogger.info(
      'Starting isolate sync execution with ${operations.length} operations');

  Future<void> requestProcessing(
      DatumSyncOperation<DatumEntityInterface> operation) async {
    // Remove per-operation debug logging to reduce cross-isolate communication overhead
    final responsePort = ReceivePort();
    mainSendPort.send(
      _ProcessOperationRequest(operation.id, responsePort.sendPort),
    );
    final result = await responsePort.first;
    responsePort.close();

    if (result is _IsolateError) {
      // Only log errors, not every operation
      workerLogger
          .warn('Operation ${operation.id} failed in isolate: ${result.error}');
      return Future.error(result.error, result.stackTrace);
    }
    // Remove success logging for each operation
  }

  void reportProgress(int completed, int total) {
    // Reduce progress logging frequency - only log every 10 operations or at completion
    if (completed % 10 == 0 || completed == total) {
      workerLogger
          .debug('Isolate progress: $completed/$total operations completed');
    }
    mainSendPort.send(_ProgressUpdate(completed, total));
  }

  bool isCancelled() => false;

  initMessage.wrappedStrategy
      .execute<DatumEntityInterface>(
    operations.cast<DatumSyncOperation<DatumEntityInterface>>(),
    requestProcessing,
    isCancelled,
    reportProgress,
  )
      .then((_) {
    workerLogger.info('Isolate sync execution completed successfully');
    mainSendPort.send(_SyncComplete());
  }).catchError(
    (Object e, StackTrace s) {
      workerLogger.error('Isolate sync execution failed: $e');
      mainSendPort.send(_SyncError(e, s));
    },
  );
}
