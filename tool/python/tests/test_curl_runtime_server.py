"""Real loopback HTTP tests; no browser, external network or subprocess curl."""
from contextlib import contextmanager
from http.client import HTTPConnection
import json
from pathlib import Path
import socket
import subprocess
import sys
import threading

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from curl_request import parse_curl
from curl_runtime_server import ENDPOINT, RuntimeHandler, RuntimeServer


@pytest.fixture
def runtime(tmp_path):
    root = tmp_path / "web"
    root.mkdir()
    (root / "index.html").write_text("<html>test web root</html>", encoding="utf-8")
    server = RuntimeServer(root)
    thread = threading.Thread(target=server.serve_forever, kwargs={"poll_interval": .01})
    thread.start()
    yield server
    server.shutdown()
    thread.join(timeout=2)
    server.server_close()
    assert not thread.is_alive()


@contextmanager
def connection(server):
    client = HTTPConnection("127.0.0.1", server.server_port, timeout=2)
    try:
        yield client
    finally:
        client.close()


def post(server, body=b"curl https://example.test", *, headers=None, path=ENDPOINT):
    fields = {"Origin": server.origin, "X-Curl-Runtime": "1", "Content-Type": "text/plain; charset=utf-8"}
    fields.update(headers or {})
    with connection(server) as client:
        client.request("POST", path, body=body, headers=fields)
        response = client.getresponse()
        return response.status, dict(response.getheaders()), response.read()


@pytest.mark.parametrize("raw", [
    "curl https://example.test/runtime-live",
    "curl -G https://example.test --data 'tag=a&tag=b&blank='",
    "curl https://example.test -H 'Content-Type: application/json' -d '{\"猫\":1}'",
    "curl https://example.test -u synthetic:credential",
    "curl https://example.test -d @forbidden-file",
    "curl https://example.test ; echo forbidden",
    "curl https://example.test --config rejected",
    "curl https://example.test -G -d 'q=%FF'",
    "",
])
def test_live_endpoint_uses_canonical_parser(runtime, raw):
    status, headers, body = post(runtime, raw.encode("utf-8"))
    assert status == 200
    assert headers["X-Curl-Runtime"] == "python"
    assert headers["Cache-Control"] == "no-store"
    assert "Access-Control-Allow-Origin" not in headers
    payload = json.loads(body)
    assert payload["schema"] == "curl-runtime/1"
    assert payload["result"] == parse_curl(raw)


@pytest.mark.parametrize("headers,status,code", [
    ({"Origin": "https://untrusted.test"}, 403, "origin"),
    ({"Origin": "null"}, 403, "origin"),
    ({"X-Curl-Runtime": "wrong"}, 403, "origin"),
    ({"Host": "untrusted.test"}, 403, "host"),
    ({"Content-Type": "application/json"}, 415, "contentType"),
    ({"Transfer-Encoding": "chunked"}, 400, "framing"),
    ({"Content-Length": "-1"}, 400, "length"),
    ({"Content-Length": "bad"}, 400, "length"),
    ({"Content-Length": "65537"}, 413, "inputTooLarge"),
    ({"Content-Length": "9" * 5000}, 413, "inputTooLarge"),
])
def test_request_contract_rejects_before_parsing(runtime, headers, status, code):
    actual, _, body = post(runtime, headers=headers)
    assert actual == status
    assert json.loads(body)["error"] == code


@pytest.mark.parametrize("missing", ["Origin", "X-Curl-Runtime", "Content-Length"])
def test_required_headers_are_not_implicit(runtime, missing):
    headers = {"Host": runtime.host_header, "Origin": runtime.origin,
               "X-Curl-Runtime": "1", "Content-Type": "text/plain", "Content-Length": "0"}
    headers.pop(missing)
    with connection(runtime) as client:
        client.putrequest("POST", ENDPOINT, skip_host=True)
        for name, value in headers.items():
            client.putheader(name, value)
        client.endheaders()
        response = client.getresponse()
        assert response.status in (400, 403)
        response.read()


@pytest.mark.parametrize("duplicate", ["Host", "Origin", "X-Curl-Runtime", "Content-Length"])
def test_ambiguous_duplicate_headers_are_rejected(runtime, duplicate):
    headers = {"Host": runtime.host_header, "Origin": runtime.origin,
               "X-Curl-Runtime": "1", "Content-Type": "text/plain", "Content-Length": "0"}
    with connection(runtime) as client:
        client.putrequest("POST", ENDPOINT, skip_host=True)
        for name, value in headers.items():
            client.putheader(name, value)
        client.putheader(duplicate, headers[duplicate])
        client.endheaders()
        response = client.getresponse()
        assert response.status in (400, 403)
        response.read()


def test_bad_encoding_oversize_and_path(runtime):
    assert post(runtime, b"\xff")[0] == 400
    assert post(runtime, b"a" * 65537)[0] == 413
    assert post(runtime, path=ENDPOINT + "?wrong=1")[0] == 404


def test_preflight_is_not_enabled(runtime):
    with connection(runtime) as client:
        client.request("OPTIONS", ENDPOINT, headers={"Origin": "https://untrusted.test"})
        response = client.getresponse()
        assert response.status == 403
        assert response.getheader("Access-Control-Allow-Origin") is None
        response.read()


def test_partial_body_times_out_without_echo(runtime, monkeypatch):
    monkeypatch.setattr(RuntimeHandler, "request_timeout", .1)
    with connection(runtime) as client:
        client.putrequest("POST", ENDPOINT)
        for name, value in {"Origin": runtime.origin, "X-Curl-Runtime": "1",
                            "Content-Type": "text/plain", "Content-Length": "100"}.items():
            client.putheader(name, value)
        client.endheaders(b"synthetic-secret")
        response = client.getresponse()
        assert response.status == 408
        body = response.read()
        assert b"synthetic-secret" not in body
        assert json.loads(body)["error"] == "timeout"


def test_partial_body_eof_is_invalid(runtime):
    with connection(runtime) as client:
        client.putrequest("POST", ENDPOINT)
        for name, value in {"Origin": runtime.origin, "X-Curl-Runtime": "1",
                            "Content-Type": "text/plain", "Content-Length": "100"}.items():
            client.putheader(name, value)
        client.endheaders(b"short")
        client.sock.shutdown(socket.SHUT_WR)
        response = client.getresponse()
        assert response.status == 400
        assert json.loads(response.read())["error"] == "incomplete"


def test_only_web_root_is_served_and_no_directory_listing(runtime, tmp_path):
    secret = tmp_path / "outside.txt"
    secret.write_text("OUTSIDE-SENTINEL", encoding="utf-8")
    (runtime.root / "leak.txt").symlink_to(secret)
    (runtime.root / "folder").mkdir()
    (runtime.root / "index-link").mkdir()
    (runtime.root / "index-link/index.html").symlink_to(secret)
    for path, expected in [("/", 200), ("/folder/", 404), ("/leak.txt", 403), ("/index-link/", 403), (ENDPOINT, 405)]:
        with connection(runtime) as client:
            client.request("GET", path)
            response = client.getresponse()
            assert response.status == expected
            assert b"OUTSIDE-SENTINEL" not in response.read()


def test_success_and_rejection_do_not_log_credentials(runtime, capsys):
    post(runtime, b"curl https://example.test -u synthetic:DO-NOT-LOG")
    post(runtime, b"curl https://example.test -d @DO-NOT-LOG")
    captured = capsys.readouterr()
    assert "DO-NOT-LOG" not in captured.out + captured.err


def test_cli_requires_valid_build_directory(tmp_path):
    runner = Path(__file__).resolve().parents[1] / "curl_runtime_server.py"
    result = subprocess.run([sys.executable, "-S", str(runner), "--web-root", str(tmp_path)],
                            capture_output=True, text=True, timeout=5)
    assert result.returncode == 2
    assert "cannot open web root" in result.stderr
