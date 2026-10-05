import importlib.util
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
VENDOR = ROOT / "tool/python/vendor"

MODULES = (
    "yourself.py",
    "xprobe.py",
    "git_inspector.py",
    "gh_ops.py",
    "check_evidence.py",
    "jsonl_digest.py",
    "cli_args.py",
)


def test_shared_toolkit_compiles_and_imports_standalone():
    for name in MODULES:
        path = VENDOR / name
        subprocess.run([sys.executable, "-m", "py_compile", str(path)], check=True)
        spec = importlib.util.spec_from_file_location("vendored_" + name[:-3], path)
        module = importlib.util.module_from_spec(spec)
        assert spec.loader is not None
        spec.loader.exec_module(module)


def test_environment_probe_is_safe_no_argument_json():
    result = subprocess.run(
        [sys.executable, "-S", str(VENDOR / "yourself.py"), "--minimal", "--format", "json"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=10,
    )
    assert result.returncode == 0, result.stderr
    assert '"schema_version": 1' in result.stdout
