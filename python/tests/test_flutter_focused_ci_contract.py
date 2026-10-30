"""Offline wiring guard: focused product checks cannot silently go unused."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]


class FocusedCIContract(unittest.TestCase):
    def test_generic_scope_is_outside_default_test_directory(self):
        config = (ROOT / 'e2e/playwright.generic-responsive.config.ts').read_text()
        self.assertIn("testDir: './focused'", config)
        self.assertTrue((ROOT / 'e2e/focused/generic_responsive.spec.ts').is_file())
        self.assertFalse((ROOT / 'e2e/tests/generic_responsive.spec.ts').exists())
        self.assertIn("testDir: './tests'", (ROOT / 'e2e/playwright.config.ts').read_text())

    def test_candidate_build_and_independent_failure_paths(self):
        workflow = (ROOT / '.github/workflows/non-dart.yml').read_text()
        lane = workflow.split('  playwright:\n', 1)[1].split('  # Chromium-only contract', 1)[0]
        self.assertIn('ref: ${{ github.event.pull_request.head.sha || github.sha }}', lane)
        self.assertIn('test "$(git rev-parse HEAD)" = "$EXPECTED_SHA"', lane)
        self.assertIn('id: candidate_build', lane)
        self.assertEqual(lane.count("if: always() && steps.candidate_build.outcome == 'success' && steps.candidate_provenance.outcome == 'success' && steps.browser_install.outcome == 'success'"), 3)
        self.assertIn('--config playwright.generic-responsive.config.ts', lane)
        self.assertIn('--project mobile-webkit --project mobile-chromium --workers 1 --retries 0 --timeout 90000 --trace on', lane)
        self.assertIn('--project chromium --project firefox --project webkit --project mobile-chromium --project mobile-webkit', lane)
        self.assertNotIn('continue-on-error:', lane)
        self.assertIn('exit "$status"', lane)
        for name in ['playwright-generic-responsive.xml', 'playwright-mobile-door.xml']:
            self.assertIn('build/test-results/' + name, lane)
            self.assertIn('junit-playwright-e2e/' + name, workflow)
        for directory in ['build/playwright-mobile-door/', 'e2e/generic-responsive-results/', 'e2e/generic-responsive-report/']:
            self.assertIn(directory, lane)
        self.assertIn('path: build/test-results/playwright-*.xml', lane)
        self.assertIn('if-no-files-found: error', lane)


if __name__ == '__main__':
    unittest.main()
