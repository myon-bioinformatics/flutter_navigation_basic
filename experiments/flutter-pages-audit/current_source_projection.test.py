import unittest
from pathlib import Path
from unittest.mock import patch
import current_source_projection as current
import proof_contract as proof

class CurrentProjection(unittest.TestCase):
    def test_reviewed_current_sources_match(self):
        self.assertFalse(current.verify()['archive_ready'])

    def mutated(self, mutate):
        original = proof.read_json
        manifest = original(current.MANIFEST)
        mutate(manifest)
        def read(path):
            return manifest if path == current.MANIFEST else original(path)
        with patch.object(proof, 'read_json', side_effect=read):
            with self.assertRaises(ValueError): current.verify()

    def test_missing_source_rejected(self):
        self.mutated(lambda m: m['sourceHashes'].pop(current.DART))

    def test_tampered_hash_rejected(self):
        self.mutated(lambda m: m['sourceHashes'].update({current.DART: '0' * 64}))

    def test_rebaseline_rejected(self):
        self.mutated(lambda m: m.update(referenceSha='0' * 40))

    def test_historical_binding_tampering_rejected(self):
        self.mutated(lambda m: m.update(historicalManifestSha256='0' * 64))

    def test_acceptance_and_retirement_cannot_be_promoted(self):
        for key in ('archive_ready', 'liveExecutionEnabled', 'acceptancePromoted'):
            with self.subTest(key=key): self.mutated(lambda m: m.update({key: True}))

    def test_decisions_cannot_be_silently_changed(self):
        self.mutated(lambda m: m['decisions'].update({'historical-evidence-promotion': 'adopt'}))

    def test_current_worktree_drift_fails(self):
        original = Path.read_bytes
        def read(path):
            return b'tampered current source' if path == current.audit.ROOT / current.DART else original(path)
        with patch.object(Path, 'read_bytes', read):
            with self.assertRaisesRegex(ValueError, 'current projection drift'): current.verify()

    def test_unreviewed_committed_difference_fails(self):
        original = proof.historical_bytes
        def read(ref, path):
            data = original(ref, path)
            return data + b'changed' if ref == current.REFERENCE and path == current.DART else data
        with patch.object(proof, 'historical_bytes', side_effect=read):
            with self.assertRaisesRegex(ValueError, 'unreviewed reference difference'): current.verify()

if __name__ == '__main__': unittest.main()
