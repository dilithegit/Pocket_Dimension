/// Safe JSON parsing and type-casting helpers to prevent runtime cast exceptions.
Map<String, dynamic> asStringKeyedMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  throw FormatException('Expected a Map, got ${value?.runtimeType}');
}
