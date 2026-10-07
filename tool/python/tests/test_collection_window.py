import importlib.util
import json
from pathlib import Path
import subprocess
import sys

import pytest

ROOT = Path(__file__).resolve().parents[3]
SCRIPT = ROOT / "tool/python/collection_window.py"
spec = importlib.util.spec_from_file_location("collection_window", SCRIPT)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)


def test_load_more_and_page_indicator_transitions():
    state = module.initial_state("load-more")
    state = module.transition(state, "load-more")
    assert module.render(state)["values"] == ["item-05", "item-06", "item-07", "item-08"]
    page = module.initial_state("page-indicator")
    page = module.transition(page, "next")
    assert module.render(page)["page"] == 2
    assert module.render(page)["pages"] == 3


def test_prefetch_and_lazy_list_are_bounded():
    for mode, command in [("prefetch", "prefetch"), ("lazy-list", "next")]:
        state = module.initial_state(mode)
        for _ in range(10):
            state = module.transition(state, command)
        rendered = module.render(state)
        assert rendered["state"]["offset"] == 8
        assert rendered["values"] == ["item-09", "item-10", "item-11", "item-12"]


def test_previous_reset_and_invalid_commands():
    state = module.transition(module.initial_state("load-more"), "next")
    assert module.transition(state, "previous")["offset"] == 0
    assert module.transition(state, "reset")["offset"] == 0
    with pytest.raises(ValueError):
        module.transition(state, "bogus")
    with pytest.raises(ValueError):
        module.transition({"mode":"load-more","offset":True,"limit":4,"total":12}, "next")


def test_cli_runs_state_transition_without_flutter():
    state = json.dumps({"mode":"page-indicator","offset":4,"limit":4,"total":12})
    result = subprocess.run(
        [sys.executable, "-I", "-S", str(SCRIPT), "--mode", "page-indicator",
         "--command", "next", "--state-json", state],
        capture_output=True, text=True, timeout=5,
    )
    assert result.returncode == 0
    payload = json.loads(result.stdout)
    assert payload["state"]["offset"] == 8
    assert payload["page"] == 3
    assert payload["values"][-1] == "item-12"
