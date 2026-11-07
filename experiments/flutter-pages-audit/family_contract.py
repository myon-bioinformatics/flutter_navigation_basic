"""Read-only 48-case discovery evidence validation; never promotes acceptance."""
import hashlib
import json
import math
import os
from pathlib import Path
import sys
import audit_contract as audit
import focused_contract as focused

SCOPE = 'read-only source-family discovery; no acceptance promotion'
PHASES = ('after-reset-initial', 'after-reset-stable')
MANIFEST = Path(__file__).with_name('family-inventory.json')

def inventory():
    raw = MANIFEST.read_bytes()
    data = json.loads(raw)
    if (data.get('schema') != 'flutter-source-family-discovery/1' or
        type(data.get('caseCount')) is not int or data['caseCount'] != 48 or
        data.get('viewports') != [v['id'] for v in audit.VIEWPORTS]):
        raise ValueError('family schema/count/viewports mismatch')
    if data.get('referenceSha') != audit.REFERENCE_SHA:
        raise ValueError('family baseline mismatch')
    hashes = data.get('sourceHashes')
    if not isinstance(hashes, dict) or not hashes:
        raise ValueError('missing source hashes')
    for name, digest in hashes.items():
        path = Path(name)
        if path.is_absolute() or '..' in path.parts or not isinstance(digest, str) or not audit.SHA256.fullmatch(digest):
            raise ValueError('unsafe or invalid source hash')
        source = audit.ROOT / path
        if not source.resolve().is_relative_to(audit.ROOT.resolve()) or source.is_symlink() or hashlib.sha256(source.read_bytes()).hexdigest() != digest:
            raise ValueError('family source drift: '+name)
    contracts = data.get('contracts')
    if not isinstance(contracts, list) or len(contracts) != 24 or any(not isinstance(c, dict) or not isinstance(c.get('route'), str) for c in contracts):
        raise ValueError('24 explicit route contracts required')
    routes = [c['route'] for c in contracts]
    canonical = {r['route'] for r in audit.make_catalogue()['routes'] if not r['alias']}
    if len(set(routes)) != 24 or not set(routes).issubset(canonical):
        raise ValueError('duplicate/unknown/alias family route')
    for contract in contracts:
        for viewport in audit.VIEWPORTS: expected_keys(contract, viewport)
    return data, hashlib.sha256(raw).hexdigest(), {(r,v['id']) for r in routes for v in audit.VIEWPORTS}

def finite(value):
    return type(value) in (int, float) and math.isfinite(value) and value >= 0

def expected_keys(contract, viewport):
    if 'items' in contract:
        items = contract['items'] + contract.get('separateNavigation', {}).get('compact' if viewport['width'] < 900 else 'wide', {}).get('items', [])
        keys = [item['key'] for item in items]
    else:
        keys = [group['key']+':'+part['key'] for group in contract['groups'] for part in group['parts']]
    if not keys or any(not isinstance(k, str) or not k for k in keys) or len(set(keys)) != len(keys):
        raise ValueError('empty/duplicate/invalid source item keys')
    return set(keys)

def observation_problems(data, digest, contracts):
    obs = data.get('observations', {}).get('familyObservation')
    if not isinstance(obs, dict) or obs.get('manifestSha256') != digest or obs.get('scope') != SCOPE:
        return ['missing/wrong family observation provenance']
    snapshots = obs.get('snapshots')
    if not isinstance(snapshots, list) or not 2 <= len(snapshots) <= 24:
        return ['between two and 24 family snapshots required']
    keys = expected_keys(contracts[data['route']], data['viewport'])
    phases, times, captures = [], [], []
    for snap in snapshots:
        if not isinstance(snap, dict) or not isinstance(snap.get('phase'), str) or not finite(snap.get('sampleMs')):
            return ['invalid snapshot phase/timestamp']
        phases.append(snap['phase']); times.append(snap['sampleMs'])
        collector = snap.get('collector')
        if (not isinstance(collector, dict) or collector.get('schema') != 'local-semantic-inventory-prototype/1'
            or collector.get('viewport') != {'x':0,'y':0,'width':data['viewport']['width'],'height':data['viewport']['height']}
            or not isinstance(collector.get('items'), list) or not isinstance(collector.get('groups'), list)):
            return ['invalid raw collector shape/viewport']
        items = collector['items']
        if (collector.get('rawTruncated') is not False or not finite(collector.get('sampleMs')) or collector.get('sampleMs') != snap['sampleMs']
            or type(collector.get('observedSemanticCount')) is not int or not 0 <= collector['observedSemanticCount'] <= 2000
            or not isinstance(collector.get('rawSemanticNodes'), list)
            or len(collector['rawSemanticNodes']) > collector['observedSemanticCount']
            or any(not isinstance(n, dict) for n in collector['rawSemanticNodes'])):
            return ['truncated/malformed raw collector evidence or timestamp mismatch']
        if (len(items) != len(keys) or any(not isinstance(item, dict) or not isinstance(item.get('key'), str) for item in items)
            or {item['key'] for item in items} != keys
            or any(type(item.get('count')) is not int or item['count'] < 0 or not isinstance(item.get('nodes'), list)
                   or len(item['nodes']) != item['count'] or any(not isinstance(n, dict) for n in item['nodes']) for item in items)):
            return ['missing/duplicate/unexpected item keys or malformed match counts']
        capture = snap.get('capture')
        if not isinstance(capture, dict) or capture not in data.get('captures', []):
            return ['snapshot capture not bound to validated receipt captures']
        captures.append(capture.get('file'))
    if len(set(phases)) != len(phases) or phases[:2] != list(PHASES) or times[1]-times[0] < 600 or any(b <= a for a,b in zip(times,times[1:])):
        return ['missing/duplicate/out-of-order snapshot phases/timestamps']
    if len(set(captures)) != len(captures):
        return ['each snapshot requires its own raw capture']
    return []

def aggregate(directory, candidate):
    if not isinstance(candidate, str) or not audit.SHA40.fullmatch(candidate):
        raise ValueError('Full explicit candidate SHA required')
    manifest, digest, expected = inventory()
    directory = Path(directory)
    full = audit.aggregate(directory/'cases', candidate_sha=candidate)
    problems = []
    for file in sorted((directory/'cases').rglob(audit.RECEIPT_NAME)):
        try:
            data = json.loads(file.read_text(), parse_constant=lambda v: (_ for _ in ()).throw(ValueError(v)))
            issues = observation_problems(data, digest, {c['route']:c for c in manifest['contracts']})
        except (ValueError, TypeError, KeyError, AttributeError, OSError) as error:
            issues = ['malformed family evidence: '+str(error)]
        if issues: problems.append({'receipt':str(file.relative_to(directory)), 'problems':issues})
    all_pairs = {(r['route'],v['id']) for r in audit.make_catalogue()['routes'] for v in audit.VIEWPORTS}
    missing = [(x['route'],x['viewport']) for x in full['missing']]
    coverage = full['coverage']
    valid = (len(missing)==382 and set(missing)==all_pairs-expected and
             not full['problems'] and not full['duplicates'] and not problems and
             coverage['receiptFiles']==48 and coverage['uniqueUrlViewportPairs']==48 and coverage['validEvidencePairs']==48 and
             full['candidateShas']==[candidate] and full['result']=='failed' and not coverage['completeExactlyOnce'])
    result = {'schema':'flutter-family-discovery/1','scope':SCOPE,'referenceSha':manifest['referenceSha'],
        'candidateSha':candidate,'manifestSha256':digest,'expectedPairs':sorted(expected),
        'collectionEvidenceValid':valid,'result':'discovery_only' if valid and not full['observedFailed'] and not full['requiredUnverified'] else 'failed_or_unverified',
        'acceptancePromoted':False,'familyBindingsVerified':False,'familyBindingUnverifiedPairs':48,
        'requiredFailed':full['requiredFailed'],'requiredUnverified':full['requiredUnverified'],
        'optionalUnverified':full['optionalUnverified'],'full430Result':full['result'],
        'full430Complete':coverage['completeExactlyOnce'],'full430MissingPairs':len(missing),'familyProblems':problems}
    return full, result

def preflight(directory):
    directory=Path(directory);directory.mkdir(parents=True,exist_ok=True)
    manifest,digest,expected=inventory()
    focused.preflight(directory/'preflight.json')
    result={'scope':SCOPE,'referenceSha':manifest['referenceSha'],'manifestSha256':digest,
            'sourceHashes':manifest['sourceHashes'],'expectedPairs':sorted(expected),'expectedCaseCount':48}
    (directory/'family-preflight.json').write_text(json.dumps(result,indent=2)+'\n')
    return result

if __name__=='__main__':
    mode,directory=sys.argv[1:];directory=Path(directory);directory.mkdir(parents=True,exist_ok=True)
    if mode=='preflight':preflight(directory)
    elif mode=='aggregate':
        full,result=aggregate(directory,os.environ.get('CANDIDATE_SHA'))
        (directory/'full430-incomplete-summary.json').write_text(json.dumps(full,indent=2)+'\n')
        (directory/'family-summary.json').write_text(json.dumps(result,indent=2)+'\n')
        print(json.dumps(result));raise SystemExit(0 if result['result']=='discovery_only' else 1)
    else:raise ValueError('Unknown family command')
