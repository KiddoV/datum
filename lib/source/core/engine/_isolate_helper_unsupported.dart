import 'dart:convert';

class IsolateHelper {
  const IsolateHelper();

  Future<String> computeJsonEncode(Object? object) async {
    // On unsupported platforms, run synchronously on the main thread.
    return jsonEncode(object);
  }

  /// Initializes any platform-specific resources. (No-op for unsupported)
  Future<void> initialize() async {}

  /// Disposes of any platform-specific resources. (No-op for unsupported)
  void dispose() {}
}
