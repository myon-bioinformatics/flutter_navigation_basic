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
        assert value["stale_readme"]

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
