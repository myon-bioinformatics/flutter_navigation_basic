"""Four-case diagnostic only; full430 validator remains unchanged and red/incomplete."""
import json
import os
from pathlib import Path
import sys
from urllib.request import Request, urlopen
import audit_contract as audit

ROUTES = {'/tools/location/coordinates', '/tools/http/request-draft'}
EXPECTED = {(r, v['id']) for r in ROUTES for v in audit.VIEWPORTS}


def focused_result(full):
    all_pairs = {(r['route'], v['id']) for r in audit.make_catalogue()['routes'] for v in audit.VIEWPORTS}
    expected_missing = all_pairs - EXPECTED
    missing = [(x['route'], x['viewport']) for x in full['missing']]
    coverage = full['coverage']
    valid = (len(missing) == len(expected_missing) and set(missing) == expected_missing
             and not full['problems'] and not full['duplicates']
             and coverage['receiptFiles'] == 4 and coverage['uniqueUrlViewportPairs'] == 4
             and coverage['validEvidencePairs'] == 4)
    return {'schema': 'flutter-focused-diagnostic/1', 'scope': 'Coordinates and HTTP canonical only, two viewports; NOT full430 or aliases',
            'referenceSha': full['referenceSha'], 'candidateShas': full['candidateShas'],
            'expectedPairs': sorted(EXPECTED), 'focusedEvidenceValid': valid,
            'result': 'passed' if valid and not full['observedFailed'] and not full['requiredUnverified'] else 'failed_or_unverified',
            'full430Result': full['result'], 'full430Complete': coverage['completeExactlyOnce'],
            'requiredFailed': full['requiredFailed'], 'requiredUnverified': full['requiredUnverified'],
            'optionalUnverified': full['optionalUnverified'], 'full430MissingPairs': len(missing)}


def preflight(output):
    pinned = json.loads(Path(__file__).with_name('focused-baseline.json').read_text())
    catalogue = audit.make_catalogue()
    if pinned != {k: catalogue[k] for k in ('referenceSha', 'sourceHashes')}:
        raise ValueError('Reviewed baseline/source hashes changed; no automatic rebaseline')
    url = 'https://myon-bioinformatics.github.io/flutter_navigation_basic/assets/assets/diagnostics/build_metadata.json'
    with urlopen(Request(url, headers={'Cache-Control': 'no-cache'}), timeout=20) as response:
        metadata = json.load(response)
    actual = metadata.get('repository', {}).get('revision', {}).get('sha')
    output.write_text(json.dumps({'expected': pinned, 'servedSha': actual, 'url': url}, indent=2)+'\n')
    if actual != pinned['referenceSha']:
        raise ValueError('STALE_BASELINE: expected '+pinned['referenceSha']+', served '+str(actual))


if __name__ == '__main__':
    mode, directory = sys.argv[1:]
    directory = Path(directory); directory.mkdir(parents=True, exist_ok=True)
    if mode == 'preflight':
        preflight(directory / 'preflight.json')
    elif mode == 'aggregate':
        candidate = os.environ.get('CANDIDATE_SHA')
        if not candidate or not audit.SHA40.fullmatch(candidate):
            raise ValueError('Full candidate SHA required')
        full = audit.aggregate(directory / 'cases', candidate_sha=candidate)
        (directory / 'full430-incomplete-summary.json').write_text(json.dumps(full, indent=2)+'\n')
        result = focused_result(full)
        (directory / 'focused-summary.json').write_text(json.dumps(result, indent=2)+'\n')
        print(json.dumps(result))
        raise SystemExit(0 if result['result'] == 'passed' else 1)
    else:
        raise ValueError('Unknown focused command')
