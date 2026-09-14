import '../../core/utils/ascii_fullwidth.dart';
import 'request_field.dart';

/// Immutable HTTP request draft shared by editor UI, preview, and curl export.
class RequestDraft {
  const RequestDraft({
    this.method = HttpMethod.get,
    this.url = '',
    this.query = const <RequestField>[],
    this.headers = const <RequestField>[],
    this.bodyMode = RequestBodyMode.none,
    this.rawBody = '',
    this.formFields = const <RequestField>[],
    this.jsonFields = const <JsonBodyField>[],
  });

  final HttpMethod method;
  final String url;
  final List<RequestField> query;
  final List<RequestField> headers;
  final RequestBodyMode bodyMode;
  final String rawBody;
  final List<RequestField> formFields;
  final List<JsonBodyField> jsonFields;

  String get normalizedUrl => normalizeAsciiFullwidth(url).trim();

  List<RequestField> get enabledQuery =>
      query.where((f) => f.enabled && f.hasName).toList(growable: false);

  List<RequestField> get enabledHeaders =>
      headers.where((f) => f.enabled && f.hasName).toList(growable: false);

  List<RequestField> get enabledFormFields =>
      formFields.where((f) => f.enabled && f.hasName).toList(growable: false);

  List<JsonBodyField> get enabledJsonFields => jsonFields
      .where(
        (f) =>
            f.enabled && normalizeAsciiFullwidth(f.name).trim().isNotEmpty,
      )
      .toList(growable: false);

  /// Header names that collide case-insensitively (normalized ASCII).
  Set<String> get duplicateHeaderNames {
    final seen = <String>{};
    final dupes = <String>{};
    for (final field in enabledHeaders) {
      final name = field.normalizedName;
      if (!seen.add(name)) dupes.add(name);
    }
    return dupes;
  }

  /// True when any enabled header name/value contains CR or LF.
  bool get hasHeaderCrLf {
    for (final field in enabledHeaders) {
      final name = normalizeAsciiFullwidth(field.name);
      final value = field.normalizedValue;
      if (name.contains('\r') ||
          name.contains('\n') ||
          value.contains('\r') ||
          value.contains('\n')) {
        return true;
      }
    }
    return false;
  }

  RequestDraft copyWith({
    HttpMethod? method,
    String? url,
    List<RequestField>? query,
    List<RequestField>? headers,
    RequestBodyMode? bodyMode,
    String? rawBody,
    List<RequestField>? formFields,
    List<JsonBodyField>? jsonFields,
  }) {
    return RequestDraft(
      method: method ?? this.method,
      url: url ?? this.url,
      query: query ?? this.query,
      headers: headers ?? this.headers,
      bodyMode: bodyMode ?? this.bodyMode,
      rawBody: rawBody ?? this.rawBody,
      formFields: formFields ?? this.formFields,
      jsonFields: jsonFields ?? this.jsonFields,
    );
  }

  static RequestDraft empty() => const RequestDraft();
}
