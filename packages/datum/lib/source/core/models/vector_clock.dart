import 'package:equatable/equatable.dart';

/// Represents a Vector Clock for tracking causality in a distributed system.
///
/// A Vector Clock is a map of replica IDs to their successful operation counts.
/// It allows determining if one event happened before another, or if they
/// are concurrent (conflicting).
class VectorClock extends Equatable {
  final Map<String, int> _clocks;

  const VectorClock([Map<String, int>? clocks]) : _clocks = clocks ?? const {};

  /// Creates a [VectorClock] from a map.
  factory VectorClock.fromMap(Map<String, dynamic> map) {
    return VectorClock(map.map((key, value) => MapEntry(key, value as int)));
  }

  /// Converts the [VectorClock] to a map.
  Map<String, int> toMap() => Map.unmodifiable(_clocks);

  /// Returns the count for the given replica ID.
  int getValue(String replicaId) => _clocks[replicaId] ?? 0;

  /// Increments the clock for the given replica ID.
  VectorClock increment(String replicaId) {
    final newClocks = Map<String, int>.from(_clocks);
    newClocks[replicaId] = (newClocks[replicaId] ?? 0) + 1;
    return VectorClock(newClocks);
  }

  /// Merges this clock with another clock.
  ///
  /// The resulting clock contains the maximum value for each replica ID.
  VectorClock merge(VectorClock other) {
    final newClocks = Map<String, int>.from(_clocks);
    other._clocks.forEach((replicaId, count) {
      newClocks[replicaId] = _clocks.containsKey(replicaId) ? (_clocks[replicaId]! > count ? _clocks[replicaId]! : count) : count;
    });
    return VectorClock(newClocks);
  }

  /// Returns true if this clock is concurrent with [other].
  ///
  /// Concurrent clocks indicate a conflict where two replicas modified the
  /// same entity independently.
  bool isConcurrent(VectorClock other) {
    return !isLessThanOrEqualTo(other) && !other.isLessThanOrEqualTo(this);
  }

  /// Returns true if this clock is less than or equal to [other].
  ///
  /// This means every entry in this clock is less than or equal to the
  /// corresponding entry in [other].
  bool isLessThanOrEqualTo(VectorClock other) {
    for (final entry in _clocks.entries) {
      final otherCount = other._clocks[entry.key] ?? 0;
      if (entry.value > otherCount) return false;
    }
    return true;
  }

  /// Returns true if this clock is strictly less than [other].
  bool isLessThan(VectorClock other) {
    return isLessThanOrEqualTo(other) && this != other;
  }

  @override
  List<Object?> get props => [_clocks];

  @override
  String toString() => 'VectorClock($_clocks)';
}
