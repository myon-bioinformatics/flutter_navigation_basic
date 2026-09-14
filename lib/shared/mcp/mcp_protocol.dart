/// Pinned MCP + OAuth foundation constants for this repository.
///
/// Full UI/executor wiring lands in a later PR; this file is the single place
/// that records which protocol versions the foundation targets.
///
/// **Legacy scope:** this foundation pins MCP `2025-03-26` (initialize +
/// `Mcp-Session-Id` Streamable HTTP). The current official MCP revision is
/// `2026-07-28` (stateless / `server/discover`). Treat this package as
/// legacy-era support unless a later PR adds dual-era compatibility.
abstract final class McpProtocol {
  /// MCP specification revision this foundation targets.
  /// Display this value in diagnostics / support matrix UIs.
  static const specificationVersion = '2025-03-26';

  /// Newest official MCP revision known to this repo (not implemented here).
  static const currentOfficialVersion = '2026-07-28';

  /// Whether this foundation implements the current official MCP revision.
  static const implementsCurrentOfficial = false;

  /// JSON-RPC 2.0 version string required on every request/response.
  static const jsonRpcVersion = '2.0';

  /// HTTP header carrying the negotiated MCP protocol version.
  static const protocolVersionHeader = 'mcp-protocol-version';

  /// HTTP header carrying the MCP session id after `initialize`.
  static const sessionIdHeader = 'mcp-session-id';

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

  /// This matrix describes the pinned `2025-03-26` path only.
  static const legacyMcpEra = true;
  static const currentOfficialVersion = McpProtocol.currentOfficialVersion;
  static const implementsCurrentOfficial =
      McpProtocol.implementsCurrentOfficial;

  static Map<String, Object?> get asJson => {
        'specificationVersion': specificationVersion,
        'currentOfficialVersion': currentOfficialVersion,
        'implementsCurrentOfficial': implementsCurrentOfficial,
        'legacyMcpEra': legacyMcpEra,
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
