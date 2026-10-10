"""Exercise Docker entrypoint orchestration with explicit fake tool processes.

This does not claim a local Docker/Flutter run: the real browser/server chain is
covered by curl-runtime.yml. These tests preserve routing, cleanup and exit codes.
"""
from pathlib import Path
import json
import os
import subprocess
import sys

import pytest

ROOT = Path(__file__).resolve().parents[3]
ENTRYPOINT = ROOT / "tool/docker/e2e-entrypoint.sh"


def _fixture(tmp_path, mode, test_exit=0, deno_exit=0):
    fakebin = tmp_path / "bin"
    fakebin.mkdir()
    (tmp_path / "e2e").mkdir()
    driver = "#!" + sys.executable + " -S\n" + '''
from pathlib import Path
import json, os, signal, sys, time
root = Path(os.environ["E2E_REPO_ROOT"])
name = Path(sys.argv[0]).name
args = sys.argv[1:]
if name == "python3" and "tool/python/vendor/yourself.py" in args:
    print(json.dumps({"fixture": True}))
elif name == "python3" and ("tool/python/curl_runtime_server.py" in args or "http.server" in args):
    (root / "server.json").write_text(json.dumps({"pid": os.getpid(), "args": args}))
    signal.pause()
elif name == "python3" and "tool/python/playwright.py" in args:
    (root / "runner.json").write_text(json.dumps({"args": args, "mode": os.environ.get("CURL_RUNTIME_E2E")}))
    print("fixture native runner")
    raise SystemExit(int(os.environ["FIXTURE_EXIT"]))
elif name == "curl":
    raise SystemExit(0 if (root / "server.json").exists() else 22)
elif name == "sleep":
    time.sleep(0.01)
else:
    print(name + " fixture-version")
    if name == "deno":
        raise SystemExit(int(os.environ["FIXTURE_DENO_EXIT"]))
'''
    for name in ("python3", "curl", "sleep", "node", "npm", "npx", "deno"):
        command = fakebin / name
        command.write_text(driver, encoding="utf-8")
        command.chmod(0o755)
    env = dict(os.environ, E2E_REPO_ROOT=str(tmp_path), CURL_RUNTIME_E2E=mode,
               FIXTURE_EXIT=str(test_exit), FIXTURE_DENO_EXIT=str(deno_exit),
               PATH=str(fakebin) + os.pathsep + os.environ["PATH"])
    return env


@pytest.mark.skipif(os.name != "posix", reason="Docker entrypoint is Linux/Bash")
@pytest.mark.parametrize("mode,expected_server", [("true", "curl_runtime_server.py"), ("1", "curl_runtime_server.py"), ("false", "http.server")])
@pytest.mark.parametrize("native_exit", [0, 7])
def test_entrypoint_keeps_native_exit_and_cleans_up(tmp_path, mode, expected_server, native_exit):
    env = _fixture(tmp_path, mode, native_exit)
    result = subprocess.run(["bash", str(ENTRYPOINT), "test", "tests/curl_runtime.spec.ts"],
                            env=env, capture_output=True, text=True, timeout=10)
    assert result.returncode == native_exit, result.stdout + result.stderr
    server = json.loads((tmp_path / "server.json").read_text())
    assert any(expected_server in arg for arg in server["args"])
    with pytest.raises(ProcessLookupError):
        os.kill(server["pid"], 0)
    runner = json.loads((tmp_path / "runner.json").read_text())
    assert runner["args"][-2:] == ["test", "tests/curl_runtime.spec.ts"]
    if mode != "false":
        assert runner["mode"] == "1"
        assert json.loads((tmp_path / "build/curl-runtime/environment.json").read_text())["fixture"]
        versions = (tmp_path / "build/curl-runtime/toolchain.log").read_text()
        assert all(tool + " fixture-version" in versions for tool in ("node", "npm", "npx", "deno"))
    else:
        assert not (tmp_path / "build/curl-runtime").exists()


@pytest.mark.skipif(os.name != "posix", reason="Docker entrypoint is Linux/Bash")
def test_required_runtime_tool_failure_is_not_hidden(tmp_path):
    result = subprocess.run(["bash", str(ENTRYPOINT), "test"],
                            env=_fixture(tmp_path, "1", deno_exit=9),
                            capture_output=True, text=True, timeout=10)
    assert result.returncode == 9
    assert not (tmp_path / "server.json").exists()
    assert not (tmp_path / "runner.json").exists()


@pytest.mark.skipif(os.name != "posix", reason="Docker entrypoint is Linux/Bash")
def test_invalid_runtime_selection_is_rejected(tmp_path):
    result = subprocess.run(["bash", str(ENTRYPOINT), "test"],
                            env=_fixture(tmp_path, "typo"),
                            capture_output=True, text=True, timeout=10)
    assert result.returncode == 2
    assert not (tmp_path / "runner.json").exists()


def test_shared_container_enrolls_deno_and_explicit_runtime_build():
    dockerfile = (ROOT / "Dockerfile.e2e").read_text()
    assert "FROM denoland/deno:bin-${DENO_VERSION}" in dockerfile
    assert "COPY --from=deno /deno /usr/local/bin/deno" in dockerfile
    assert "ARG NODE_MAJOR=22" in dockerfile
    assert "ARG CURL_PYTHON_RUNTIME=false" in dockerfile
    assert "--dart-define=CURL_PYTHON_RUNTIME=${CURL_PYTHON_RUNTIME}" in dockerfile
    assert "deno run --no-config --no-lock --no-remote tool/docker/toolchain_smoke.ts" in dockerfile
    assert "playwright install --with-deps chromium firefox webkit" in dockerfile


def test_runtime_workflow_tests_the_container_and_actual_page_changes():
    workflow = (ROOT / ".github/workflows/curl-runtime.yml").read_text()
    assert '"lib/features/http_request_draft/**"' in workflow
    assert '"tool/docker/**"' in workflow
    assert "file: Dockerfile.e2e" in workflow
    assert "build-args: CURL_PYTHON_RUNTIME=true" in workflow
    assert "docker run --rm --init --ipc=host" in workflow
    for project in ("chromium", "firefox", "webkit", "mobile-chromium", "mobile-webkit"):
        assert "--project " + project in workflow
    assert "--reporter=line,junit" in workflow
    assert "tool/python/vendor/check_png.py" in workflow
    assert "if: always()" in workflow
    assert "push: false" in workflow
    assert "docker.sock" not in workflow
