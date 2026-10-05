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
    assert '"schema_version": 1' in result.stdout
