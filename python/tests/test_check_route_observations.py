"""Expected (TOML, hand-written) vs observed (JSON, Flutter) numbered routes."""
import json
from pathlib import Path
import sys
import tomllib

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import check_route_observations as check  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
EXPECTED = tomllib.loads((ROOT / "ci/numbered_routes.toml").read_text(encoding="utf-8"))


def _observed(**changes):
    routes = {k: {"widget": v, "id": int(k)} for k, v in EXPECTED["routes"].items()}
    for key, value in changes.items():
        if value is None:
            routes.pop(key)
        else:
            routes[key] = value
    return {"schema": "route-observations/2", "provenance": {"head_sha": "a" * 40, "run_id": "123"}, "routes": routes}


def test_hand_written_expectations_cover_all_198_routes():
    assert list(EXPECTED["routes"]) == ["%03d" % i for i in range(1, 199)]
    known = set(EXPECTED["shared_widgets"]) | set(EXPECTED.get("dedicated_widgets", {})) | {EXPECTED["generic_widget"]}
    assert set(EXPECTED["routes"].values()) <= known


def test_matching_observations_pass():
    assert check.compare(EXPECTED, _observed(), head_sha="a" * 40, run_id="123") == []


def test_wrong_head_or_run_provenance_fails():
    assert "head SHA" in check.compare(EXPECTED, _observed(), head_sha="b" * 40, run_id="123")[0]
    assert "run ID" in check.compare(EXPECTED, _observed(), head_sha="a" * 40, run_id="999")[0]


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
    receipt = tmp_path / "receipt.json"
    assert check.main([str(good), "--head-sha", "a" * 40, "--run-id", "123", "--receipt", str(receipt)]) == 0
    saved = json.loads(receipt.read_text(encoding="utf-8"))
    assert saved["head_sha"] == "a" * 40 and saved["run_id"] == "123" and saved["result"] == "success"
    no_identity_receipt = tmp_path / "no-identity.json"
    assert check.main([str(good), "--receipt", str(no_identity_receipt)]) == 2
    assert not no_identity_receipt.exists()
    assert check.main([str(bad)]) == 1
    assert check.main([str(tmp_path / "missing.json")]) == 2


def test_refactor_smoke_check_step_parses_as_one_command():
    import shlex
    # Refactor smoke installs only pytest; the full Non-Dart pytest has PyYAML.
    yaml = pytest.importorskip("yaml")
    workflow = yaml.safe_load((ROOT / ".github/workflows/structure-refactor-validation.yml").read_text(encoding="utf-8"))
    runs = [step["run"] for job in workflow["jobs"].values() for step in job.get("steps", [])
            if step.get("run", "").startswith("python3 -S python/check_route_observations.py")]
    assert len(runs) == 1
    argv = shlex.split(runs[0].replace("${{ github.event.pull_request.head.sha || github.sha }}", "h")
                       .replace("${{ github.run_id }}", "1"))
    assert "\\" not in argv, argv  # stray backslash arguments break argparse
    assert argv[argv.index("--head-sha") + 1] == "h" and argv[argv.index("--run-id") + 1] == "1"



@pytest.mark.parametrize("payload", [[], {"schema": "route-observations/2", "provenance": {}, "routes": []},
                                     {"schema": "route-observations/2", "provenance": {}, "routes": {"001": "x"}}])
def test_malformed_observations_fail_without_traceback(tmp_path, payload):
    path = tmp_path / "observed.json"
    path.write_text(json.dumps(payload), encoding="utf-8")
    assert check.main([str(path)]) in (1, 2)


def test_toml_naming_an_unknown_widget_fails():
    broken = {**EXPECTED, "routes": {**EXPECTED["routes"], "001": "TypoScreen"}}
    assert "001: TOML names unknown widget 'TypoScreen'" in check.compare(broken, _observed())


@pytest.mark.parametrize("key", ["1a", "", "abc", "\u0661\u0662\u0663", "\u00b2", "\uff10\uff10\uff11"])
def test_non_numeric_route_keys_fail_without_traceback(key):
    broken = _observed()
    broken["routes"][key] = {"widget": "GenericScreen", "id": 1}
    assert check.compare(EXPECTED, broken) == ["route keys must be zero-padded numbers such as 001"]


def test_audit_and_checker_share_one_definition_of_widget_kinds():
    import pattern_responsibility_audit as audit
    assert audit.known_widgets is check.known_widgets


def test_receipt_binds_input_bytes_and_uses_repository_paths(tmp_path):
    import hashlib
    path, receipt = tmp_path / "observed.json", tmp_path / "receipt.json"
    path.write_text(json.dumps(_observed()), encoding="utf-8")
    assert check.main([str(path), "--head-sha", "a" * 40, "--run-id", "123", "--receipt", str(receipt)]) == 0
    saved = json.loads(receipt.read_text(encoding="utf-8"))
    assert saved["expected"] == "ci/numbered_routes.toml"
    assert saved["expected_sha256"] == hashlib.sha256((ROOT / "ci/numbered_routes.toml").read_bytes()).hexdigest()
    assert saved["observed_sha256"] == hashlib.sha256(path.read_bytes()).hexdigest()


def test_extra_route_without_widget_and_array_toml_value_fail_without_traceback():
    extra = _observed()
    extra["routes"]["199"] = {"id": 199}
    assert "199: observed None, but it is missing from the TOML" in check.compare(EXPECTED, extra)
    broken = {**EXPECTED, "routes": {**EXPECTED["routes"], "001": ["GenericScreen"]}}
    assert "001: TOML names unknown widget ['GenericScreen']" in check.compare(broken, _observed())


def test_receipt_records_run_attempt(tmp_path):
    data = _observed()
    data["provenance"]["run_attempt"] = "2"
    path, receipt = tmp_path / "observed.json", tmp_path / "receipt.json"
    path.write_text(json.dumps(data), encoding="utf-8")
    assert check.main([str(path), "--head-sha", "a" * 40, "--run-id", "123", "--receipt", str(receipt)]) == 0
    assert json.loads(receipt.read_text(encoding="utf-8"))["run_attempt"] == "2"
