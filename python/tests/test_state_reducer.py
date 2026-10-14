import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import pytest

SCRIPT = Path(__file__).resolve().parents[1] / "state_reducer.py"
spec = importlib.util.spec_from_file_location("state_reducer", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


@pytest.mark.parametrize("mode", ["event_state", "redux"])
def test_reducer_preserves_event_order(mode):
    data = {"mode": mode, "initial": 3, "actions": [
        {"type": "increment", "value": 2},
        {"type": "decrement", "value": 4},
        {"type": "set", "value": 10},
        {"type": "reset"},
    ]}
    result = module.process(data)
    assert result == {"schema": "state-reducer/1", "mode": mode,
                      "state": 3, "history": [3, 5, 1, 10, 3]}
    assert data["initial"] == 3


@pytest.mark.parametrize("actions", [
    [{"type": "unknown"}],
    [{"type": "increment", "value": True}],
    [{"type": "reset", "value": 1}],
    [{"type": "increment", "value": 2, "extra": 1}],
    [{"type": "set", "value": "1"}],
])
def test_invalid_actions_fail(actions):
    with pytest.raises(ValueError):
        module.process({"mode": "redux", "initial": 0, "actions": actions})


def test_invalid_boundary_and_overflow():
    with pytest.raises(ValueError):
        module.process({"mode": "event_state", "initial": 999999999, "actions": [
            {"type": "increment", "value": 100}
        ]})
    with pytest.raises(ValueError):
        module.process({"mode": "redux", "initial": 0, "actions": [] , "extra": True})


def test_cli_stdin_and_exit_code():
    req = {"mode": "redux", "initial": 0, "actions": [{"type": "increment", "value": 2}]}
    good = subprocess.run([sys.executable, "-I", "-S", str(SCRIPT)], input=json.dumps(req),
                          text=True, capture_output=True, timeout=5)
    assert good.returncode == 0
    assert json.loads(good.stdout)["state"] == 2
    bad = subprocess.run([sys.executable, "-I", "-S", str(SCRIPT)], input='{"mode":"redux"}',
                         text=True, capture_output=True, timeout=5)
    assert bad.returncode == 2 and not bad.stdout
