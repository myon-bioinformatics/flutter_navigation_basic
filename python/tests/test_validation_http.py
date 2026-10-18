"""Real local HTTP input and validation integration contract."""
import json
import socket
import time
from contextlib import contextmanager
from pathlib import Path
from threading import Thread
from functools import partial
from urllib.request import Request, urlopen as _urlopen

# fetch-guard: a stuck local server fails the test in 10 s instead of hanging the CI job.
urlopen = partial(_urlopen, timeout=10)
from urllib.error import HTTPError
from http.server import ThreadingHTTPServer

import pytest

BASE = Path(__file__).resolve().parents[1]
import sys
sys.path.insert(0, str(BASE))
from validation_http import Handler, build_server


@contextmanager
def running(origins=None):
    http = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    if origins is not None:
        http.allowed_origins = frozenset(origins)
    worker = Thread(target=http.serve_forever, daemon=True)
    worker.start()
    try:
        assert http.server_address[0] == "127.0.0.1"
        yield f"http://127.0.0.1:{http.server_port}"
    finally:
        http.shutdown()
        worker.join(timeout=5)
        http.server_close()


@pytest.fixture
def server():
    with running() as url:
        yield url


def test_browser_form_is_served(server):
    with urlopen(server) as response:
        body = response.read().decode("utf-8")
    assert 'id="value"' in body and 'id="run"' in body
    assert "fetch('/validate'" in body
    assert "textContent" in body and "innerHTML" not in body
    assert "submitted:value" in body


def test_form_submission_uses_actual_python_validator(server):
    request = Request(server + "/validate", method="POST",
                      data=json.dumps({"operation": "email", "value": "a@example.org"}).encode(),
                      headers={"Content-Type": "application/json", "Origin": "http://localhost:8080"})
    with urlopen(request) as response:
        assert json.load(response) == {"valid": True}
        assert response.headers["Access-Control-Allow-Origin"] == "http://localhost:8080"
        assert "*" not in response.headers["Access-Control-Allow-Origin"]


def test_bad_payload_fails_closed(server):
    request = Request(server + "/validate", method="POST", data=b'{"operation":"missing"}',
                      headers={"Content-Type": "application/json"})
    with pytest.raises(HTTPError) as error:
        urlopen(request)
    assert error.value.code == 400
    assert json.loads(error.value.read()) == {"error": "invalid validation request"}


def _post(url, body, **headers):
    return Request(url + "/validate", method="POST", data=body,
                   headers={"Content-Type": "application/json", **headers})


@pytest.mark.parametrize("origin_host", ["127.0.0.1", "localhost"])
def test_same_origin_form_post_is_accepted(server, origin_host):
    # Browsers send Origin on same-origin POSTs; the served form must work.
    # 127.0.0.1 and localhost are the same loopback origin for the bound port.
    port = server.rsplit(":", 1)[1]
    origin = f"http://{origin_host}:{port}"
    with urlopen(_post(server, json.dumps({"operation": "email", "value": "x"}).encode(),
                       Origin=origin)) as response:
        assert json.load(response) == {"valid": False}
        assert response.headers["Access-Control-Allow-Origin"] == origin


def test_localhost_host_header_is_accepted(server):
    port = int(server.rsplit(":", 1)[1])
    body = b'{"operation":"required","value":"ok"}'
    status, raw = _exchange(
        port,
        f"POST /validate HTTP/1.1\r\nHost: localhost:{port}\r\n"
        f"Origin: http://localhost:{port}\r\nContent-Type: application/json\r\n"
        f"Content-Length: {len(body)}\r\n\r\n",
        body,
    )
    assert status == 200
    assert json.loads(raw) == {"valid": True}


@pytest.mark.parametrize("headers", [
    {"Origin": "http://evil.example"},
    {"Host": "evil.example"},  # DNS rebinding to 127.0.0.1
])
def test_foreign_origin_or_host_is_rejected(server, headers):
    with pytest.raises(HTTPError) as error:
        urlopen(_post(server, b'{"operation":"required","value":"x"}', **headers))
    assert error.value.code == 403
    assert error.value.headers.get_content_type() == "application/json"
    assert error.value.headers.get("Access-Control-Allow-Origin") is None
    assert json.loads(error.value.read()) == {"error": "origin not allowed"}


def test_extra_origins_are_an_explicit_allowlist():
    with running(origins=frozenset({"http://127.0.0.1:9"})) as url:
        with pytest.raises(HTTPError) as error:
            urlopen(_post(url, b'{"operation":"required","value":"x"}',
                          Origin="http://localhost:8080"))
        assert error.value.code == 403
        with urlopen(_post(url, b'{"operation":"required","value":"x"}',
                           Origin="http://127.0.0.1:9")) as response:
            assert response.status == 200
        with urlopen(_post(url, b'{"operation":"required","value":"x"}',
                           Origin=url)) as response:
            assert response.status == 200


def test_server_binds_loopback_and_defaults_the_flutter_origin():
    http = build_server(["--port", "0"])
    try:
        assert http.server_address[0] == "127.0.0.1"
        assert http.allowed_origins == frozenset({"http://localhost:8080"})
    finally:
        http.server_close()


def test_allow_origin_flag_replaces_the_default():
    http = build_server(["--port", "0", "--allow-origin", "http://127.0.0.1:9",
                         "--allow-origin", "https://localhost:8443"])
    try:
        assert http.allowed_origins == frozenset({
            "http://127.0.0.1:9", "https://localhost:8443"})
    finally:
        http.server_close()


def test_wildcard_allow_origin_is_rejected():
    with pytest.raises(SystemExit):
        build_server(["--port", "0", "--allow-origin", "*"])


def test_deeply_nested_payload_fails_closed(server):
    with pytest.raises(HTTPError) as error:
        urlopen(_post(server, b"[" * 60000))
    assert error.value.code == 400
    assert json.loads(error.value.read()) == {"error": "invalid validation request"}


def test_bad_json_is_400(server):
    with pytest.raises(HTTPError) as error:
        urlopen(_post(server, b"{not json"))
    assert error.value.code == 400
    assert json.loads(error.value.read()) == {"error": "invalid validation request"}


def test_oversized_body_is_400(server):
    with pytest.raises(HTTPError) as error:
        urlopen(_post(server, b"x" * 65537))
    assert error.value.code == 400
    assert json.loads(error.value.read()) == {"error": "invalid validation request"}


def test_huge_integer_is_answered(server):
    body = (b'{"operation":"range","value":' + b"9" * 401
            + b',"options":{"minimum":0,"maximum":1}}')
    with urlopen(_post(server, body)) as response:
        assert response.status == 200
        assert json.load(response) == {"valid": False}


@pytest.mark.parametrize("length", ["0", "-1"])
def test_content_length_zero_or_negative_is_400(server, length):
    port = int(server.rsplit(":", 1)[1])
    status, raw = _exchange(
        port,
        f"POST /validate HTTP/1.1\r\nHost: 127.0.0.1:{port}\r\n"
        f"Content-Type: application/json\r\nContent-Length: {length}\r\n\r\n",
    )
    assert status == 400
    assert json.loads(raw) == {"error": "invalid validation request"}


def test_stalled_body_gets_408(server, monkeypatch):
    monkeypatch.setattr(Handler, "timeout", 0.5)
    port = int(server.rsplit(":", 1)[1])
    with socket.create_connection(("127.0.0.1", port), timeout=5) as client:
        client.sendall(b"POST /validate HTTP/1.1\r\nHost: 127.0.0.1:%d\r\n"
                       b"Content-Type: application/json\r\nContent-Length: 10\r\n\r\n" % port)
        started = time.monotonic()
        data = b""
        while True:
            chunk = client.recv(4096)
            if not chunk:
                break
            data += chunk
    assert time.monotonic() - started < 4
    status = int(data.split(b" ", 2)[1])
    assert status == 408
    _head, _, raw = data.partition(b"\r\n\r\n")
    assert json.loads(raw) == {"error": "request timed out"}


def _exchange(port, head, body=b""):
    with socket.create_connection(("127.0.0.1", port), timeout=5) as client:
        client.sendall(head.encode() + body)
        client.shutdown(socket.SHUT_WR)
        data = b""
        while True:
            chunk = client.recv(8192)
            if not chunk:
                break
            data += chunk
    status = int(data.split(b" ", 2)[1])
    _head, _, raw = data.partition(b"\r\n\r\n")
    return status, raw


def test_non_json_media_type_returns_415(server):
    request = Request(server + "/validate", method="POST",
                      data=b'{"operation":"required","value":"x"}',
                      headers={"Content-Type": "text/plain"})
    with pytest.raises(HTTPError) as error:
        urlopen(request)
    assert error.value.code == 415
    assert json.loads(error.value.read()) == {"error": "unsupported media type"}


@pytest.mark.parametrize("method", ["PUT", "PATCH", "DELETE", "HEAD"])
def test_unsupported_methods_return_405_and_allow(server, method):
    request = Request(server + "/validate", method=method)
    with pytest.raises(HTTPError) as error:
        urlopen(request)
    assert error.value.code == 405
    assert error.value.headers["Allow"] == "GET, POST, OPTIONS"


def test_occupied_port_has_actionable_error():
    with running() as url:
        port = url.rsplit(":", 1)[1]
        with pytest.raises(SystemExit) as error:
            build_server(["--port", port])
        assert error.value.code == 2
