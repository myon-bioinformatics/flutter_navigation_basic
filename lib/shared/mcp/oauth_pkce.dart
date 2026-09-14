import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// OAuth 2.1 Authorization Server Metadata (RFC 8414 subset).
class OAuthAuthorizationServerMetadata {
  const OAuthAuthorizationServerMetadata({
    required this.issuer,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    this.registrationEndpoint,
    this.scopesSupported = const [],
    this.responseTypesSupported = const ['code'],
    this.grantTypesSupported = const ['authorization_code'],
    this.codeChallengeMethodsSupported = const ['S256'],
    this.tokenEndpointAuthMethodsSupported = const ['none', 'client_secret_basic'],
  });

  final String issuer;
  final String authorizationEndpoint;
  final String tokenEndpoint;
  final String? registrationEndpoint;
  final List<String> scopesSupported;
  final List<String> responseTypesSupported;
  final List<String> grantTypesSupported;
  final List<String> codeChallengeMethodsSupported;
  final List<String> tokenEndpointAuthMethodsSupported;

  bool get supportsPkceS256 =>
      codeChallengeMethodsSupported.map((e) => e.toUpperCase()).contains('S256');

  factory OAuthAuthorizationServerMetadata.fromJson(Map<String, Object?> json) {
    String req(String key) {
      final value = json[key];
      if (value is! String || value.isEmpty) {
        throw FormatException('missing OAuth metadata field: $key');
      }
      return value;
    }

    List<String> list(String key) {
      final value = json[key];
      if (value is! List) return const [];
      return value.whereType<String>().toList(growable: false);
    }

    // Remote discovery must not invent capabilities the server omitted.
    // - Absent code_challenge_methods_supported → [] (supportsPkceS256 false)
    // - Absent token_endpoint_auth_methods_supported → RFC 8414 default
    //   `client_secret_basic` (not `none`)
    final codeChallengeMethods = json.containsKey(
      'code_challenge_methods_supported',
    )
        ? list('code_challenge_methods_supported')
        : const <String>[];
    final tokenAuthMethods = json.containsKey(
      'token_endpoint_auth_methods_supported',
    )
        ? list('token_endpoint_auth_methods_supported')
        : const ['client_secret_basic'];

    return OAuthAuthorizationServerMetadata(
      issuer: req('issuer'),
      authorizationEndpoint: req('authorization_endpoint'),
      tokenEndpoint: req('token_endpoint'),
      registrationEndpoint: json['registration_endpoint'] as String?,
      scopesSupported: list('scopes_supported'),
      responseTypesSupported: list('response_types_supported').isEmpty
          ? const ['code']
          : list('response_types_supported'),
      grantTypesSupported: list('grant_types_supported').isEmpty
          ? const ['authorization_code']
          : list('grant_types_supported'),
      codeChallengeMethodsSupported: codeChallengeMethods,
      tokenEndpointAuthMethodsSupported: tokenAuthMethods,
    );
  }

  Map<String, Object?> toJson() => {
        'issuer': issuer,
        'authorization_endpoint': authorizationEndpoint,
        'token_endpoint': tokenEndpoint,
        if (registrationEndpoint != null)
          'registration_endpoint': registrationEndpoint,
        'scopes_supported': scopesSupported,
        'response_types_supported': responseTypesSupported,
        'grant_types_supported': grantTypesSupported,
        'code_challenge_methods_supported': codeChallengeMethodsSupported,
        'token_endpoint_auth_methods_supported':
            tokenEndpointAuthMethodsSupported,
      };
}

/// OAuth 2.0 Protected Resource Metadata (RFC 9728 subset) for MCP HTTP.
class OAuthProtectedResourceMetadata {
  const OAuthProtectedResourceMetadata({
    required this.resource,
    required this.authorizationServers,
    this.scopesSupported = const [],
    this.bearerMethodsSupported = const ['header'],
    this.resourceName,
  });

  final String resource;
  final List<String> authorizationServers;
  final List<String> scopesSupported;
  final List<String> bearerMethodsSupported;
  final String? resourceName;

  factory OAuthProtectedResourceMetadata.fromJson(Map<String, Object?> json) {
    final resource = json['resource'];
    if (resource is! String || resource.isEmpty) {
      throw const FormatException('missing protected resource');
    }
    final servers = json['authorization_servers'];
    if (servers is! List || servers.isEmpty) {
      throw const FormatException('missing authorization_servers');
    }
    return OAuthProtectedResourceMetadata(
      resource: resource,
      authorizationServers: servers.whereType<String>().toList(growable: false),
      scopesSupported: (json['scopes_supported'] as List?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const [],
      bearerMethodsSupported: (json['bearer_methods_supported'] as List?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const ['header'],
      resourceName: json['resource_name'] as String?,
    );
  }

  Map<String, Object?> toJson() => {
        'resource': resource,
        'authorization_servers': authorizationServers,
        'scopes_supported': scopesSupported,
        'bearer_methods_supported': bearerMethodsSupported,
        if (resourceName != null) 'resource_name': resourceName,
      };
}

/// PKCE (RFC 7636) S256 pair. Uses [Random.secure] + verified `crypto` SHA-256.
class PkcePair {
  const PkcePair({
    required this.codeVerifier,
    required this.codeChallenge,
    this.codeChallengeMethod = 'S256',
  });

  final String codeVerifier;
  final String codeChallenge;
  final String codeChallengeMethod;

  /// Creates a new S256 PKCE pair. Verifier is 43–128 unreserved chars.
  factory PkcePair.generate({Random? random, int verifierLength = 64}) {
    if (verifierLength < 43 || verifierLength > 128) {
      throw ArgumentError.value(verifierLength, 'verifierLength', '43..128');
    }
    final rng = random ?? Random.secure();
    const alphabet =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final verifier = String.fromCharCodes(
      List<int>.generate(
        verifierLength,
        (_) => alphabet.codeUnitAt(rng.nextInt(alphabet.length)),
      ),
    );
    return PkcePair(
      codeVerifier: verifier,
      codeChallenge: codeChallengeS256(verifier),
    );
  }

  static String codeChallengeS256(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64UrlEncode(Uint8List.fromList(digest.bytes))
        .replaceAll('=', '');
  }
}

/// Result of a local Bearer audience check (no network).
enum BearerAudienceStatus {
  missing,
  malformed,
  expired,
  wrongAudience,
  ok,
}

class BearerAudienceClaim {
  const BearerAudienceClaim({
    required this.status,
    this.audience,
    this.expiresAt,
  });

  final BearerAudienceStatus status;
  final String? audience;
  final DateTime? expiresAt;
}

/// Demo-only JWT-shaped Bearer parser for mock/foundation tests.
///
/// Accepts `header.payload.signature` and base64url-decodes the payload JSON.
/// Signature is **not** verified here — live verification belongs to #70 /
/// platform adapters. Use only with fixture tokens.
BearerAudienceClaim inspectBearerAudience(
  String? authorizationHeader, {
  required String expectedAudience,
  DateTime Function()? clock,
}) {
  if (authorizationHeader == null || authorizationHeader.isEmpty) {
    return const BearerAudienceClaim(status: BearerAudienceStatus.missing);
  }
  final parts = authorizationHeader.split(RegExp(r'\s+'));
  if (parts.length != 2 || parts[0].toLowerCase() != 'bearer') {
    return const BearerAudienceClaim(status: BearerAudienceStatus.malformed);
  }
  final token = parts[1];
  final segments = token.split('.');
  if (segments.length < 2) {
    return const BearerAudienceClaim(status: BearerAudienceStatus.malformed);
  }
  try {
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(_padBase64(segments[1]))),
    );
    if (payload is! Map) {
      return const BearerAudienceClaim(status: BearerAudienceStatus.malformed);
    }
    final aud = payload['aud'];
    final exp = payload['exp'];
    final audiences = <String>[];
    if (aud is String) {
      audiences.add(aud);
    } else if (aud is List) {
      if (aud.isEmpty) {
        return const BearerAudienceClaim(
          status: BearerAudienceStatus.malformed,
        );
      }
      for (final item in aud) {
        if (item is! String || item.isEmpty) {
          return const BearerAudienceClaim(
            status: BearerAudienceStatus.malformed,
          );
        }
        audiences.add(item);
      }
    } else if (aud != null) {
      return const BearerAudienceClaim(status: BearerAudienceStatus.malformed);
    }
    final audience = audiences.isEmpty ? null : audiences.first;
    DateTime? expiresAt;
    if (exp is int) {
      expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    } else if (exp is num) {
      expiresAt =
          DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
    }
    final now = (clock ?? DateTime.now)().toUtc();
    if (expiresAt != null && !expiresAt.isAfter(now)) {
      return BearerAudienceClaim(
        status: BearerAudienceStatus.expired,
        audience: audience,
        expiresAt: expiresAt,
      );
    }
    if (!audiences.contains(expectedAudience)) {
      return BearerAudienceClaim(
        status: BearerAudienceStatus.wrongAudience,
        audience: audience,
        expiresAt: expiresAt,
      );
    }
    return BearerAudienceClaim(
      status: BearerAudienceStatus.ok,
      audience: expectedAudience,
      expiresAt: expiresAt,
    );
  } on Object {
    return const BearerAudienceClaim(status: BearerAudienceStatus.malformed);
  }
}

String _padBase64(String value) {
  final mod = value.length % 4;
  if (mod == 0) return value;
  return value.padRight(value.length + (4 - mod), '=');
}
