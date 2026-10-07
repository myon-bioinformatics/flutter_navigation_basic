#!/usr/bin/env python3
"""Portable collection-window state transitions for catalogue examples."""
from __future__ import annotations
import argparse
import json

INTERACTIVE_MODES = ("selectable", "swipe-delete", "reorderable", "checklist")

MODES = ("load-more", "lazy-list", "prefetch", "page-indicator", "page-size", "offset-limit", "keyset", "window", "bidirectional")
ITEMS = [f"item-{index:02d}" for index in range(1, 13)]

def initial_state(mode: str) -> dict:
    if mode not in MODES:
        raise ValueError("unsupported mode")
    state = {"mode": mode, "offset": 0, "limit": 4, "total": len(ITEMS)}
    if mode == "keyset":
        state["cursor"] = None
    return state

def transition(state: dict, command: str) -> dict:
    if not isinstance(state, dict):
        raise TypeError("state must be an object")
    mode = state.get("mode")
    offset, limit, total = state.get("offset"), state.get("limit"), state.get("total")
    if mode not in MODES:
        raise ValueError("invalid mode")
    if not all(isinstance(v, int) and not isinstance(v, bool) for v in (offset, limit, total)):
        raise ValueError("invalid bounds")
    if offset < 0 or limit <= 0 or total < 0:
        raise ValueError("invalid bounds")
    result = dict(state)
    if command in ("next", "load-more", "prefetch"):
        result["offset"] = min(offset + limit, max(0, total - limit))
        if mode == "keyset":
            result["cursor"] = ITEMS[result["offset"] - 1] if result["offset"] else None
    elif command == "page-size-3":
        result["limit"] = 3
        result["offset"] = min((offset // 3) * 3, max(0, total - 3))
    elif command == "offset-6":
        result["offset"] = min(6, max(0, total - limit))
    elif command == "refresh":
        result["offset"] = 0
        result["revision"] = state.get("revision", 0) + 1
    elif command == "previous":
        result["offset"] = max(0, offset - limit)
    elif command == "reset":
        result["offset"] = 0
    else:
        raise ValueError("unsupported command")
    return result

def render(state: dict) -> dict:
    offset, limit, total = state["offset"], state["limit"], state["total"]
    return {
        "schema": "collection-window/1",
        "mode": state["mode"],
        "state": state,
        "page": offset // limit + 1 if total else 0,
        "pages": (total + limit - 1) // limit if total else 0,
        "values": ITEMS[offset:min(offset + limit, total)],
    }

def initial_collection(mode: str) -> dict:
    if mode not in INTERACTIVE_MODES:
        raise ValueError("unsupported collection mode")
    return {"mode": mode, "items": ["a", "b", "c", "d"], "selected": []}


def collection_command(state: dict, command: str, item: str = "b") -> dict:
    if not isinstance(state, dict) or state.get("mode") not in INTERACTIVE_MODES:
        raise ValueError("invalid collection state")
    items, selected = state.get("items"), state.get("selected")
    if not isinstance(items, list) or not isinstance(selected, list) or any(
        not isinstance(x, str) for x in items + selected
    ) or len(items) != len(set(items)) or not set(selected).issubset(items):
        raise ValueError("invalid collection items")
    if item not in items:
        raise ValueError("unknown item")
    result = {"mode": state["mode"], "items": items.copy(), "selected": selected.copy()}
    if command in ("select", "toggle"):
        if item in result["selected"]:
            result["selected"].remove(item)
        else:
            result["selected"].append(item)
    elif command == "delete":
        result["items"].remove(item)
        if item in result["selected"]:
            result["selected"].remove(item)
    elif command == "move-first":
        result["items"].remove(item)
        result["items"].insert(0, item)
    else:
        raise ValueError("unsupported collection command")
    return result


def collection_payload(mode: str) -> dict:
    command = {"selectable": "select", "swipe-delete": "delete",
               "reorderable": "move-first", "checklist": "toggle"}[mode]
    state = collection_command(initial_collection(mode), command)
    return {"schema": "collection-command/1", "mode": mode,
            "state": state, "values": [
                {"id": item, "selected": item in state["selected"]} for item in state["items"]
            ]}


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=MODES + INTERACTIVE_MODES, required=True)
    parser.add_argument("--command", choices=("next","previous","load-more","prefetch","reset","page-size-3","offset-6","refresh","select","toggle","delete","move-first"), default="next")
    parser.add_argument("--state-json")
    args = parser.parse_args(argv)
    if args.mode in INTERACTIVE_MODES:
        state = json.loads(args.state_json) if args.state_json else initial_collection(args.mode)
        command = args.command if args.state_json else {"selectable":"select","swipe-delete":"delete","reorderable":"move-first","checklist":"toggle"}[args.mode]
        output = collection_payload(args.mode) if not args.state_json else {"schema":"collection-command/1","mode":args.mode,"state":collection_command(state, command),"values":[]}
    else:
        state = json.loads(args.state_json) if args.state_json else initial_state(args.mode)
        output = render(transition(state, args.command))
    print(json.dumps(output, ensure_ascii=False, sort_keys=True))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
