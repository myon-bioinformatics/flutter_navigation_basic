"""Generate deterministic candidate triples for Home discovery (stdlib only).

The Flutter runtime randomly chooses a triple each Home refresh; this file
provides precomputed eligible IDs, not a frozen one-time Home selection.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "assets" / "home_discovery_draws.json"
COUNT = 64
IDS = tuple(range(6, 199))


def make_draws():
    state = 0x1257A7
    draws = []
    for _ in range(COUNT):
        pool = list(IDS)
        for i in range(len(pool) - 1, 0, -1):
            state = (1664525 * state + 1013904223) & 0xffffffff
            j = state % (i + 1)
            pool[i], pool[j] = pool[j], pool[i]
        draws.append(pool[:3])
    return draws


def render():
    return json.dumps({"schema": 1, "draws": make_draws()}, separators=(",", ":")) + "\n"


if __name__ == "__main__":
    OUTPUT.write_text(render(), encoding="utf-8")
