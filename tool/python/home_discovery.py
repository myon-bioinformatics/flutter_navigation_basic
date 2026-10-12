"""Generate deterministic candidate triples for Home discovery (stdlib only).

The Flutter runtime randomly chooses a triple each Home refresh; this file
provides precomputed eligible IDs, not a frozen one-time Home selection.
"""
import json
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "assets" / "home_discovery_draws.json"
COUNT = 64
IDS = tuple(range(6, 199))


def make_draws():
    ids = list(IDS)
    random.Random(0x1257A7).shuffle(ids)
    return [ids[i:i + 3] for i in range(0, COUNT * 3, 3)]


def render():
    return json.dumps({"schema": 1, "draws": make_draws()}, separators=(",", ":")) + "\n"


if __name__ == "__main__":
    OUTPUT.write_text(render(), encoding="utf-8")
