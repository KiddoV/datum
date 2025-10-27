import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

/// A fallback implementation of IsolateHelper for unsupported platforms.
///
/// This ensures that the code can be analyzed and compiled even in environments
/// where neither `dart:io` nor `dart:html` is available.
class IsolateHelper {
  /// Creates a fallback IsolateHelper.
  const IsolateHelper();

  /// Throws [UnimplementedError] as isolates are not supported.
  Future<Isolate> spawn<T>(void Function(T message) entryPoint, T message) {
    throw UnimplementedError('Isolates are not supported on this platform.');
  }

  /// Runs JSON encoding on the main thread as a fallback.
  Future<String> computeJsonEncode(Object? object) {
    return Future.value(jsonEncode(object));
  }

  /// Initializes any platform-specific resources. (No-op)
  Future<void> initialize() async {}

  /// Disposes of any platform-specific resources. (No-op)
  void dispose() {}
}
