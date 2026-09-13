/// Allow-lists and network-boundary checks for Maps short-link expansion.
///
/// Keeps initial short URLs, redirect hops, and final expanded Maps URLs on
/// explicit HTTP(S) hosts so expanders cannot treat `?q=lat,lng` on arbitrary
/// destinations as success, and IO must not GET private/link-local targets.
class MapsUrlPolicy {
  const MapsUrlPolicy._();

  static const Set<int> _allowedPorts = {80, 443};

  /// Whether [uri] is http(s), has a host, no userinfo, and an allowed port.
  static bool isSafePublicHttpUri(Uri uri) {
    if (!_isHttpOrHttpsScheme(uri.scheme)) return false;
    if (uri.host.isEmpty) return false;
    if (uri.userInfo.isNotEmpty) return false;
    if (uri.hasPort && !_allowedPorts.contains(uri.port)) return false;
    if (isBlockedNetworkHost(uri.host)) return false;
    return true;
  }

  /// Initial short / share URLs that may need redirect expansion.
  static bool isAllowedShortShareUri(Uri uri) {
    if (!isSafePublicHttpUri(uri)) return false;
    final host = uri.host.toLowerCase();
    final path = uri.path;

    if (host == 'maps.app.goo.gl') {
      return path.isNotEmpty && path != '/';
    }
    // Legacy Google short hosts only when the path is Maps-scoped.
    if (host == 'goo.gl' || host == 'g.co') {
      final lower = path.toLowerCase();
      return lower == '/maps' || lower.startsWith('/maps/');
    }
    if (host == 'maps.apple.com') {
      return true;
    }
    return false;
  }

  /// Final URLs that may be parsed for coordinates after expansion.
  static bool isAllowedExpandedMapsUri(Uri uri) {
    if (!isSafePublicHttpUri(uri)) return false;
    final host = uri.host.toLowerCase();
    if (host == 'maps.apple.com') return true;
    if (_isGoogleMapsHost(host)) {
      if (host == 'maps.google.com' || host.startsWith('maps.google.')) {
        return true;
      }
      final path = uri.path.toLowerCase();
      return path == '/maps' || path.startsWith('/maps/');
    }
    return false;
  }

  /// Each redirect hop must pass this before IO issues the next GET.
  static bool isAllowedRedirectHopUri(Uri uri) {
    if (!isSafePublicHttpUri(uri)) return false;
    final host = uri.host.toLowerCase();
    if (host == 'maps.app.goo.gl') return true;
    if (host == 'goo.gl' || host == 'g.co') {
      final lower = uri.path.toLowerCase();
      return lower.isEmpty ||
          lower == '/' ||
          lower == '/maps' ||
          lower.startsWith('/maps/');
    }
    if (host == 'maps.apple.com') return true;
    if (_isGoogleMapsHost(host)) return true;
    return false;
  }

  /// Localhost, private, and link-local hosts that must never be fetched.
  static bool isBlockedNetworkHost(String host) {
    final normalized = host.toLowerCase().trim();
    if (normalized.isEmpty) return true;
    if (normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '0.0.0.0' ||
        normalized == '::1' ||
        normalized == '[::1]') {
      return true;
    }
    if (normalized.endsWith('.localhost') || normalized.endsWith('.local')) {
      return true;
    }

    final ipv4 = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$')
        .firstMatch(normalized);
    if (ipv4 != null) {
      final a = int.parse(ipv4.group(1)!);
      final b = int.parse(ipv4.group(2)!);
      final c = int.parse(ipv4.group(3)!);
      final d = int.parse(ipv4.group(4)!);
      if (a > 255 || b > 255 || c > 255 || d > 255) return true;
      if (a == 0 || a == 10 || a == 127) return true;
      if (a == 169 && b == 254) return true;
      if (a == 172 && b >= 16 && b <= 31) return true;
      if (a == 192 && b == 168) return true;
      if (a == 100 && b >= 64 && b <= 127) return true;
      return false;
    }

    final ipv6 = normalized.startsWith('[') && normalized.endsWith(']')
        ? normalized.substring(1, normalized.length - 1)
        : normalized;
    if (ipv6.contains(':')) {
      final lower = ipv6.toLowerCase();
      if (lower == '::1') return true;
      if (lower.startsWith('fe80:')) return true;
      if (lower.startsWith('fc') || lower.startsWith('fd')) return true;
      if (lower.startsWith('::ffff:')) {
        final mapped = lower.substring('::ffff:'.length);
        return isBlockedNetworkHost(mapped);
      }
    }
    return false;
  }

  static bool _isHttpOrHttpsScheme(String scheme) {
    final normalized = scheme.toLowerCase();
    return normalized == 'http' || normalized == 'https';
  }

  static bool _isGoogleMapsHost(String host) {
    if (host == 'maps.google.com' || host.startsWith('maps.google.')) {
      return true;
    }
    final withoutWww =
        host.startsWith('www.') ? host.substring(4) : host;
    // google.com, google.co.jp, google.co.uk, ...
    return RegExp(r'^google(\.[a-z]{2,}){1,3}$').hasMatch(withoutWww);
  }
}
