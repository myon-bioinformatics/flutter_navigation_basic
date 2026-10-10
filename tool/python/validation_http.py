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


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
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
   const data = await response.json(); output.textContent = JSON.stringify({http_status:response.status,...data},null,2);
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
