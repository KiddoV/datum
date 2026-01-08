import 'package:example/features/tasks/presentation/controllers/simple_datum_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SimpleDatumController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is valid', () {
      final controller = container.read(simpleDatumControllerProvider.notifier);
      expect(controller, isA<SimpleDatumController>());
    });

    test('syncResultEventProvider starts null', () {
      final state = container.read(syncResultEventProvider);
      expect(state, isNull);
    });
  });
}
