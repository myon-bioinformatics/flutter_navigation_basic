import '../../core/utils/ascii_fullwidth.dart';

/// One enabled key/value row used by query, headers, and form bodies.
class RequestField {
  const RequestField({
    required this.id,
    this.enabled = true,
    this.name = '',
    this.value = '',
    this.sensitive = false,
  });

  final String id;
  final bool enabled;
  final String name;
  final String value;
  final bool sensitive;

  /// Normalized name for comparisons (fullwidth→ASCII, trimmed, lowercased).
  String get normalizedName =>
      normalizeAsciiFullwidth(name).trim().toLowerCase();

  String get normalizedValue => normalizeAsciiFullwidth(value);

  bool get hasName => normalizeAsciiFullwidth(name).trim().isNotEmpty;

  RequestField copyWith({
    String? id,
    bool? enabled,
    String? name,
    String? value,
    bool? sensitive,
  }) {
    return RequestField(
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      name: name ?? this.name,
      value: value ?? this.value,
      sensitive: sensitive ?? this.sensitive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequestField &&
          other.id == id &&
          other.enabled == enabled &&
          other.name == name &&
          other.value == value &&
          other.sensitive == sensitive;

  @override
  int get hashCode => Object.hash(id, enabled, name, value, sensitive);
}

enum RequestBodyMode { none, raw, json, formUrlEncoded, multipart }

enum JsonFieldType { string, number, boolean, nullValue }

/// Optional typed JSON row builder (flat only; nested JSON stays in raw).
class JsonBodyField {
  const JsonBodyField({
    required this.id,
    this.enabled = true,
    this.name = '',
    this.type = JsonFieldType.string,
    this.value = '',
  });

  final String id;
  final bool enabled;
  final String name;
  final JsonFieldType type;
  final String value;

  JsonBodyField copyWith({
    String? id,
    bool? enabled,
    String? name,
    JsonFieldType? type,
    String? value,
  }) {
    return JsonBodyField(
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
    );
  }
}

enum HttpMethod { get, post, put, patch, delete, head, options }

extension HttpMethodX on HttpMethod {
  String get label => name.toUpperCase();

  static HttpMethod? tryParse(String raw) {
    final normalized = normalizeAsciiFullwidth(raw).trim().toUpperCase();
    for (final method in HttpMethod.values) {
      if (method.label == normalized) return method;
    }
    return null;
  }
}
