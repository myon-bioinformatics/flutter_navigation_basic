"""Network probe: DNS, TCP, TLS, and HTTP timings for one URL.

Python stdlib port of tool/net_probe.dart -- no project-specific (Flutter)
dependency, so it doesn't need to be Dart. Output format intentionally
mirrors the Dart version's section headers ([DNS]/[TCP]/[TLS]/[HTTP]) so
existing muscle memory / docs transfer, though exact text isn't byte-for-
byte identical (e.g. certificate subject/issuer formatting).
"""

from __future__ import annotations

import hashlib
import socket
import ssl
import sys
import time
import urllib.error
import urllib.request
from urllib.parse import urlsplit

_NETWORK_TIMEOUT = 10.0
_MAX_REDIRECTS = 5
_USER_AGENT = "flutter-navigation-basic-dev-probe/1.0"


def _format_duration(seconds: float) -> str:
    if seconds < 1:
        return f"{round(seconds * 1000)} ms"
    return f"{seconds}s"


def _format_bytes(count: int) -> str:
    units = ["B", "KiB", "MiB", "GiB"]
    value = float(count)
    unit = 0
    while value >= 1024 and unit < len(units) - 1:
        value /= 1024
        unit += 1
    decimals = 0 if unit == 0 else 2
    return f"{value:.{decimals}f} {units[unit]}"


def _format_name(rdns_tuple: tuple) -> str:
    parts = []
    for attr in rdns_tuple:
        for key, value in attr:
            parts.append(f"{key}={value}")
    return ", ".join(parts)


class _CountingRedirectHandler(urllib.request.HTTPRedirectHandler):
    def __init__(self) -> None:
        self.redirect_count = 0

    def redirect_request(self, req, fp, code, msg, headers, newurl):  # noqa: D102
        self.redirect_count += 1
        if self.redirect_count > _MAX_REDIRECTS:
            return None
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def run(url: str) -> int:
    parts = urlsplit(url)
    if not parts.scheme or not parts.hostname:
        print(f"Invalid URL: {url}", file=sys.stderr)
        return 64
    if parts.scheme not in ("http", "https"):
        print("Only http:// and https:// are supported.", file=sys.stderr)
        return 64

    host = parts.hostname
    port = parts.port or (443 if parts.scheme == "https" else 80)

    print("=== Network Probe ===")
    print(f"target: {url}")
    print()

    try:
        dns_start = time.monotonic()
        addrinfo = socket.getaddrinfo(host, port, proto=socket.IPPROTO_TCP)
        dns_elapsed = time.monotonic() - dns_start
        print(f"[DNS] {_format_duration(dns_elapsed)}")
        seen = set()
        for family, _, _, _, sockaddr in addrinfo:
            address = sockaddr[0]
            if address in seen:
                continue
            seen.add(address)
            kind = "IPv6" if family == socket.AF_INET6 else "IPv4"
            print(f"  {kind}: {address}")

        tcp_start = time.monotonic()
        sock = socket.create_connection((host, port), timeout=_NETWORK_TIMEOUT)
        try:
            tcp_elapsed = time.monotonic() - tcp_start
            local_addr, local_port = sock.getsockname()[:2]
            remote_addr, remote_port = sock.getpeername()[:2]
            print(f"[TCP] {_format_duration(tcp_elapsed)}")
            print(f"  local : {local_addr}:{local_port}")
            print(f"  remote: {remote_addr}:{remote_port}")

            if parts.scheme == "https":
                tls_start = time.monotonic()
                context = ssl.create_default_context()
                with context.wrap_socket(sock, server_hostname=host) as secure:
                    tls_elapsed = time.monotonic() - tls_start
                    print(f"[TLS] {_format_duration(tls_elapsed)}")
                    cert = secure.getpeercert()
                    der = secure.getpeercert(binary_form=True)
                    if cert:
                        subject = _format_name(cert.get("subject", ()))
                        issuer = _format_name(cert.get("issuer", ()))
                        print(f"  subject : {subject}")
                        print(f"  issuer  : {issuer}")
                        print(
                            f"  valid   : {cert.get('notBefore', '?')} "
                            f"→ {cert.get('notAfter', '?')}"
                        )
                        if der:
                            print(f"  sha1    : {hashlib.sha1(der).hexdigest()}")
        finally:
            sock.close()

        http_start = time.monotonic()
        request = urllib.request.Request(url, headers={"User-Agent": _USER_AGENT})
        redirect_handler = _CountingRedirectHandler()
        opener = urllib.request.build_opener(redirect_handler)
        try:
            response = opener.open(request, timeout=_NETWORK_TIMEOUT)
        except urllib.error.HTTPError as error:
            # unlike Dart's HttpClient, urllib raises on 4xx/5xx instead of
            # returning them as a normal response -- HTTPError is itself a
            # response-like object (status/reason/headers/read()), so route
            # it through the same stats printing rather than a separate,
            # thinner error path.
            response = error
        try:
            body = response.read()
            http_elapsed = time.monotonic() - http_start
            status = response.status
            reason = response.reason
            headers = response.headers.items()
        finally:
            response.close()

        print(f"[HTTP] {_format_duration(http_elapsed)}")
        print(f"  status   : {status} {reason}")
        print(f"  redirects: {redirect_handler.redirect_count}")
        print(f"  bytes    : {len(body)} ({_format_bytes(len(body))})")
        for name, value in headers:
            print(f"  <{name}: {value}")

        return 1 if status >= 400 else 0
    except (TimeoutError, socket.timeout) as error:
        print(f"Probe timed out after {int(_NETWORK_TIMEOUT)}s: {error}", file=sys.stderr)
        return 1
    except Exception as error:  # noqa: BLE001 -- mirrors the Dart `on Object catch`
        print(f"Probe failed: {error}", file=sys.stderr)
        return 1


def main(argv: list[str] | None = None) -> int:
    args = sys.argv[1:] if argv is None else argv
    if not args or args[0] in ("--help", "-h"):
        print("Usage: python3 tool/python/net_probe.py <http-or-https-url>")
        print("Shows DNS, TCP, TLS (HTTPS), HTTP status/headers, bytes, and timings.")
        return 0
    return run(args[0])


if __name__ == "__main__":
    raise SystemExit(main())
