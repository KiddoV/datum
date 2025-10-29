import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

/// Helper for offloading work to a background isolate on native platforms.
class IsolateHelper {
  /// Creates an IsolateHelper for native platforms.
  const IsolateHelper();

  /// Spawns a long-lived isolate for complex, two-way communication.
  Future<Isolate> spawn<T>(void Function(T message) entryPoint, T message) => Isolate.spawn<T>(entryPoint, message);

  /// Runs a one-off JSON encoding task in a background isolate.
  ///
  /// This is ideal for preventing UI jank when encoding large objects.
  Future<String> computeJsonEncode(Object? object) {
    return Isolate.run(() => jsonEncode(object));
  }

  /// Initializes any platform-specific resources. (No-op for native)
  Future<void> initialize() async {}

  /// Disposes of any platform-specific resources. (No-op for native)
  void dispose() {}
}
