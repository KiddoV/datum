import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

/// A web-compatible implementation of IsolateHelper.
///
/// On the web, `Isolate.spawn` is not supported. This implementation provides
/// fallbacks for other methods.
class IsolateHelper {
  /// Creates an IsolateHelper for the web.
  const IsolateHelper();

  /// Throws [UnimplementedError] as `Isolate.spawn` is not supported on web.
  Future<Isolate> spawn<T>(void Function(T message) entryPoint, T message) {
    throw UnimplementedError('Isolate.spawn is not supported on the web.');
  }

  /// Runs JSON encoding on the main thread as a fallback for the web.
  ///
  /// While `Isolate.run` is web-compatible, this provides a simple synchronous
  /// fallback if needed. For very large objects, consider a web worker.
  Future<String> computeJsonEncode(Object? object) {
    return Future.value(jsonEncode(object));
  }

  /// Initializes any platform-specific resources. (No-op for web)
  Future<void> initialize() async {}

  /// Disposes of any platform-specific resources. (No-op for web)
  void dispose() {}
}
