"""Verify a proposed source-only projection; never promote historical UI evidence."""
import hashlib
from pathlib import Path
import audit_contract as audit
import proof_contract as proof

REFERENCE = '00eb2c4fc5576489e5a4034736ffcc5502b67671'
MANIFEST = proof.HERE / 'current-source-projection.v1.json'
OLD_WORKFLOW = '.github/workflows/flutter-pages.yml'
NEW_WORKFLOW = '.github/workflows/pages.yml'
DART = 'lib/core/data_processing/pattern_source_links.dart'


def verify():
    source, _, _ = proof.inventory('historical')
    projection = proof.read_json(MANIFEST)
    if (projection.get('schema') != 'flutter-current-source-projection/1'
            or projection.get('referenceSha') != REFERENCE
            or projection.get('historicalReferenceSha') != audit.REFERENCE_SHA
            or projection.get('historicalManifestSha256') != hashlib.sha256((proof.HERE / 'source-adapter.json').read_bytes()).hexdigest()
            or projection.get('status') != 'proposed-source-only'
            or any(projection.get(key) is not False for key in ('liveExecutionEnabled', 'acceptancePromoted', 'archive_ready'))
            or projection.get('uiAcceptance') != 'unverified'):
        raise ValueError('invalid projection identity, provenance or acceptance policy')
    original = source['sourceHashes'] | source['additionalChromeSourceHashes']
    expected_paths = (set(original) - {OLD_WORKFLOW}) | {NEW_WORKFLOW}
    if set(projection['sourceHashes']) != expected_paths:
        raise ValueError('projection source coverage changed')
    if projection.get('decisions') != {
        DART: 'proposed-adopt-comment-only-change',
        OLD_WORKFLOW: 'proposed-reject-as-current-path-preserve-historical-record',
        NEW_WORKFLOW: 'proposed-adopt-renamed-workflow-and-CI-gate-name',
        'historical-evidence-promotion': 'reject',
        'live-measurement': 'not-authorized',
        'archive-retirement': 'not-authorized',
    }:
        raise ValueError('projection decisions changed')
    for old_path in original:
        new_path = NEW_WORKFLOW if old_path == OLD_WORKFLOW else old_path
        before = proof.historical_bytes(audit.REFERENCE_SHA, old_path)
        after = proof.historical_bytes(REFERENCE, new_path)
        expected = before
        if old_path == DART:
            expected = before.replace(b'(flutter-pages.yml)', b'(pages.yml)')
        elif old_path == OLD_WORKFLOW:
            expected = before.replace(b'name: Flutter Web Pages\n', b'name: Pages\n').replace(b'workflows: ["Flutter"]', b'workflows: ["CI"]').replace(b'                  "Flutter",', b'                  "CI",')
        if after != expected:
            raise ValueError('unreviewed reference difference: ' + new_path)
        digest = hashlib.sha256(after).hexdigest()
        if projection['sourceHashes'][new_path] != digest:
            raise ValueError('projection hash mismatch: ' + new_path)
        local = audit.ROOT / new_path
        if local.is_symlink() or not local.resolve().is_relative_to(audit.ROOT.resolve()) or not local.is_file() or hashlib.sha256(local.read_bytes()).hexdigest() != digest:
            raise ValueError('current projection drift: ' + new_path)
    return projection


if __name__ == '__main__':
    try:
        verify()
    except (ValueError, OSError, KeyError, TypeError) as error:
        raise SystemExit(str(error))
    print('Proposed current source projection matches reviewed commit bytes. UI acceptance unverified; archive_ready=false; no live measurements.')
