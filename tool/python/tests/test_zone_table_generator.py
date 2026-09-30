"""Guard the shipped asset and generator's fail-closed drift contract."""
import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location("zone_generator", ROOT / "tool/time/generate_zone_table.py")
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)


def test_asset_matches_oracle_and_render_is_deterministic():
    table = generator.build_table()
    assert len(table["zones"]) == 25
    assert generator.render(table) == generator.render(generator.build_table())
    assert json.loads(generator.ASSET_PATH.read_text()) == table


def test_check_rejects_missing_corrupt_and_modified_assets(tmp_path, monkeypatch):
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
    assert generator.main() == 1


def test_asset_only_change_selects_python_and_preserves_auto_playwright():
    workflow = (ROOT / ".github/workflows/non-dart.yml").read_text()
    assert workflow.count('      - "assets/time/**"') == 2
    assert "tool/time/*|assets/time/*|" in workflow
    assert "python tool/time/generate_zone_table.py --check" in workflow
    assert "name: Playwright E2E (auto)" in workflow
    assert "run_playwright:" not in workflow
