"""Offline provenance modes must never conceal current-source incompatibility."""
import copy, tempfile, unittest
from pathlib import Path
from unittest.mock import patch
import audit_contract as audit
import proof_contract as proof

class SourceIntegrity(unittest.TestCase):
    def setUp(self):
        self.source = proof.read_json(proof.HERE / 'source-adapter.json')
        self.selection = proof.read_json(proof.HERE / 'proof-selection.json')

    def test_historical_reference_matches_all_recorded_hashes(self):
        proof.inventory('historical')

    def test_missing_reference_fails_without_worktree_fallback(self):
        with tempfile.TemporaryDirectory() as tmp, patch.object(audit, 'ROOT', Path(tmp)):
            with self.assertRaisesRegex(ValueError, 'historical reference/blob unavailable'):
                proof.inventory('historical')

    def test_missing_commit_and_missing_blob_fail(self):
        with self.assertRaisesRegex(ValueError, 'historical reference/blob unavailable'):
            proof.historical_bytes('0' * 40, 'lib/main.dart')
        with self.assertRaisesRegex(ValueError, 'historical reference/blob unavailable'):
            proof.historical_bytes(audit.REFERENCE_SHA, 'missing-proof-source.dart')

    def test_tampered_historical_bytes_fail(self):
        with patch.object(proof, 'historical_bytes', return_value=b'tampered'):
            with self.assertRaisesRegex(ValueError, 'historical source hash mismatch'):
                proof.inventory('historical')

    def test_tampered_manifest_hash_fails(self):
        source = copy.deepcopy(self.source)
        source['sourceHashes'][next(iter(source['sourceHashes']))] = '0' * 64
        with patch.object(proof, 'read_json', side_effect=[source, self.selection]):
            with self.assertRaisesRegex(ValueError, 'historical source hash mismatch'):
                proof.inventory('historical')

    def test_manifest_reference_cannot_override_trusted_reference(self):
        source = copy.deepcopy(self.source); source['referenceSha'] = '0' * 40
        with patch.object(proof, 'read_json', side_effect=[source, self.selection]):
            with self.assertRaisesRegex(ValueError, 'explicit source/reference'):
                proof.inventory('historical')

    def test_current_drift_and_missing_sources_are_both_reported(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for name in self.source['sourceHashes'] | self.source['additionalChromeSourceHashes']:
                path = root / name; path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(proof.historical_bytes(self.source['referenceSha'], name))
            with patch.object(audit, 'ROOT', root):
                proof.inventory('current')
                (root / 'lib/core/data_processing/pattern_source_links.dart').write_bytes(b'drift')
                (root / '.github/workflows/flutter-pages.yml').unlink()
                with self.assertRaises(ValueError) as error:
                    proof.inventory('current')
                self.assertIn('current source drift: lib/core/data_processing/pattern_source_links.dart', str(error.exception))
                self.assertIn('current source missing/unsafe: .github/workflows/flutter-pages.yml', str(error.exception))

    def test_legacy_cli_stays_strict_current_check(self):
        with patch.object(proof, 'inventory', side_effect=ValueError('current source drift')) as inventory:
            with self.assertRaisesRegex(SystemExit, 'current source drift'):
                proof.main(['check-source'])
            inventory.assert_called_once_with('current')

    def test_workflow_covers_every_source_on_push_and_pull_request(self):
        workflow = (audit.ROOT / '.github/workflows/flutter-audit-contracts.yml').read_text()
        for event in ('pull_request:', 'push:'):
            block = workflow.split('  ' + event, 1)[1].split('\npermissions:', 1)[0]
            if event == 'pull_request:': block = block.split('\n  push:', 1)[0]
            for name in self.source['sourceHashes'] | self.source['additionalChromeSourceHashes'] | {'.github/workflows/pages.yml': ''}:
                self.assertIn("      - '" + name + "'", block)
        self.assertIn('fetch-depth: 0', workflow)
        self.assertIn('proof_contract.py check-historical-source', workflow)
        self.assertIn('current_source_projection.py', workflow)
        self.assertNotIn('continue-on-error:', workflow)

if __name__ == '__main__': unittest.main()
