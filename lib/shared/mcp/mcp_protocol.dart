import 'dart:convert';

/// Pinned MCP + OAuth foundation constants for this repository.
///
/// Full UI/executor wiring lands in a later PR; this file is the single place
/// that records which protocol versions the foundation targets.
///
/// **Dual-era scope:** this foundation implements legacy MCP `2025-03-26`
/// (initialize + `Mcp-Session-Id` Streamable HTTP) **and** current-official
/// `2026-07-28` (`server/discover`, stateless tools with per-request `_meta`).
/// 
abstract final class McpProtocol {
  /// MCP specification revision this foundation targets.
  /// Display this value in diagnostics / support matrix UIs.
  static const specificationVersion = '2025-03-26';

  /// Newest official MCP revision known to this repo (not implemented here).
  static const currentOfficialVersion = '2026-07-28';

  /// Whether this foundation implements the current official MCP revision.
  static const implementsCurrentOfficial = true;

  /// JSON-RPC 2.0 version string required on every request/response.
  static const jsonRpcVersion = '2.0';

  /// HTTP header carrying the negotiated MCP protocol version.
  static const protocolVersionHeader = 'mcp-protocol-version';

  /// HTTP header carrying the MCP session id after `initialize`.
  static const sessionIdHeader = 'mcp-session-id';

  /// HTTP header mirroring JSON-RPC `method` (current-official Streamable HTTP).
  static const methodHeader = 'mcp-method';

  /// HTTP header mirroring tool/prompt `name` or resource `uri` when required.
  static const nameHeader = 'mcp-name';

  /// Accept values for Streamable HTTP (JSON and optional SSE stream).
  static const acceptJson = 'application/json';
  static const acceptEventStream = 'text/event-stream';

  /// Legacy SSE transport is compatibility-only (not the default path).
  static const legacySseTransport = 'sse';
  static const streamableHttpTransport = 'streamable-http';
}

/// High-level support flags for Flutter / web constraints.
///
/// In-app execution is **not** promised for every mode — callers must surface
/// this matrix rather than implying silent success on unsupported platforms.
abstract final class McpSupportMatrix {
  static const specificationVersion = McpProtocol.specificationVersion;

  static const streamableHttp = true;
  static const jsonRpc = true;
  static const sessionHeader = true;
  static const oauthDiscovery = true;
  static const pkceS256 = true;
  static const bearerAudienceCheck = true;

  /// Browser CORS / cookie / client-cert limits mean full in-app OAuth is not
  /// guaranteed on Flutter Web; discovery + PKCE helpers still work offline.
  static const flutterWebInAppOAuthGuaranteed = false;
  static const legacySseDefault = false;

  /// Dual-era: legacy `2025-03-26` and current-official `2026-07-28`.
  static const legacyMcpEra = true;
  static const currentOfficialEra = true;
  static const currentOfficialVersion = McpProtocol.currentOfficialVersion;
  static const implementsCurrentOfficial =
      McpProtocol.implementsCurrentOfficial;

  static Map<String, Object?> get asJson => {
        'specificationVersion': specificationVersion,
        'currentOfficialVersion': currentOfficialVersion,
        'implementsCurrentOfficial': implementsCurrentOfficial,
        'legacyMcpEra': legacyMcpEra,
        'currentOfficialEra': currentOfficialEra,
        'streamableHttp': streamableHttp,
        'jsonRpc': jsonRpc,
        'sessionHeader': sessionHeader,
        'oauthDiscovery': oauthDiscovery,
        'pkceS256': pkceS256,
        'bearerAudienceCheck': bearerAudienceCheck,
        'flutterWebInAppOAuthGuaranteed': flutterWebInAppOAuthGuaranteed,
        'legacySseDefault': legacySseDefault,
      };
}

/// Encode/decode current-official MCP header values (`Mcp-Name`, etc.).
///
/// Values that are not plain printable ASCII, that carry leading/trailing
/// whitespace, or that already look like the sentinel MUST be encoded as
/// `=?base64?<b64>?=` so intermediaries and `dart:io` do not corrupt them.
abstract final class McpHeaderCodec {
  static final RegExp _sentinel =
      RegExp(r'^=\?base64\?([A-Za-z0-9+/=]+)\?=$');

  /// True when [value] cannot safely travel as a raw ASCII header.
  static bool needsEncoding(String value) {
    if (value != value.trim()) return true;
    if (_sentinel.hasMatch(value) ||
        (value.startsWith('=?') && value.endsWith('?='))) {
      return true;
    }
    for (final unit in value.codeUnits) {
      if (unit < 0x20 || unit > 0x7e) return true;
    }
    return false;
  }

  /// Returns [value] unchanged when ASCII-safe; otherwise a base64 sentinel.
  static String encode(String value) {
    if (!needsEncoding(value)) return value;
    return '=?base64?${base64.encode(utf8.encode(value))}?=';
  }

  /// Decodes a raw or sentinel header value. Returns null for malformed
  /// sentinel-shaped input.
  static String? decode(String value) {
    final match = _sentinel.firstMatch(value);
    if (match != null) {
      try {
        return utf8.decode(base64.decode(match.group(1)!));
      } on FormatException {
        return null;
      }
    }
    // Reject broken sentinel-shaped values that are not well-formed.
    if (value.startsWith('=?') && value.contains('?=')) {
      return null;
    }
    return value;
  }
}

