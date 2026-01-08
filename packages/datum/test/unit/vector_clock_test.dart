import 'package:datum/datum.dart';
import 'package:test/test.dart';

void main() {
  group('VectorClock', () {
    test('creates an empty vector clock', () {
      const vc = VectorClock();
      expect(vc.toMap(), isEmpty);
    });

    test('creates a vector clock from a map', () {
      final map = {'node1': 1, 'node2': 5};
      final vc = VectorClock.fromMap(map);
      expect(vc.getValue('node1'), 1);
      expect(vc.getValue('node2'), 5);
      expect(vc.getValue('node3'), 0);
    });

    test('increments a node', () {
      const vc = VectorClock({'node1': 1});
      final incremented = vc.increment('node1');
      expect(incremented.getValue('node1'), 2);
      expect(vc.getValue('node1'), 1); // Immutable
    });

    test('increments a non-existent node', () {
      const vc = VectorClock();
      final incremented = vc.increment('node1');
      expect(incremented.getValue('node1'), 1);
    });

    test('merges two vector clocks', () {
      const vc1 = VectorClock({'node1': 2, 'node2': 1});
      const vc2 = VectorClock({'node1': 1, 'node2': 3, 'node3': 5});
      final merged = vc1.merge(vc2);

      expect(merged.getValue('node1'), 2);
      expect(merged.getValue('node2'), 3);
      expect(merged.getValue('node3'), 5);
    });

    test('comparison: isLessThanOrEqualTo', () {
      const vc1 = VectorClock({'node1': 1, 'node2': 1});
      const vc2 = VectorClock({'node1': 1, 'node2': 2});
      const vc3 = VectorClock({'node1': 2, 'node2': 1});
      const vc4 = VectorClock({'node1': 1, 'node2': 1});

      expect(vc1.isLessThanOrEqualTo(vc2), isTrue);
      expect(vc1.isLessThanOrEqualTo(vc4), isTrue);
      expect(vc2.isLessThanOrEqualTo(vc1), isFalse);
      expect(vc2.isLessThanOrEqualTo(vc3), isFalse); // Concurrent
    });

    test('comparison: isLessThan', () {
      const vc1 = VectorClock({'node1': 1, 'node2': 1});
      const vc2 = VectorClock({'node1': 1, 'node2': 2});
      const vc4 = VectorClock({'node1': 1, 'node2': 1});

      expect(vc1.isLessThan(vc2), isTrue);
      expect(vc1.isLessThan(vc4), isFalse);
    });

    test('comparison: isConcurrent', () {
      const vc1 = VectorClock({'node1': 2, 'node2': 1});
      const vc2 = VectorClock({'node1': 1, 'node2': 2});
      const vc3 = VectorClock({'node1': 1, 'node2': 1});

      expect(vc1.isConcurrent(vc2), isTrue);
      expect(vc1.isConcurrent(vc3), isFalse);
      expect(vc2.isConcurrent(vc3), isFalse);
    });

    test('equality and hashing', () {
      const vc1 = VectorClock({'node1': 1});
      const vc2 = VectorClock({'node1': 1});
      const vc3 = VectorClock({'node1': 2});

      expect(vc1, equals(vc2));
      expect(vc1.hashCode, equals(vc2.hashCode));
      expect(vc1, isNot(equals(vc3)));
    });
  });
}
