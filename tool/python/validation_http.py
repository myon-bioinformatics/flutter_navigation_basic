#!/usr/bin/env python3
"""Opt-in local HTTP bridge for the 091-099 Python validation producer.

Run separately: python3 -S tool/python/validation_http.py --port 8765
Bind loopback only; do not expose this development endpoint publicly.
"""
from __future__ import annotations

import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from validation_patterns import run


class Handler(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(204)
        self._headers()
        self.end_headers()

    def _headers(self):
        self.send_header("Access-Control-Allow-Origin", "http://localhost:8080")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Cache-Control", "no-store")

    def do_POST(self):
        if self.path != "/validate":
            self.send_error(404)
            return
        origin = self.headers.get("Origin")
        if origin and origin != "http://localhost:8080":
            self.send_error(403)
            return
        try:
            size = int(self.headers.get("Content-Length", "0"))
            if not 0 < size <= 65536:
                raise ValueError("invalid request size")
            payload = json.loads(self.rfile.read(size))
            result = run(payload)
            body = json.dumps(result, ensure_ascii=False).encode()
            status = 200
        except (ValueError, TypeError, UnicodeError, KeyError):
            body = b'{"error":"invalid validation request"}'
            status = 400
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self._headers()
        self.end_headers()
        self.wfile.write(body)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8765)
    args = parser.parse_args()
    ThreadingHTTPServer(("127.0.0.1", args.port), Handler).serve_forever()


if __name__ == "__main__":
    main()
