"""Contract for explicit Python/Node selection and agent-safe print output."""
from __future__ import annotations

import importlib.util
from pathlib import Path

import pytest


SCRIPT = Path(__file__).resolve().parents[1] / "test.py"
SPEC = importlib.util.spec_from_file_location("test_entry_under_test", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
entry = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(entry)


@pytest.mark.parametrize("argv,expected", [
    ([], ["python"]),
    (["--python"], ["python"]),
    (["--py"], ["python"]),
    (["--pytest"], ["python"]),
    (["--node"], ["node"]),
    (["--python", "--node"], ["node", "python"]),
    (["--node", "--python"], ["node", "python"]),
])
def test_explicit_runner_selection(monkeypatch, argv, expected):
    calls = []
    monkeypatch.setattr(entry, "_run_pytest", lambda args: calls.append(("python", args)) or 0)
    monkeypatch.setattr(entry, "_run_node_tests", lambda args: calls.append(("node", [])) or 0)
    assert entry.main(argv) == 0
    assert [kind for kind, _ in calls] == expected


def test_exitfirst_reaches_pytest_and_does_not_skip_node(monkeypatch):
    calls = []
    monkeypatch.setattr(entry, "_run_pytest", lambda args: calls.append(("python", args)) or 0)
    monkeypatch.setattr(entry, "_run_node_tests", lambda args: calls.append(("node", [])) or 0)
    assert entry.main(["--python", "--node", "-x"]) == 0
    assert calls == [("node", []), ("python", ["-x"])]


def test_node_only_rejects_pytest_exitfirst(monkeypatch):
    monkeypatch.setattr(entry, "_run_node_tests", lambda args: pytest.fail("node must not start"))
    with pytest.raises(SystemExit) as exc:
        entry.main(["--node", "-x"])
    assert exc.value.code == 2


def test_literal_print_without_running_tests(monkeypatch, capsys):
    monkeypatch.setattr(entry, "_run_pytest", lambda args: pytest.fail("python must not start"))
    monkeypatch.setattr(entry, "_run_node_tests", lambda args: pytest.fail("node must not start"))
    message = 'from pathlib import Path; print("literal, not executed")'
    assert entry.main(["--print-message", message]) == 0
    assert capsys.readouterr().out.strip() == message


def test_print_combined_with_explicit_python(monkeypatch, capsys):
    calls = []
    monkeypatch.setattr(entry, "_run_pytest", lambda args: calls.append(args) or 0)
    assert entry.main(["--python", "--print-message", "agent note"]) == 0
    assert calls == [[]]
    assert "agent note" in capsys.readouterr().out


def test_nonzero_result_not_masked_by_other_runner(monkeypatch):
    monkeypatch.setattr(entry, "_run_pytest", lambda args: 1)
    monkeypatch.setattr(entry, "_run_node_tests", lambda args: 0)
    assert entry.main(["--python", "--node"]) == 1


@pytest.mark.parametrize("node_exit,python_exit,expected", [
    (1, 0, 1),   # A passing pytest run must not hide a failed Node run.
    (0, 1, 1),   # A passing Node run must not hide a failed pytest run.
    (7, 3, 7),   # Both fail: retain the first nonzero exit code.
    (0, 0, 0),
])
def test_combined_runner_preserves_failure(monkeypatch, node_exit, python_exit, expected):
    calls = []
    monkeypatch.setattr(entry, "_run_node_tests",
                        lambda args: calls.append("node") or node_exit)
    monkeypatch.setattr(entry, "_run_pytest",
                        lambda args: calls.append("python") or python_exit)
    assert entry.main(["--node", "--python"]) == expected
    assert calls == ["node", "python"]
