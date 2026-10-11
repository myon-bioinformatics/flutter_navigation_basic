#!/usr/bin/env python3
"""Serve a Flutter web build and its local-only Python curl import endpoint.

Development/CI adapter, not a production HTTP server or a proxy. Request text
is parsed in-process by curl_request; no curl, shell, file import or outbound
request is executed. Bind and accepted Host/Origin are deliberately loopback-only.
"""
from __future__ import annotations

import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import socket
import sys
import threading

from curl_request import MAX_INPUT_BYTES, parse_curl

ENDPOINT = "/__runtime__/curl-import"
SCHEMA = "curl-runtime/1"
MAX_REPLY_BYTES = 1_048_576


class RuntimeServer(ThreadingHTTPServer):
    daemon_threads = True
    request_queue_size = 8

    def __init__(self, root: Path, port: int = 0):
        self.root = root.resolve(strict=True)
        index = self.root / "index.html"
        if not index.is_file() or not index.resolve().is_relative_to(self.root):
            raise ValueError("web root must contain index.html")
        self._slots = threading.BoundedSemaphore(8)
        super().__init__(("127.0.0.1", port), partial(RuntimeHandler, directory=str(self.root)))
        self.origin = f"http://127.0.0.1:{self.server_port}"
        self.host_header = f"127.0.0.1:{self.server_port}"

    def process_request(self, request, client_address):
        if not self._slots.acquire(blocking=False):
            self.shutdown_request(request)
            return
        try:
            super().process_request(request, client_address)
        except BaseException:
            self._slots.release()
            raise

    def process_request_thread(self, request, client_address):
        try:
            super().process_request_thread(request, client_address)
        finally:
            self._slots.release()

    def handle_error(self, request, client_address):
        # Never interpolate request data, paths or credentials into logs.
        print("curl-runtime: request failed", file=sys.stderr)


class RuntimeHandler(SimpleHTTPRequestHandler):
    server_version = "CurlRuntime"
    sys_version = ""
    request_timeout = 5.0

    def setup(self):
        super().setup()
        self.connection.settimeout(self.request_timeout)

    def log_message(self, format, *args):
        # Successful parsed data can contain secrets. No access/body logs.
        pass

    def _host_ok(self):
        return self.headers.get_all("Host", []) == [self.server.host_header]

    def _reply(self, status, payload):
        data = json.dumps(payload, ensure_ascii=True, separators=(",", ":")).encode("utf-8")
        if len(data) > MAX_REPLY_BYTES:
            status, data = 500, b'{"schema":"curl-runtime/1","error":"replyTooLarge"}'
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("X-Curl-Runtime", "python")
        self.send_header("Connection", "close")
        self.end_headers()
        self.close_connection = True
        self.wfile.write(data)

    def _error(self, status, code):
        self._reply(status, {"schema": SCHEMA, "error": code})

    def do_POST(self):
        if not self._host_ok():
            return self._error(403, "host")
        if self.path != ENDPOINT:
            return self._error(404, "path")
        if (self.headers.get_all("Origin", []) != [self.server.origin] or
                self.headers.get_all("X-Curl-Runtime", []) != ["1"]):
            return self._error(403, "origin")
        if self.headers.get_content_type() != "text/plain":
            return self._error(415, "contentType")
        lengths = self.headers.get_all("Content-Length", [])
        if self.headers.get_all("Transfer-Encoding") or len(lengths) != 1:
            return self._error(400, "framing")
        if not lengths[0].isascii() or not lengths[0].isdecimal():
            return self._error(400, "length")
        # Avoid converting a thousands-of-digits integer supplied in a header.
        if len(lengths[0]) > 6 or int(lengths[0]) > MAX_INPUT_BYTES:
            return self._error(413, "inputTooLarge")
        length = int(lengths[0])
        try:
            data = self.rfile.read(length)
            if len(data) != length:
                return self._error(400, "incomplete")
            raw = data.decode("utf-8", errors="strict")
        except (TimeoutError, socket.timeout):
            return self._error(408, "timeout")
        except UnicodeError:
            return self._error(400, "encoding")
        self._reply(200, {"schema": SCHEMA, "result": parse_curl(raw)})

    def do_OPTIONS(self):
        # No CORS opt-in; other origins may not call this local runtime.
        self._error(403, "origin")

    def send_head(self):
        if not self._host_ok():
            self.send_error(403)
            return None
        if self.path.startswith("/__runtime__/"):
            self.send_error(405)
            return None
        candidate = Path(self.translate_path(self.path)).resolve()
        if not candidate.is_relative_to(self.server.root):
            self.send_error(403)
            return None
        if candidate.is_dir():
            for name in ("index.html", "index.htm"):
                index = candidate / name
                if index.exists() and not index.resolve().is_relative_to(self.server.root):
                    self.send_error(403)
                    return None
        return super().send_head()

    def list_directory(self, path):
        self.send_error(404)
        return None


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--web-root", type=Path, required=True)
    parser.add_argument("--port", type=int, default=8080)
    args = parser.parse_args(argv)
    if not 0 <= args.port <= 65535:
        parser.error("port must be between 0 and 65535")
    try:
        server = RuntimeServer(args.web_root, args.port)
    except (OSError, ValueError):
        parser.error("cannot open web root or bind local runtime")
    print(f"curl-runtime: {server.origin}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
