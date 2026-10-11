"""Real local HTTP input and validation integration contract."""
import importlib.util
import json
import socket
import time
from pathlib import Path
from threading import Thread
from urllib.request import Request, urlopen
from urllib.error import HTTPError
from http.server import ThreadingHTTPServer

import pytest

BASE = Path(__file__).resolve().parents[1]
import sys
sys.path.insert(0, str(BASE))
from validation_http import Handler


@pytest.fixture
def server():
    http = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    worker = Thread(target=http.serve_forever, daemon=True)
    worker.start()
    try:
        yield f"http://127.0.0.1:{http.server_port}"
    finally:
        http.shutdown()
        worker.join(timeout=5)
        http.server_close()


def test_browser_form_is_served(server):
    with urlopen(server) as response:
        body = response.read().decode("utf-8")
    assert 'id="value"' in body and 'id="run"' in body
    assert "fetch('/validate'" in body


def test_form_submission_uses_actual_python_validator(server):
    request = Request(server + "/validate", method="POST",
                      data=json.dumps({"operation": "email", "value": "a@example.org"}).encode(),
                      headers={"Content-Type": "application/json", "Origin": "http://localhost:8080"})
    with urlopen(request) as response:
        assert json.load(response) == {"valid": True}


def test_bad_payload_fails_closed(server):
    request = Request(server + "/validate", method="POST", data=b'{"operation":"missing"}',
                      headers={"Content-Type": "application/json"})
    with pytest.raises(HTTPError) as error:
        urlopen(request)
    assert error.value.code == 400


def _post(url, body, **headers):
    return Request(url + "/validate", method="POST", data=body,
                   headers={"Content-Type": "application/json", **headers})


def test_same_origin_form_post_is_accepted(server):
    # Browsers send Origin on same-origin POSTs; the served form must work.
    with urlopen(_post(server, json.dumps({"operation": "email", "value": "x"}).encode(),
                       Origin=server)) as response:
        assert json.load(response) == {"valid": False}


@pytest.mark.parametrize("headers", [
    {"Origin": "http://evil.example"},
    {"Host": "evil.example"},  # DNS rebinding to 127.0.0.1
])
def test_foreign_origin_or_host_is_rejected(server, headers):
    with pytest.raises(HTTPError) as error:
        urlopen(_post(server, b'{"operation":"required","value":"x"}', **headers))
    assert error.value.code == 403


def test_deeply_nested_payload_fails_closed(server):
    with pytest.raises(HTTPError) as error:
        urlopen(_post(server, b"[" * 60000))
    assert error.value.code == 400


@pytest.mark.parametrize("body", [
    b"{not json",                      # malformed JSON
    b"x" * 65537,                      # over the 64 KiB limit
    b'{"operation":"range","value":' + b"9" * 401 + b',"options":{"minimum":0,"maximum":1}}',
])
def test_abnormal_bodies_get_a_response_not_a_dropped_connection(server, body):
    if len(body) > 65536:
        with pytest.raises(HTTPError) as error:
            urlopen(_post(server, body))
        assert error.value.code == 400
        return
    try:
        with urlopen(_post(server, body)) as response:
            assert response.status == 200 and json.load(response) == {"valid": False}
    except HTTPError as error:
        assert error.code == 400


def test_client_that_never_sends_its_body_is_dropped(server, monkeypatch):
    monkeypatch.setattr(Handler, "timeout", 0.5)
    port = int(server.rsplit(":", 1)[1])
    with socket.create_connection(("127.0.0.1", port), timeout=5) as client:
        client.sendall(b"POST /validate HTTP/1.1\r\nHost: 127.0.0.1:%d\r\n"
                       b"Content-Type: application/json\r\nContent-Length: 10\r\n\r\n" % port)
        started = time.monotonic()
        assert client.recv(1024) == b""  # server closed the connection
        assert time.monotonic() - started < 4
