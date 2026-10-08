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


def collection_cli(mode, command=None, state=None):
    args = [sys.executable, "-I", "-S", str(SCRIPT), "--mode", mode]
    if command is not None:
        args.extend(["--command", command])
    if state is not None:
        args.extend(["--state-json", json.dumps(state)])
    result = subprocess.run(
        args, capture_output=True, text=True, timeout=5,
    )
    assert result.returncode == 0, result.stderr
    assert result.stderr == ""
    return json.loads(result.stdout)


def assert_collection_display(payload, mode, items, selected):
    assert payload["schema"] == "collection-command/1"
    assert payload["mode"] == mode
    assert payload["state"] == {"mode": mode, "items": items, "selected": selected}
    assert [value["id"] for value in payload["values"]] == payload["state"]["items"]
    assert payload["values"] == [
        {"id": item, "selected": item in selected} for item in items
    ]


@pytest.mark.parametrize("mode,items,selected", [
    ("selectable", ["a", "b", "c", "d"], ["b"]),
    ("swipe-delete", ["a", "c", "d"], []),
    ("reorderable", ["b", "a", "c", "d"], []),
    ("checklist", ["a", "b", "c", "d"], ["b"]),
])
def test_collection_cli_without_state_renders_transition(mode, items, selected):
    assert_collection_display(collection_cli(mode), mode, items, selected)


@pytest.mark.parametrize("mode,command", [
    ("selectable", "select"),
    ("checklist", "toggle"),
])
def test_collection_cli_continues_selection(mode, command):
    payload = collection_cli(mode)
    items = ["a", "b", "c", "d"]
    for selected in ([], ["b"], []):
        payload = collection_cli(mode, command, payload["state"])
        assert_collection_display(payload, mode, items, selected)


def test_collection_cli_continues_reordering_custom_state():
    mode = "reorderable"
    payload = collection_cli(mode)
    assert_collection_display(payload, mode, ["b", "a", "c", "d"], [])
    for _ in range(2):
        payload = collection_cli(mode, "move-first", payload["state"])
        assert_collection_display(payload, mode, ["b", "a", "c", "d"], [])
    state = {"mode": mode, "items": ["猫", "d", "b", "a"], "selected": ["d"]}
    payload = collection_cli(mode, "move-first", state)
    assert_collection_display(payload, mode, ["b", "猫", "d", "a"], ["d"])
    payload = collection_cli(mode, "move-first", payload["state"])
    assert_collection_display(payload, mode, ["b", "猫", "d", "a"], ["d"])


def test_collection_cli_continues_swipe_delete_and_removes_selection():
    mode = "swipe-delete"
    payload = collection_cli(mode, "select", module.initial_collection(mode))
    assert_collection_display(payload, mode, ["a", "b", "c", "d"], ["b"])
    payload = collection_cli(mode, "delete", payload["state"])
    assert_collection_display(payload, mode, ["a", "c", "d"], [])


def test_swipe_delete_continues_until_empty_and_preserves_other_selection():
    mode = "swipe-delete"
    state = {"mode": mode, "items": ["a", "b", "c", "d"], "selected": ["b", "d"]}
    for item, items, selected in [
        ("b", ["a", "c", "d"], ["d"]),
        ("c", ["a", "d"], ["d"]),
        ("d", ["a"], []),
        ("a", [], []),
    ]:
        state = module.collection_command(state, "delete", item)
        assert_collection_display(module.render_collection(state), mode, items, selected)
