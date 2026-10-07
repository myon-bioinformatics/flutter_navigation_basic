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


def test_page_size_offset_keyset_and_window_modes():
    page_size = module.transition(module.initial_state("page-size"), "page-size-3")
    assert module.render(page_size)["values"] == ["item-01", "item-02", "item-03"]
    assert module.render(page_size)["pages"] == 4

    offset = module.transition(module.initial_state("offset-limit"), "offset-6")
    assert module.render(offset)["values"] == ["item-07", "item-08", "item-09", "item-10"]

    keyset = module.transition(module.initial_state("keyset"), "next")
    assert keyset["cursor"] == "item-04"
    assert module.render(keyset)["values"][0] == "item-05"

    window = module.transition(module.initial_state("window"), "next")
    assert module.render(window)["page"] == 2


def test_refresh_command_resets_window_and_advances_revision():
    state = module.transition(module.initial_state("load-more"), "next")
    refreshed = module.transition(state, "refresh")
    assert refreshed["offset"] == 0
    assert refreshed["revision"] == 1
    assert module.transition(refreshed, "refresh")["revision"] == 2


def test_bidirectional_window_can_move_both_ways():
    state = module.initial_state("bidirectional")
    state = module.transition(state, "next")
    assert module.render(state)["values"][0] == "item-05"
    state = module.transition(state, "previous")
    assert module.render(state)["values"][0] == "item-01"


@pytest.mark.parametrize("mode,command,expected_items,expected_selected", [
    ("selectable","select",["a","b","c","d"],["b"]),
    ("swipe-delete","delete",["a","c","d"],[]),
    ("reorderable","move-first",["b","a","c","d"],[]),
    ("checklist","toggle",["a","b","c","d"],["b"]),
])
def test_collection_commands(mode,command,expected_items,expected_selected):
    state=module.collection_command(module.initial_collection(mode),command)
    assert state["items"]==expected_items
    assert state["selected"]==expected_selected


def test_collection_commands_reject_invalid_items():
    with pytest.raises(ValueError):
        module.collection_command(module.initial_collection("selectable"),"select","missing")
    with pytest.raises(ValueError):
        module.collection_command({"mode":"selectable","items":["a","a"],"selected":[]},"select","a")


def test_collection_cli_runs_without_flutter():
    result=subprocess.run(
        [sys.executable,"-I","-S",str(SCRIPT),"--mode","reorderable"],
        capture_output=True,text=True,timeout=5,
    )
    assert result.returncode==0
    assert json.loads(result.stdout)["state"]["items"][0]=="b"
