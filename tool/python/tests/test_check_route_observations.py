"""Expected (TOML, hand-written) vs observed (JSON, Flutter) numbered routes."""
import json
from pathlib import Path
import sys
import tomllib

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import check_route_observations as check  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]
EXPECTED = tomllib.loads((ROOT / "tool/ci/numbered_routes.toml").read_text(encoding="utf-8"))


def _observed(**changes):
    routes = {k: {"widget": v, "id": int(k)} for k, v in EXPECTED["routes"].items()}
    for key, value in changes.items():
        if value is None:
            routes.pop(key)
        else:
            routes[key] = value
    return {"schema": "route-observations/1", "routes": routes}


def test_hand_written_expectations_cover_all_198_routes():
    assert list(EXPECTED["routes"]) == ["%03d" % i for i in range(1, 199)]
    known = set(EXPECTED["shared_widgets"]) | set(EXPECTED.get("dedicated_widgets", {})) | {EXPECTED["generic_widget"]}
    assert set(EXPECTED["routes"].values()) <= known


def test_matching_observations_pass():
    assert check.compare(EXPECTED, _observed()) == []


@pytest.mark.parametrize(("changes", "fragment"), [
    ({"091": {"widget": "GenericScreen", "id": 91}}, "091: expected ValidationPatternLinks#91, observed GenericScreen#91"),
    ({"001": {"widget": "GenericScreen", "id": 2}}, "001: expected GenericScreen#1, observed GenericScreen#2"),
    ({"199": {"widget": "GenericScreen", "id": 199}}, "199: observed GenericScreen, but it is missing from the TOML"),
    ({"198": None}, "198: expected GenericScreen, but no such route was observed"),
])
def test_any_count_kind_or_id_difference_fails(changes, fragment):
    assert fragment in check.compare(EXPECTED, _observed(**{k: v for k, v in changes.items()}))


def test_cli_exit_codes(tmp_path):
    good, bad = tmp_path / "good.json", tmp_path / "bad.json"
    good.write_text(json.dumps(_observed()), encoding="utf-8")
    bad.write_text(json.dumps(_observed(**{"171": {"widget": "GenericScreen", "id": 171}})), encoding="utf-8")
    assert check.main([str(good)]) == 0
    assert check.main([str(bad)]) == 1
    assert check.main([str(tmp_path / "missing.json")]) == 2
