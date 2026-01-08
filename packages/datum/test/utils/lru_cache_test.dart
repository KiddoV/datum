import 'package:datum/source/core/utils/lru_cache.dart';
import 'package:test/test.dart';

void main() {
  group('LRUCache', () {
    test('should return null for non-existent key', () {
      final cache = LRUCache<String, int>(3);
      expect(cache.get('a'), isNull);
    });

    test('should store and retrieve values', () {
      final cache = LRUCache<String, int>(3);
      cache.put('a', 1);
      expect(cache.get('a'), 1);
    });

    test('should evict least recently used item when full', () {
      final cache = LRUCache<String, int>(3);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);

      // Cache is full: [a, b, c] (assuming insertion order is oldest to newest)

      cache.put('d', 4);
      // 'a' should be evicted: [b, c, d]

      expect(cache.containsKey('a'), isFalse);
      expect(cache.containsKey('b'), isTrue);
      expect(cache.containsKey('c'), isTrue);
      expect(cache.containsKey('d'), isTrue);
    });

    test('should update recentness on access', () {
      final cache = LRUCache<String, int>(3);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);

      // Access 'a', making it most recently used: [b, c, a]
      cache.get('a');

      cache.put('d', 4);
      // 'b' should be evicted instead of 'a': [c, a, d]

      expect(cache.containsKey('b'), isFalse);
      expect(cache.containsKey('a'), isTrue);
    });

    test('should update value and recentness on put', () {
      final cache = LRUCache<String, int>(3);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);

      // Update 'a', making it MRU: [b, c, a]
      cache.put('a', 10);

      cache.put('d', 4);
      // 'b' should be evicted: [c, a, d]

      expect(cache.containsKey('b'), isFalse);
      expect(cache.get('a'), 10);
    });

    test('should support operator [] and []=', () {
      final cache = LRUCache<String, int>(2);
      cache['a'] = 1;
      expect(cache['a'], 1);
    });

    test('should clear cache', () {
      final cache = LRUCache<String, int>(3);
      cache.put('a', 1);
      cache.clear();
      expect(cache.length, 0);
    });

    test('remove should remove item', () {
      final cache = LRUCache<String, int>(3);
      cache['a'] = 1;
      cache.remove('a');
      expect(cache.containsKey('a'), isFalse);
    });

    test('removeWhere should remove items matching predicate', () {
      final cache = LRUCache<String, int>(4);
      cache['a'] = 1;
      cache['b'] = 2;
      cache['c'] = 3;

      cache.removeWhere((k, v) => v % 2 != 0); // Remove odds

      expect(cache.containsKey('a'), isFalse); // 1 is odd
      expect(cache.containsKey('b'), isTrue); // 2 is even
      expect(cache.containsKey('c'), isFalse); // 3 is odd
    });
  });
}
