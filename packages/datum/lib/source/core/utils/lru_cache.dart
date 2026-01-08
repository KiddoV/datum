import 'dart:collection';

/// A generic Least Recently Used (LRU) cache implementation.
///
/// Wraps a [LinkedHashMap] to provide O(1) access and insertion while maintaining
/// insertion order. When the cache exceeds [maxSize], the least recently used
/// item (the first item in the iteration order) is evicted.
class LRUCache<K, V> {
  final int maxSize;
  final LinkedHashMap<K, V> _cache;

  /// Creates an [LRUCache] with the specified [maxSize].
  LRUCache(this.maxSize)
      : assert(maxSize > 0, 'maxSize must be greater than 0'),
        _cache = LinkedHashMap<K, V>();

  /// Retrieves the value associated with [key], or `null` if the key is not present.
  ///
  /// Accessing a key moves it to the end of the list (most recently used).
  V? get(K key) {
    if (!_cache.containsKey(key)) {
      return null;
    }
    final value = _cache.remove(key) as V;
    _cache[key] = value;
    return value;
  }

  /// Associates the [key] with the given [value].
  ///
  /// If the key was already in the cache, its associated value is changed.
  /// If the cache is full, the least recently used item is evicted.
  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  /// Removes the value associated with [key] and returns it.
  V? remove(K key) {
    return _cache.remove(key);
  }

  /// Checks if the cache contains [key].
  ///
  /// This method does NOT update the recentness of the key.
  bool containsKey(K key) => _cache.containsKey(key);

  /// Removes entries that satisfy the given [predicate].
  void removeWhere(bool Function(K key, V value) predicate) {
    _cache.removeWhere(predicate);
  }

  /// Removes all entries from the cache.
  void clear() {
    _cache.clear();
  }

  /// Returns the number of entries in the cache.
  int get length => _cache.length;

  /// Returns a map representation of the cache.
  ///
  /// Note: modifying the returned map does not affect the cache.
  Map<K, V> toMap() => Map.unmodifiable(_cache);

  /// Access using [] operator (updates recentness)
  V? operator [](K key) => get(key);

  /// Sets value using []= operator
  void operator []=(K key, V value) => put(key, value);

  /// Returns iterable of values in order from least recently used to most recently used.
  Iterable<V> get values => _cache.values;

  /// Returns iterable of keys in order from least recently used to most recently used.
  Iterable<K> get keys => _cache.keys;

  /// Returns entries as a [List].
  List<MapEntry<K, V>> get entries => _cache.entries.toList();
}
