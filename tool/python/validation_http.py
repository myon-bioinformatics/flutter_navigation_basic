#!/usr/bin/env python3
"""Opt-in local HTTP bridge for the 091-099 Python validation producer.

Run separately: python3 -S tool/python/validation_http.py --port 8765
Bind loopback only; do not expose this development endpoint publicly.
"""
from __future__ import annotations

import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from html import escape
from validation_patterns import run


OPERATIONS = ('required', 'email', 'password', 'phone', 'url', 'date', 'range', 'regex', 'form')
FLUTTER_DEV_ORIGIN = "http://localhost:8080"


class Handler(BaseHTTPRequestHandler):
    # Socket read timeout: a client that never sends its body is dropped instead
    # of holding a worker forever (http.server closes on TimeoutError).
    timeout = 10

    def _loopback_names(self):
        port = self.server.server_address[1]
        return {f"127.0.0.1:{port}", f"localhost:{port}"}

    def _trusted(self):
        """Reject DNS-rebinding hosts and foreign origins.

        The form is served from this server itself, and browsers send Origin on
        same-origin POSTs too, so this server's own origin must be accepted.
        """
        if self.headers.get("Host") not in self._loopback_names():
            return False
        origin = self.headers.get("Origin")
        return origin is None or origin == FLUTTER_DEV_ORIGIN or origin in {
            "http://" + name for name in self._loopback_names()}

    def do_GET(self):
        if not self._trusted():
            self.send_error(403)
            return
        if self.path != '/':
            self.send_error(404)
            return
        options = ''.join(f'<option value="{escape(op)}">{escape(op)}</option>' for op in OPERATIONS)
        body = ('''<!doctype html><html lang="ja"><meta charset="utf-8"><title>Validation 091-099</title>
<h1>Validation 091–099 (Python)</h1><p>ローカル検証デモ。セキュリティ上の保証はありません。</p>
<label>検証種別 <select id="op">''' + options + '''</select></label>
<label>入力 <input id="value" autocomplete="off"></label>
<button id="run">検証</button><pre id="result" role="status"></pre>
<script>
const output = document.getElementById('result');
document.getElementById('run').addEventListener('click', async () => {
 const operation = document.getElementById('op').value;
 const value = document.getElementById('value').value;
 let payload = {operation, value};
 if (operation === 'range') payload = {operation, value: Number(value), options:{minimum:0,maximum:100}};
 if (operation === 'regex') payload.options = {pattern:'ascii_identifier'};
 if (operation === 'form') payload = {operation, fields:[{name:'required',rule:'required',value}]};
 try { const response = await fetch('/validate',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(payload)});
   const text = await response.text(); let data;
   try { data = JSON.parse(text); } catch { data = {error: 'non-JSON response'}; }
   output.textContent = JSON.stringify({http_status:response.status,...data},null,2);
 } catch (error) { output.textContent = '通信エラー: '+String(error); }
});
</script></html>''').encode('utf-8')
        self.send_response(200)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(204)
        self._headers()
        self.end_headers()

    def _headers(self):
        self.send_header("Access-Control-Allow-Origin", FLUTTER_DEV_ORIGIN)
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Cache-Control", "no-store")

    def do_POST(self):
        if self.path != "/validate":
            self.send_error(404)
            return
        if not self._trusted():
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
        except (ValueError, TypeError, UnicodeError, KeyError, RecursionError, OverflowError):
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
