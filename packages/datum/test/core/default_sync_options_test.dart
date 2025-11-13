import 'package:datum/source/config/datum_config.dart';
import 'package:datum/source/core/models/datum_sync_options.dart';
import '../test_utils/test_datum_entity.dart';
import 'package:test/test.dart';

void main() {
  group('DatumConfig defaultSyncOptions', () {
    test('should use default sync options when none provided', () {
      const defaultOptions = DatumSyncOptions<TestDatumEntity>(
        includeDeletes: false,
        resolveConflicts: false,
        forceFullSync: true,
        timeout: Duration(seconds: 30),
      );

      const config = DatumConfig<TestDatumEntity>(
        defaultSyncOptions: defaultOptions,
      );

      expect(config.defaultSyncOptions, equals(defaultOptions));
    });

    test('should allow null default sync options', () {
      const config = DatumConfig<TestDatumEntity>();

      expect(config.defaultSyncOptions, isNull);
    });

    test('copyWith should preserve defaultSyncOptions', () {
      const defaultOptions = DatumSyncOptions<TestDatumEntity>(
        includeDeletes: false,
      );

      const config = DatumConfig<TestDatumEntity>(
        defaultSyncOptions: defaultOptions,
      );

      final copied = config.copyWith();

      expect(copied.defaultSyncOptions, equals(defaultOptions));
    });

    test('copyWith should allow changing defaultSyncOptions', () {
      const originalOptions = DatumSyncOptions<TestDatumEntity>(
        includeDeletes: false,
      );

      const newOptions = DatumSyncOptions<TestDatumEntity>(
        includeDeletes: true,
      );

      const config = DatumConfig<TestDatumEntity>(
        defaultSyncOptions: originalOptions,
      );

      final copied = config.copyWith<TestDatumEntity>(defaultSyncOptions: newOptions);

      expect(copied.defaultSyncOptions, equals(newOptions));
    });
  });
}
