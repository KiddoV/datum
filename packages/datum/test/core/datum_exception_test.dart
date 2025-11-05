import 'package:datum/source/core/errors/datum_exception.dart';

import 'package:test/test.dart';

void main() {
  group('Datum Exceptions toString()', () {
    test('NetworkException formats correctly', () {
      const retryableException = NetworkException(message: 'Connection timed out');
      const nonRetryableException = NetworkException(
        message: 'Bad request',
        isRetryable: false,
      );

      expect(
        retryableException.toString(),
        'DatumException(networkError): Connection timed out',
      );
      expect(
        nonRetryableException.toString(),
        'DatumException(networkError): Bad request',
      );
    });

    test('MigrationException formats correctly', () {
      final exception = MigrationException(
        message: 'Schema version mismatch',
      );
      expect(
        exception.toString(),
        'DatumException(migrationError): Schema version mismatch',
      );
    });

    test('UserSwitchException formats correctly', () {
      const exception = UserSwitchException(
        oldUserId: 'user-old',
        newUserId: 'user-new',
        message: 'Unsynced data exists.',
      );
      expect(
        exception.toString(),
        'UserSwitchException(oldUserId: user-old, newUserId: user-new,message: Unsynced data exists.,code: DatumExceptionCode.userSwitchError)',
      );
    });

    test('AdapterException formats correctly without stack trace', () {
      const exception = AdapterException(
        message: 'MockAdapter',
        error: 'Failed to read from disk',
      );
      expect(
        exception,
        isA<AdapterException>()
            .having(
              (e) => e.message,
              "message",
              'MockAdapter',
            )
            .having(
              (e) => e.error,
              "error",
              'Failed to read from disk',
            ),
      );
    });

    test('AdapterException formats correctly with stack trace', () {
      final stackTrace = StackTrace.current;
      final exception = AdapterException(
        message: 'MockAdapter',
        error: 'Failed to write',
        stackTrace: stackTrace,
      );
      expect(
        exception,
        isA<AdapterException>()
            .having(
              (e) => e.message,
              "message",
              "MockAdapter",
            )
            .having(
              (e) => e.error,
              "error",
              'Failed to write',
            )
            .having(
              (e) => e.stackTrace,
              "stacktrace",
              stackTrace,
            ),
      );
    });

    test(
      'EntityNotFoundException formats correctly',
      () {
        const exception = EntityNotFoundException(message: 'Entity with ID 123 not found');
        expect(
          exception,
          isA<EntityNotFoundException>().having(
            (e) => e.message,
            "message",
            'Entity with ID 123 not found',
          ),
        );
      },
    );
  });
}
