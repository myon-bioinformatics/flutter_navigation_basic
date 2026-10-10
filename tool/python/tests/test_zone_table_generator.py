"""Guard the shipped transitions, provenance, and asset-only CI routing."""
import importlib.util
import json
from pathlib import Path

import pytest
import yaml

ROOT = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location("zone_generator", ROOT / "tool/time/generate_zone_table.py")
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)


def test_asset_matches_oracle_and_render_is_deterministic():
    table = generator.build_table()
    assert len(table["zones"]) == 25
    assert generator.render(table) == generator.render(generator.build_table())
    asset = json.loads(generator.ASSET_PATH.read_text())
    assert asset["tzdata_version"]
    assert generator.comparable_table(asset) == generator.comparable_table(table)


def test_check_rejects_missing_corrupt_and_modified_assets(tmp_path, monkeypatch, capsys):
    table = generator.build_table()
    asset = tmp_path / "zone_table.json"
    monkeypatch.setattr(generator, "ASSET_PATH", asset)
    monkeypatch.setattr(generator, "build_table", lambda: table)
    monkeypatch.setattr("sys.argv", ["generate_zone_table.py", "--check"])
    assert generator.main() == 1
    asset.write_text("{broken")
    assert generator.main() == 1
    asset.write_text(generator.render(table))
    assert generator.main() == 0
    changed = json.loads(asset.read_text())
    changed["zones"]["Asia/Tokyo"]["transitions"][0][1] = 0
    asset.write_text(json.dumps(changed))
    assert generator.main() == 1
    changed = json.loads(generator.render(table))
    changed["tzdata_version"] = "different-release"
    asset.write_text(json.dumps(changed))
    capsys.readouterr()
    assert generator.main() == 0
    assert "warning: tzdata release differs" in capsys.readouterr().err
    # A version warning must never mask real transition drift.
    changed["zones"]["Asia/Tokyo"]["transitions"][0][1] = 0
    asset.write_text(json.dumps(changed))
    assert generator.main() == 1
    changed["tzdata_version"] = None
    asset.write_text(json.dumps(changed))
    assert generator.main() == 1
    asset.write_text("[]")
    assert generator.main() == 1


def test_generation_rejects_unknown_tzdata_version(monkeypatch):
    monkeypatch.setattr(generator, "tzdata_version", lambda: None)
    with pytest.raises(SystemExit, match="cannot determine IANA tzdata version"):
        generator.build_table()


def _workflow(name):
    # BaseLoader preserves YAML 1.2's `on` spelling as a string, unlike
    # PyYAML's default YAML 1.1 boolean resolver. All assertions are structural.
    return yaml.load((ROOT / ".github/workflows" / name).read_text(), Loader=yaml.BaseLoader)


def test_asset_only_change_selects_python_flutter_and_preserves_auto_playwright(classify_workflow_asset):
    non_dart = _workflow("non-dart.yml")
    for event in ("push", "pull_request"):
        assert "assets/time/**" in non_dart["on"][event]["paths"]
    outputs = classify_workflow_asset(non_dart, "assets/time/zone_table.json")
    assert outputs["python"] == "true"
    assert outputs["playwright"] == "false"
    checks = non_dart["jobs"]["python-stdlib"]["steps"]
    assert any("python tool/time/generate_zone_table.py --check" in step.get("run", "") for step in checks)
    assert any(job.get("name") == "Playwright E2E (auto)" for job in non_dart["jobs"].values())
    dispatch = non_dart["on"]["workflow_dispatch"]
    inputs = dispatch.get("inputs", {}) if isinstance(dispatch, dict) else {}
    assert "run_playwright" not in inputs

    flutter = _workflow("dart.yml")
    assert "pull_request" in flutter["on"]
    assert "paths" not in flutter["on"]["pull_request"]
    assert "paths-ignore" not in flutter["on"]["pull_request"]
    assert classify_workflow_asset(flutter, "assets/time/zone_table.json")["flutter"] == "true"
    assert "test/now_timeline" in (ROOT / "tool/ci/flutter_core_test_paths.txt").read_text().splitlines()
    assert any("flutter_core_test_paths.txt" in step.get("run", "") and "flutter test" in step["run"]
               for job in flutter["jobs"].values() for step in job.get("steps", []))
