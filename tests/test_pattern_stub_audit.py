import tempfile
import unittest
from pathlib import Path

from tool.pattern_stub_audit import audit


class PatternStubAuditTest(unittest.TestCase):
    def test_detects_only_full_placeholder_signature(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            base = root / "lib/features/api_patterns/pattern_001_to_099/pattern_001"
            base.mkdir(parents=True)
            (base / "service.dart").write_text(
                """// TODO: 実装を追加してください
await Future.delayed(const Duration(milliseconds: 100));
return Pattern001Result(message: 'HttpGet executed successfully');
""",
                encoding="utf-8",
            )
            real = root / "lib/features/api_patterns/pattern_001_to_099/pattern_002"
            real.mkdir(parents=True)
            (real / "service.dart").write_text(
                "return Pattern002Result(message: 'implemented');\n",
                encoding="utf-8",
            )

            result = audit(root)

        self.assertEqual(
            result["api_patterns"],
            ["lib/features/api_patterns/pattern_001_to_099/pattern_001/service.dart"],
        )


if __name__ == "__main__":
    unittest.main()
