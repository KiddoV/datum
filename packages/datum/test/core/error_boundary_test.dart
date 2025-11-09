import 'package:datum/source/core/engine/error_boundary.dart';
import 'package:datum/source/utils/datum_logger.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/test_entity.dart';

class MockLogger extends Mock implements DatumLogger {}

void main() {
  late MockLogger mockLogger;

  setUp(() {
    mockLogger = MockLogger();
    registerFallbackValue(StackTrace.empty);
  });

  group('ErrorBoundary', () {
    group('ErrorBoundaryStrategy', () {
      test('enum values are correct', () {
        expect(ErrorBoundaryStrategy.isolate.index, 0);
        expect(ErrorBoundaryStrategy.retry.index, 1);
        expect(ErrorBoundaryStrategy.fallback.index, 2);
        expect(ErrorBoundaryStrategy.escalate.index, 3);
      });
    });

    group('ErrorBoundaryConfig', () {
      test('default values are correct', () {
        const config = ErrorBoundaryConfig();
        expect(config.strategy, ErrorBoundaryStrategy.isolate);
        expect(config.retryDelay, const Duration(seconds: 1));
        expect(config.maxRetries, 3);
        expect(config.fallbackValue, isNull);
        expect(config.fallbackOperation, isNull);
      });

      test('custom values are preserved', () {
        const customConfig = ErrorBoundaryConfig(
          strategy: ErrorBoundaryStrategy.retry,
          retryDelay: Duration(seconds: 5),
          maxRetries: 10,
          fallbackValue: 'fallback',
          fallbackOperation: null,
        );
        expect(customConfig.strategy, ErrorBoundaryStrategy.retry);
        expect(customConfig.retryDelay, const Duration(seconds: 5));
        expect(customConfig.maxRetries, 10);
        expect(customConfig.fallbackValue, 'fallback');
        expect(customConfig.fallbackOperation, isNull);
      });
    });

    group('ErrorBoundary', () {
      test('uses default config when none provided', () {
        final boundary = ErrorBoundary<String>();
        expect(boundary.config.strategy, ErrorBoundaryStrategy.isolate);
      });

      test('uses provided config', () {
        const config = ErrorBoundaryConfig(strategy: ErrorBoundaryStrategy.retry);
        final boundary = ErrorBoundary<String>(config: config);
        expect(boundary.config.strategy, ErrorBoundaryStrategy.retry);
      });

      test('uses provided logger', () {
        // We can't directly test the logger field since it's private,
        // but we can verify it doesn't throw when provided
        final boundary = ErrorBoundary<String>(logger: mockLogger);
        expect(boundary, isNotNull);
      });

      group('execute', () {
        test('returns result when operation succeeds', () async {
          final boundary = ErrorBoundary<String>();
          final result = await boundary.execute(() async => 'success');
          expect(result, 'success');
        });

        test('isolate strategy logs error and returns fallback', () async {
          const config = ErrorBoundaryConfig(
            strategy: ErrorBoundaryStrategy.isolate,
            fallbackValue: 'fallback',
          );
          final boundary = ErrorBoundary<String>(config: config, logger: mockLogger);

          final result = await boundary.execute(() async => throw Exception('test error'));

          expect(result, 'fallback');
          verify(() => mockLogger.error('Error isolated in boundary: Exception: test error', any())).called(1);
        });

        test('isolate strategy throws when no fallback provided', () async {
          const config = ErrorBoundaryConfig(strategy: ErrorBoundaryStrategy.isolate);
          final boundary = ErrorBoundary<String>(config: config, logger: mockLogger);

          await expectLater(
            boundary.execute(() async => throw Exception('test error')),
            throwsA(isA<StateError>()),
          );
          verify(() => mockLogger.error('Error isolated in boundary: Exception: test error', any())).called(1);
        });

        test('retry strategy retries on failure and succeeds', () async {
          const config = ErrorBoundaryConfig(
            strategy: ErrorBoundaryStrategy.retry,
            maxRetries: 2,
            retryDelay: Duration(milliseconds: 10),
          );
          final boundary = ErrorBoundary<String>(config: config, logger: mockLogger);

          var attempts = 0;
          final result = await boundary.execute(() async {
            attempts++;
            if (attempts == 1) throw Exception('first attempt fails');
            return 'success on retry';
          });

          expect(result, 'success on retry');
          expect(attempts, 2);
          verify(() => mockLogger.warn('Retrying operation after error: Exception: first attempt fails (attempt 1/2)')).called(1);
        });

        test('retry strategy exhausts retries and uses fallback', () async {
          const config = ErrorBoundaryConfig(
            strategy: ErrorBoundaryStrategy.retry,
            maxRetries: 2,
            retryDelay: Duration(milliseconds: 10),
            fallbackValue: 'fallback',
          );
          final boundary = ErrorBoundary<String>(config: config, logger: mockLogger);

          final result = await boundary.execute(() async => throw Exception('persistent error'));

          expect(result, 'fallback');
          verify(() => mockLogger.warn('Retrying operation after error: Exception: persistent error (attempt 1/2)')).called(1);
          verify(() => mockLogger.warn('Retrying operation after error: Exception: persistent error (attempt 2/2)')).called(1);
          verify(() => mockLogger.error('Max retries exceeded for error: Exception: persistent error', any())).called(1);
        });

        test('fallback strategy uses fallback value', () async {
          const config = ErrorBoundaryConfig(
            strategy: ErrorBoundaryStrategy.fallback,
            fallbackValue: 'fallback',
          );
          final boundary = ErrorBoundary<String>(config: config, logger: mockLogger);

          final result = await boundary.execute(() async => throw Exception('error'));

          expect(result, 'fallback');
          verify(() => mockLogger.warn('Using fallback for error: Exception: error')).called(1);
        });

        test('fallback strategy uses fallback operation', () async {
          final config = ErrorBoundaryConfig(
            strategy: ErrorBoundaryStrategy.fallback,
            fallbackOperation: () async => 'async fallback',
          );
          final boundary = ErrorBoundary<String>(config: config, logger: mockLogger);

          final result = await boundary.execute(() async => throw Exception('error'));

          expect(result, 'async fallback');
          verify(() => mockLogger.warn('Using fallback for error: Exception: error')).called(1);
        });

        test('escalate strategy rethrows error', () async {
          const config = ErrorBoundaryConfig(strategy: ErrorBoundaryStrategy.escalate);
          final boundary = ErrorBoundary<String>(config: config, logger: mockLogger);

          await expectLater(
            boundary.execute(() async => throw Exception('escalated error')),
            throwsA(isA<Exception>()),
          );
          verify(() => mockLogger.debug('Escalating error: Exception: escalated error')).called(1);
        });
      });

      group('executeVoid', () {
        test('completes successfully when operation succeeds', () async {
          final boundary = ErrorBoundary<void>(logger: mockLogger);
          await expectLater(
            boundary.executeVoid(() async {}),
            completes,
          );
        });

        test('isolate strategy logs error for void operations', () async {
          const config = ErrorBoundaryConfig(strategy: ErrorBoundaryStrategy.isolate);
          final boundary = ErrorBoundary<void>(config: config, logger: mockLogger);

          await expectLater(
            boundary.executeVoid(() async => throw Exception('void error')),
            completes,
          );
          verify(() => mockLogger.error('Error isolated in boundary: Exception: void error', any())).called(1);
        });

        test('retry strategy retries void operations', () async {
          const config = ErrorBoundaryConfig(
            strategy: ErrorBoundaryStrategy.retry,
            maxRetries: 1,
            retryDelay: Duration(milliseconds: 10),
          );
          final boundary = ErrorBoundary<void>(config: config, logger: mockLogger);

          var attempts = 0;
          await boundary.executeVoid(() async {
            attempts++;
            if (attempts == 1) throw Exception('first attempt fails');
          });

          expect(attempts, 2);
          verify(() => mockLogger.warn('Retrying operation after error: Exception: first attempt fails (attempt 1/1)')).called(1);
        });

        test('escalate strategy rethrows error for void operations', () async {
          const config = ErrorBoundaryConfig(strategy: ErrorBoundaryStrategy.escalate);
          final boundary = ErrorBoundary<void>(config: config, logger: mockLogger);

          await expectLater(
            boundary.executeVoid(() async => throw Exception('void escalated error')),
            throwsA(isA<Exception>()),
          );
          verify(() => mockLogger.debug('Escalating error: Exception: void escalated error')).called(1);
        });
      });
    });

    group('ErrorBoundaries utility class', () {
      test('syncIsolation creates correct boundary', () {
        final boundary = ErrorBoundaries.syncIsolation<TestEntity>();
        expect(boundary.config.strategy, ErrorBoundaryStrategy.isolate);
        expect(boundary.config.fallbackValue, isNull);
      });

      test('adapterRetry creates correct boundary', () {
        final boundary = ErrorBoundaries.adapterRetry<String>(
          maxRetries: 5,
          retryDelay: const Duration(seconds: 2),
        );
        expect(boundary.config.strategy, ErrorBoundaryStrategy.retry);
        expect(boundary.config.maxRetries, 5);
        expect(boundary.config.retryDelay, const Duration(seconds: 2));
      });

      test('readWithFallback creates correct boundary', () {
        final boundary = ErrorBoundaries.readWithFallback<String>(
          fallbackValue: 'default',
          fallbackOperation: () async => 'async default',
        );
        expect(boundary.config.strategy, ErrorBoundaryStrategy.fallback);
        expect(boundary.config.fallbackValue, 'default');
        expect(boundary.config.fallbackOperation, isNotNull);
      });

      test('observerIsolation creates correct boundary', () {
        final boundary = ErrorBoundaries.observerIsolation();
        expect(boundary.config.strategy, ErrorBoundaryStrategy.isolate);
      });
    });
  });
}
