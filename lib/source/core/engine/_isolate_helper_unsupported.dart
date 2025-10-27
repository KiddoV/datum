import 'dart:convert';

class IsolateHelper {
  const IsolateHelper();

  Future<String> computeJsonEncode(Object? object) async {
    // On unsupported platforms, run synchronously on the main thread.
    return jsonEncode(object);
  }
}
