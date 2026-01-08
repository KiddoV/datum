import 'package:datum/datum.dart';
import 'package:test/test.dart';

void main() {
  group('PNCounter', () {
    test('initial value is zero', () {
      const counter = PNCounter();
      expect(counter.value, 0);
    });

    test('increments correctly', () {
      var counter = const PNCounter();
      counter = counter.increment('node1', 5);
      expect(counter.value, 5);
      counter = counter.increment('node2', 3);
      expect(counter.value, 8);
    });

    test('decrements correctly', () {
      var counter = const PNCounter();
      counter = counter.increment('node1', 10);
      counter = counter.decrement('node1', 4);
      expect(counter.value, 6);
    });

    test('merges two counters', () {
      final c1 = const PNCounter().increment('node1', 5).decrement('node2', 2);
      final c2 = const PNCounter().increment('node1', 3).increment('node2', 4).decrement('node2', 5);

      final merged = c1.merge(c2);

      // For each node, we take max of P and max of N
      // node1: P=max(5,3)=5, N=max(0,0)=0 -> 5
      // node2: P=max(0,4)=4, N=max(2,5)=5 -> -1
      // Total: 5 + (-1) = 4
      expect(merged.value, 4);
    });

    test('to/from map', () {
      final counter = const PNCounter().increment('node1', 5).decrement('node2', 3);
      final map = counter.toMap();
      final fromMap = PNCounter.fromMap(map);

      expect(fromMap.value, 2);
      expect(fromMap.toMap(), equals(map));
    });
  });

  group('ORSet', () {
    test('initial set is empty', () {
      const set = ORSet<String>();
      expect(set.value, isEmpty);
    });

    test('adds elements', () {
      var set = const ORSet<String>();
      set = set.add('a', 'tag1');
      set = set.add('b', 'tag2');
      expect(set.value, containsAll(['a', 'b']));
    });

    test('removes elements', () {
      var set = const ORSet<String>();
      set = set.add('a', 'tag1');
      set = set.add('b', 'tag2');
      set = set.remove('a');
      expect(set.value, ['b']);
      expect(set.value, isNot(contains('a')));
    });

    test('merges two sets', () {
      // Set 1: adds 'a' (tag1), 'b' (tag2)
      final s1 = const ORSet<String>().add('a', 'tag1').add('b', 'tag2');

      // Set 2: observes s1, adds 'a' (tag3), removes 'b'
      final s2 = s1.add('a', 'tag3').remove('b');

      final merged = s1.merge(s2);

      // 'a' has tags tag1, tag3. Tag1 is not in s2.remove, tag3 is not in s1.remove.
      // 'b' tag2 is in s1.add but marked as removed in s2.
      expect(merged.value, contains('a'));
      expect(merged.value, isNot(contains('b')));
    });

    test('to/from map', () {
      final set = const ORSet<String>().add('a', 'tag1').remove('b');
      final map = set.toMap();
      final fromMap = ORSet<String>.fromMap(map, (v) => v.toString());

      expect(fromMap.toMap(), equals(map));
    });
  });
}
