"""Non-pytest JUnit validation contract."""
import importlib.util
from pathlib import Path
import pytest

SCRIPT = Path(__file__).resolve().parents[1] / "validate_runner_junit.py"
spec = importlib.util.spec_from_file_location("validate_runner_junit", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def test_native_junit_cases_are_counted(tmp_path):
    report = tmp_path / "node.xml"
    report.write_text('<testsuite tests="3"><testcase name="pass"/>'
                      '<testcase name="fail"><failure message="oops"/></testcase>'
                      '<testcase name="skip"><skipped/></testcase></testsuite>',
                      encoding="utf-8")
    assert module.inspect(report) == {"tests": 3, "failures": 1, "errors": 0, "skipped": 1}


@pytest.mark.parametrize("xml", [
    "<testsuite/>",
    "<testsuite><testcase/></testsuite>",
    "<testsuite><testcase name='x'></testsuite>",
    "<not-junit><testcase name='x'/></not-junit>",
])
def test_invalid_reports_fail_closed(tmp_path, xml):
    report = tmp_path / "bad.xml"
    report.write_text(xml, encoding="utf-8")
    with pytest.raises((ValueError, module.ET.ParseError)):
        module.inspect(report)


def test_missing_report_fails_closed(tmp_path):
    with pytest.raises(ValueError):
        module.inspect(tmp_path / "missing.xml")
