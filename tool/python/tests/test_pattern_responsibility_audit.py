import pytest
import pattern_responsibility_audit as audit
from pathlib import Path
import tempfile

ROOT=Path(__file__).resolve().parents[3]

def setup(tmp,num,service=None):
    folder=audit.pattern_dir(tmp,num)
    folder.mkdir(parents=True)
    (folder/"README.md").write_text(
        "# Pattern %03d: Example\nGet.to(() => Demo());\ncontroller.dart\n" % num,
        encoding="utf-8")
    (folder/"view.dart").write_text("class Demo {}\n",encoding="utf-8")
    if service is not None:
        (folder/"service.dart").write_text(service,encoding="utf-8")

def test_fake_service_remains_unimplemented():
    with tempfile.TemporaryDirectory() as td:
        root=Path(td)
        setup(root,4,service="TODO: 実装を追加してください\n"
              "await Future.delayed(const Duration(milliseconds: 100));\n"
              "return 'executed successfully';")
        value=audit.inspect(root,4)
        assert value["status"]=="fake_delayed_success"
        assert not value["stale_readme"]

def test_external_cli_not_connected_to_flutter():
    with tempfile.TemporaryDirectory() as td:
        root=Path(td)
        setup(root,114)
        row=audit.inspect(root,114)
        assert row["status"]=="standalone_cli_ui_unwired"
        assert not row["producer"]["flutter_runtime_connected"]

def test_security_title_does_not_claim_defense():
    with tempfile.TemporaryDirectory() as td:
        root=Path(td)
        setup(root,102)
        result=audit.inspect(root,102)
        assert result["status"]=="description_only"
        assert any("SQL" in line for line in result["warnings"])

def test_repository_inventory_is_dynamic_and_well_formed():
    result=audit.audit(ROOT)
    assert result["summary"]["patterns"]==len(result["patterns"])
    assert result["summary"]["dart_files"]==sum(
        len(record["dart_files"]) for record in result["patterns"])
    assert not result["errors"],result["errors"]
    assert "implemented" not in result["summary"]["statuses"]


def test_missing_catalogue_id_fails_check():
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        setup(root, 1)
        result = audit.audit(root)
        assert result["summary"]["patterns"] == 1
        assert "002: missing catalogue pattern" in result["errors"]
        assert result["summary"]["errors"] >= 197


def test_empty_catalogue_fails_check():
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        (root / "lib/features/data_processing_patterns").mkdir(parents=True)
        result = audit.audit(root)
        assert result["summary"]["patterns"] == 0
        missing = [e for e in result["errors"] if e.endswith("missing catalogue pattern")]
        assert len(missing) == 198  # plus the missing route manifest error


def test_unexpected_catalogue_id_is_reported():
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        setup(root, 199)
        result = audit.audit(root)
        assert "199: unexpected catalogue pattern" in result["errors"]


def test_removed_file_mentioned_in_prose_is_not_stale():
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        setup(root, 2)
        row = audit.inspect(root, 2)
        assert not row["stale_readme"]
        assert row["producer"]["source"] == "tool/python/list_selection.py"


def test_active_readme_import_of_removed_file_is_stale():
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        setup(root, 2)
        readme = audit.pattern_dir(root, 2) / "README.md"
        readme.write_text(readme.read_text(encoding="utf-8") +
                          "\nimport 'controller.dart';\n", encoding="utf-8")
        assert audit.inspect(root, 2)["stale_readme"]


def test_shared_producer_families_are_registered():
    expected = {
        1: "list_selection.py",
        34: "collection_window.py",
        44: "collection_window.py",
        45: "collection_structure.py",
        49: "collection_structure.py",
        51: "collection_window.py",
        54: "collection_window.py",
        86: "list_selection.py",
        113: "list_selection.py",
        114: "collection_transform.py",
    }
    for number, filename in expected.items():
        record = audit.producer(number)
        assert record is not None, number
        assert record["source"].endswith("/" + filename)
        assert record["flutter_runtime_connected"] is False


def test_duplicate_pattern_in_second_bucket_is_rejected():
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        setup(root, 1)
        duplicate = root / "lib/features/data_processing_patterns/pattern_100_to_198/pattern_001"
        duplicate.mkdir(parents=True)
        result = audit.audit(root)
        assert result["summary"]["patterns"] == 1
        assert any("001: duplicate or misplaced" in error for error in result["errors"])


def test_pattern_in_wrong_bucket_is_rejected():
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        folder = root / "lib/features/data_processing_patterns/pattern_001_to_099/pattern_100"
        folder.mkdir(parents=True)
        (folder / "README.md").write_text("# Pattern 100: Example", encoding="utf-8")
        (folder / "view.dart").write_text("class Example {}", encoding="utf-8")
        result = audit.audit(root)
        assert any("100: duplicate or misplaced" in error for error in result["errors"])


def test_seven_shared_gesture_routes_need_no_legacy_view():
    for number in sorted(audit.GESTURES):
        row = audit.inspect(ROOT, number)
        assert row["status"] == "native_flutter_shared_interaction", row
        assert (row["dart_files"], row["legacy_view"]) == ([], "absent")
        assert not row["stale_readme"]
        assert not any("E2E-only" in warning for warning in row["warnings"])


import json


def _manifest(root, overrides=None, **changes):
    routes = {"%03d" % i: "GenericScreen" for i in range(1, 199)}
    routes.update({"%03d" % k: v for k, v in (overrides or {}).items()})
    doc = {"schema": "numbered-routes/1", "generic_widget": "GenericScreen",
           "shared_widgets": {"InteractivePatternExample": "x", "ValidationPatternLinks": "x"},
           "routes": routes, **changes}
    lines = [f'schema = "{doc["schema"]}"', f'generic_widget = "{doc["generic_widget"]}"',
             "[shared_widgets]", *[f'{k} = "{v}"' for k, v in doc["shared_widgets"].items()],
             "[routes]", *[f'"{k}" = "{v}"' for k, v in doc["routes"].items()]]
    (root/"tool/ci").mkdir(parents=True, exist_ok=True)
    (root/audit.MANIFEST).write_text("\n".join(lines) + "\n", encoding="utf-8")


def _gesture_root(td, route):
    root = Path(td)
    setup(root, 171)
    (audit.pattern_dir(root, 171)/"view.dart").write_text(
        "const InteractivePatternExample(patternId: 171);\n", encoding="utf-8")
    _manifest(root, {171: route})
    return root


def test_gesture_status_follows_the_proven_route_not_the_view_text():
    with tempfile.TemporaryDirectory() as td:
        row = audit.inspect(_gesture_root(td, "InteractivePatternExample"), 171)
        assert row["status"] == "native_flutter_shared_interaction", row
        assert (row["reachability"], row["provision"], row["legacy_view"]) == (
            "shared", "shared_interaction", "unreachable")
    with tempfile.TemporaryDirectory() as td:
        row = audit.inspect(_gesture_root(td, "GenericScreen"), 171)
        assert row["status"] != "native_flutter_shared_interaction"
        assert row["reachability"] == "generic"
        assert any("does not build the shared native interaction" in w for w in row["warnings"])


def test_shared_route_makes_view_optional_but_generic_route_does_not():
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        for number in (136, 137):  # no producer, not a gesture pattern
            setup(root, number)
            (audit.pattern_dir(root, number)/"view.dart").unlink()
        _manifest(root, {136: "ValidationPatternLinks"})
        shared, generic = audit.inspect(root, 136), audit.inspect(root, 137)
        assert (shared["status"], shared["legacy_view"]) == ("shared_widget_route", "absent")
        assert generic["status"] == "missing_catalogue_artifact"


@pytest.mark.parametrize(("change", "message"), [
    ({"routes": {"001": "GenericScreen"}}, "must list 001-198 in order"),
    ({"schema": "numbered-routes/0"}, "unexpected schema"),
    ({"shared_widgets": {"MysteryWidget": "x"}}, "unknown widget kinds"),
])
def test_malformed_manifest_is_an_audit_error(change, message):
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        setup(root, 1)
        _manifest(root, **change)
        assert any(message in error for error in audit.audit(root)["errors"])


def test_missing_manifest_is_an_audit_error():
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        setup(root, 1)
        assert "tool/ci/numbered_routes.toml: missing" in audit.audit(root)["errors"]


def test_real_repository_reachability_is_complete():
    summary = audit.audit(ROOT)["summary"]
    assert sum(summary["reachability"].values()) == 198
    assert "unknown" not in summary["reachability"]
    assert "unknown" not in summary["provisions"]


def test_cli_rejects_route_receipt_without_external_identity(tmp_path):
    receipt = tmp_path / "receipt.json"
    receipt.write_text(json.dumps({
        "schema": "route-verification/1", "head_sha": "a" * 40,
        "run_id": "123", "routes": 198, "result": "success"
    }), encoding="utf-8")
    assert audit.main(["--root", str(ROOT), "--route-verification", str(receipt),
                       "--json"]) == 2


@pytest.mark.parametrize(("head", "run"), [("b" * 40, "123"), ("a" * 40, "999")])
def test_cli_rejects_route_receipt_for_other_head_or_run(tmp_path, head, run):
    receipt = tmp_path / "receipt.json"
    receipt.write_text(json.dumps({
        "schema": "route-verification/1", "head_sha": "a" * 40,
        "run_id": "123", "routes": 198, "result": "success"
    }), encoding="utf-8")
    assert audit.main(["--root", str(ROOT), "--route-verification", str(receipt),
                       "--route-head-sha", head, "--route-run-id", run, "--json"]) == 2



def test_malformed_receipt_is_rejected_without_traceback(tmp_path):
    path = tmp_path / "receipt.json"
    path.write_text("[]", encoding="utf-8")
    assert audit.main(["--check", "--route-verification", str(path),
                       "--route-head-sha", "a" * 40, "--route-run-id", "123"]) == 2


def _bound_receipt(tmp_path, digest=None):
    import hashlib
    data = {"schema": "route-verification/1", "result": "success", "routes": 198,
            "head_sha": "a" * 40, "run_id": "123",
            "expected_sha256": digest or hashlib.sha256((ROOT / audit.MANIFEST).read_bytes()).hexdigest()}
    path = tmp_path / "bound-receipt.json"
    path.write_text(json.dumps(data), encoding="utf-8")
    return path


def test_receipt_is_accepted_only_for_the_current_toml_bytes(tmp_path):
    assert audit.verify_receipt(ROOT, _bound_receipt(tmp_path), "a" * 40, "123")["run_id"] == "123"
    with pytest.raises(ValueError, match="different tool/ci/numbered_routes.toml"):
        audit.verify_receipt(ROOT, _bound_receipt(tmp_path, "0" * 64), "a" * 40, "123")
    assert audit.main(["--check", "--route-verification", str(_bound_receipt(tmp_path)),
                       "--route-head-sha", "a" * 40, "--route-run-id", "123"]) == 0


def test_audit_without_receipt_says_unverified_not_null():
    assert audit.audit(ROOT)["route_verification"] == {"status": "unverified"}


def test_receipt_must_cover_all_198_routes(tmp_path):
    import hashlib
    path = tmp_path / "short.json"
    path.write_text(json.dumps({"schema": "route-verification/1", "result": "success", "routes": 197,
                                "head_sha": "a" * 40, "run_id": "123",
                                "expected_sha256": hashlib.sha256((ROOT / audit.MANIFEST).read_bytes()).hexdigest()}),
                    encoding="utf-8")
    with pytest.raises(ValueError, match="198 routes"):
        audit.verify_receipt(ROOT, path, "a" * 40, "123")


def test_routes_proven_shared_have_no_legacy_view_left():
    """Views behind a shared route were unreachable; keep them deleted."""
    rows = {r["id"]: r for r in audit.audit(ROOT)["patterns"]}
    shared = sorted(n for n, r in rows.items() if r["reachability"] == "shared")
    assert len(shared) == 24
    left = [n for n in shared if rows[n]["legacy_view"] != "absent" and n not in (136, 137)]
    assert left == []
