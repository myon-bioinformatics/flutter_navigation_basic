import json
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
VENDOR = ROOT / "python/vendor"

MODULES = (
    "yourself.py",
    "xprobe.py",
    "gh_ops.py",
    "check_evidence.py",
    "check_png.py",
    "jsonl_digest.py",
    "cli_args.py",
    "gh_identity.py",
)


@pytest.mark.parametrize("name", MODULES)
def test_shared_toolkit_compiles_and_imports_standalone(name):
    path = VENDOR / name
    subprocess.run([sys.executable, "-m", "py_compile", str(path)], check=True)
    subprocess.run(
        [sys.executable, "-S", "-c",
         "import sys; sys.path.insert(0, r'" + str(VENDOR) + "'); __import__('" + name[:-3] + "')"],
        check=True,
        cwd=ROOT,
    )


def test_environment_probe_is_safe_no_argument_json():
    result = subprocess.run(
        [sys.executable, "-S", str(VENDOR / "yourself.py"), "--minimal", "--format", "json"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=10,
    )
    assert result.returncode == 0, result.stderr
    payload = json.loads(result.stdout)
    assert payload["schema_version"] == 1
    assert set(payload) == {"schema_version", "os", "runtime", "host", "directory"}


def test_gh_identity_local_contract_prefers_github_environment():
    sys.path.insert(0, str(VENDOR))
    import gh_identity
    value = gh_identity.local_identity(env={
        "GITHUB_SHA": "A" * 40,
        "GITHUB_HEAD_REF": "feature/runtime",
    })
    assert value["schema"] == "gh-identity-local/1"
    assert value["sha"] == "a" * 40
    assert value["ref"] == "feature/runtime"
    assert value["source"] == "github-env"


def test_gh_identity_provides_the_git_inspection_api_that_replaced_git_inspector():
    sys.path.insert(0, str(VENDOR))
    import gh_identity
    for name in ("status", "ls_files", "diff", "log", "log_numstat", "show", "blame", "grep", "check_ignore"):
        assert callable(getattr(gh_identity, "git_" + name)), name
    observed = gh_identity.git_status(ROOT)
    assert isinstance(observed, dict)


def _load_exact_vendor(name):
    import importlib.util
    path = VENDOR / (name + '.py')
    spec = importlib.util.spec_from_file_location('_flutter_vendor_' + name, path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    assert Path(module.__file__).resolve() == path.resolve()
    return module


@pytest.mark.parametrize('explicit', [True, False])
def test_adopted_xprobe_rejects_node25_with_precise_diagnostic(monkeypatch, explicit):
    import shutil
    module = _load_exact_vendor('xprobe')
    calls = []
    def version_probe(argv, **kwargs):
        calls.append(argv)
        assert argv[-1] == '--version'
        return subprocess.CompletedProcess(argv, 0, b'v25.0.0\n', b'')
    monkeypatch.setattr(subprocess, 'run', version_probe)
    monkeypatch.setattr(shutil, 'which', lambda name: sys.executable if name == 'node' else None)
    with pytest.raises(RuntimeError, match=r'needs Node 26\+.*found Node 25'):
        module.load_yaml('key: value', node=sys.executable if explicit else None)
    assert calls


def test_adopted_cli_args_rejects_node25(monkeypatch):
    module = _load_exact_vendor('cli_args')
    calls = []
    def version_probe(argv, **kwargs):
        calls.append(argv)
        assert argv[-1] == '--version'
        return subprocess.CompletedProcess(argv, 0, b'v25.0.0\n', b'')
    monkeypatch.setattr(subprocess, 'run', version_probe)
    with pytest.raises(module.NodeNotFoundError, match=r'26.*25'):
        module.resolve_node(sys.executable)
    assert calls
