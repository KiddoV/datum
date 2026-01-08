import 'dart:convert' as convert;

/// Utilities for JSON encoding/decoding to support generated code.
class DatumJsonUtils {
  static String encode(Object? value) => convert.json.encode(value);
  static dynamic decode(String source) => convert.json.decode(source);
}
