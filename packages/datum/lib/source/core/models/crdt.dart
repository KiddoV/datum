import 'package:equatable/equatable.dart';

/// Base interface for Conflict-free Replicated Data Types (CRDTs).
abstract interface class CRDT<T> {
  /// Merges this CRDT with another of the same type.
  CRDT<T> merge(covariant CRDT<T> other);

  /// Returns the current value of the CRDT.
  T get value;

  /// Converts the CRDT state to a map for serialization.
  Map<String, dynamic> toMap();
}

/// A Positive-Negative Counter CRDT.
///
/// It allows increments and decrements across multiple replicas independently
/// and can be merged without conflicts.
class PNCounter extends Equatable implements CRDT<int> {
  final Map<String, int> _p; // Positive increments
  final Map<String, int> _n; // Negative decrements

  const PNCounter({
    Map<String, int>? p,
    Map<String, int>? n,
  })  : _p = p ?? const {},
        _n = n ?? const {};

  factory PNCounter.fromMap(Map<String, dynamic> map) {
    final pMap = (map['p'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as int)) ?? {};
    final nMap = (map['n'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as int)) ?? {};
    return PNCounter(p: pMap, n: nMap);
  }

  @override
  Map<String, dynamic> toMap() => {
        'p': _p,
        'n': _n,
      };

  @override
  int get value {
    final pTotal = _p.values.fold(0, (sum, val) => sum + val);
    final nTotal = _n.values.fold(0, (sum, val) => sum + val);
    return pTotal - nTotal;
  }

  PNCounter increment(String replicaId, [int amount = 1]) {
    final newP = Map<String, int>.from(_p);
    newP[replicaId] = (newP[replicaId] ?? 0) + amount;
    return PNCounter(p: newP, n: _n);
  }

  PNCounter decrement(String replicaId, [int amount = 1]) {
    final newN = Map<String, int>.from(_n);
    newN[replicaId] = (newN[replicaId] ?? 0) + amount;
    return PNCounter(p: _p, n: newN);
  }

  @override
  PNCounter merge(covariant PNCounter other) {
    final mergedP = Map<String, int>.from(_p);
    other._p.forEach((k, v) {
      mergedP[k] = mergedP.containsKey(k) ? (mergedP[k]! > v ? mergedP[k]! : v) : v;
    });

    final mergedN = Map<String, int>.from(_n);
    other._n.forEach((k, v) {
      mergedN[k] = mergedN.containsKey(k) ? (mergedN[k]! > v ? mergedN[k]! : v) : v;
    });

    return PNCounter(p: mergedP, n: mergedN);
  }

  @override
  List<Object?> get props => [_p, _n];

  @override
  String toString() => 'PNCounter(value: $value)';
}

/// An Observed-Remove Set CRDT.
///
/// Elements can be added and removed across multiple replicas.
/// It uses a "win" strategy for concurrent add/remove of the same element.
class ORSet<T> extends Equatable implements CRDT<Set<T>> {
  final Map<T, Set<String>> _addSet;
  final Map<T, Set<String>> _removeSet;

  const ORSet({
    Map<T, Set<String>>? addSet,
    Map<T, Set<String>>? removeSet,
  })  : _addSet = addSet ?? const {},
        _removeSet = removeSet ?? const {};

  factory ORSet.fromMap(Map<String, dynamic> map, T Function(dynamic) decoder) {
    final addMap = <T, Set<String>>{};
    (map['add'] as Map<String, dynamic>?)?.forEach((k, v) {
      addMap[decoder(k)] = (v as List).cast<String>().toSet();
    });

    final removeMap = <T, Set<String>>{};
    (map['remove'] as Map<String, dynamic>?)?.forEach((k, v) {
      removeMap[decoder(k)] = (v as List).cast<String>().toSet();
    });

    return ORSet(addSet: addMap, removeSet: removeMap);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'add': _addSet.map((k, v) => MapEntry(k.toString(), v.toList())),
      'remove': _removeSet.map((k, v) => MapEntry(k.toString(), v.toList())),
    };
  }

  @override
  Set<T> get value {
    final result = <T>{};
    for (final element in _addSet.keys) {
      final adds = _addSet[element] ?? {};
      final removes = _removeSet[element] ?? {};
      if (adds.difference(removes).isNotEmpty) {
        result.add(element);
      }
    }
    return result;
  }

  ORSet<T> add(T element, String tag) {
    final newAdd = Map<T, Set<String>>.from(_addSet.map((k, v) => MapEntry(k, Set<String>.from(v))));
    newAdd[element] = (newAdd[element] ?? {})..add(tag);
    return ORSet(addSet: newAdd, removeSet: _removeSet);
  }

  ORSet<T> remove(T element) {
    if (!_addSet.containsKey(element)) return this;
    final newRemove = Map<T, Set<String>>.from(_removeSet.map((k, v) => MapEntry(k, Set<String>.from(v))));
    newRemove[element] = (newRemove[element] ?? {})..addAll(_addSet[element]!);
    return ORSet(addSet: _addSet, removeSet: newRemove);
  }

  @override
  ORSet<T> merge(covariant ORSet<T> other) {
    final mergedAdd = Map<T, Set<String>>.from(_addSet.map((k, v) => MapEntry(k, Set<String>.from(v))));
    other._addSet.forEach((k, v) {
      mergedAdd[k] = (mergedAdd[k] ?? {})..addAll(v);
    });

    final mergedRemove = Map<T, Set<String>>.from(_removeSet.map((k, v) => MapEntry(k, Set<String>.from(v))));
    other._removeSet.forEach((k, v) {
      mergedRemove[k] = (mergedRemove[k] ?? {})..addAll(v);
    });

    return ORSet(addSet: mergedAdd, removeSet: mergedRemove);
  }

  @override
  List<Object?> get props => [_addSet, _removeSet];
}
