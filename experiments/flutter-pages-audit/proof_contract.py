"""Offline proof-receipt integrity. Collection validity is not UI acceptance."""
import hashlib
import json
import math
from pathlib import Path
import sys
import audit_contract as audit

HERE = Path(__file__).resolve().parent
PHASES = ('spatial-initial', 'spatial-reference-1600', 'spatial-reference-1720', 'spatial-restored')

def read_json(path):
    return json.loads(Path(path).read_text(), parse_constant=lambda value: (_ for _ in ()).throw(ValueError('nonfinite JSON')))

def inventory():
    source = read_json(HERE/'source-adapter.json')
    selection = read_json(HERE/'proof-selection.json')
    if source.get('referenceSha') != audit.REFERENCE_SHA or source.get('caseCount') != 48 or selection.get('caseCount') != 8:
        raise ValueError('explicit source/reference/selection required')
    if selection.get('liveExecutionEnabled') is not False:
        raise ValueError('User requested no new measurement: live execution must remain disabled')
    if selection.get('referenceHeights') != [1600, 1720] or selection.get('retries') != 0 or selection.get('sourceProofAcceptanceEnabled') is not False:
        raise ValueError('unexpected measurement or acceptance policy')
    for name, digest in {**source['sourceHashes'], **source['additionalChromeSourceHashes']}.items():
        path = Path(name)
        if path.is_absolute() or '..' in path.parts or not audit.SHA256.fullmatch(digest):
            raise ValueError('invalid source path/hash')
        local = audit.ROOT/path
        if local.is_symlink() or not local.resolve().is_relative_to(audit.ROOT.resolve()) or hashlib.sha256(local.read_bytes()).hexdigest() != digest:
            raise ValueError('source drift: '+name)
    expected = {(route, viewport) for route in selection['routes'] for viewport in selection['viewports']}
    if len(expected) != 8 or not expected.issubset({(case['route'],case['viewportId']) for case in source['cases']}):
        raise ValueError('unbound route selection')
    return source, selection, expected

def finite(value):
    return type(value) in (int, float) and math.isfinite(value)

def box(value):
    return isinstance(value,dict) and set(value)=={'x','y','width','height'} and all(finite(v) for v in value.values()) and value['width']>=0 and value['height']>=0

def snapshot_problems(sample, expected):
    """Validate the actual supported raw collector shape, not inferred UI fitness."""
    errors=[]
    if any(sample.get(key)!=expected.get(key) for key in ('route','referenceSha','sourceHashes','locale','stateKey')):
        errors.append('snapshot source context mismatch')
    if sample.get('contextOrigin')!='driver-verified-context-not-independent-proof':errors.append('unsupported snapshot context')
    for key in ('enumerationComplete','nativeEnumerationComplete'):
        if sample.get(key) is not True:errors.append('incomplete '+key)
    if sample.get('rawTruncated') is not False or any(sample.get(key)!=[] for key in ('problems','traversalErrors','opaqueBoundaries')):errors.append('incomplete raw census')
    if not all(box(sample.get(key)) for key in ('viewport','envelope','header')) or sample.get('footer') is not None and not box(sample['footer']):errors.append('malformed snapshot geometry')
    if not isinstance(sample.get('location'),dict) or not isinstance(sample.get('displayObservation'),dict):errors.append('missing observed environment')
    nodes=sample.get('nodes');regions=sample.get('scrollRegions')
    if not isinstance(nodes,list) or not nodes or not all(isinstance(n,dict) for n in nodes):return errors+['missing node census']
    ids=[n.get('id') for n in nodes]
    if any(not isinstance(i,str) or not i for i in ids) or len(set(str(i) for i in ids))!=len(ids):errors.append('invalid node identities')
    for key,kind in [('semanticCount','semantic'),('nativeCount','native')]:
        if type(sample.get(key)) is not int or sample[key]!=sum(n.get('type')==kind for n in nodes):errors.append('census count mismatch')
    if type(sample.get('observedCandidateCount')) is not int or sample['observedCandidateCount']!=len(nodes) or type(sample.get('observedElementCount')) is not int or sample['observedElementCount']<len(nodes):errors.append('invalid raw census counts')
    if not isinstance(regions,list) or not all(isinstance(r,dict) for r in regions):errors.append('missing scroll census');regions=[]
    region_ids=[r.get('id') for r in regions]
    if any(not isinstance(i,str) or not i for i in region_ids) or len(set(str(i) for i in region_ids))!=len(region_ids):errors.append('invalid scroll identities')
    for node in nodes:
        if node.get('type') not in ('semantic','native') or not isinstance(node.get('tag'),str) or not isinstance(node.get('label'),str) or node.get('role') is not None and not isinstance(node['role'],str):errors.append('malformed node identity')
        if not box(node.get('box')) or not box(node.get('clip')) or type(node.get('visible')) is not bool or type(node.get('unsupportedClip')) is not bool:errors.append('malformed node geometry')
        if any(node.get(k) is not True for k in ('completeAncestry','clipEnumerationComplete','descendantEnumerationComplete')):errors.append('incomplete node census')
        for key,allowed in [('ancestorIds',ids),('rawDescendantIds',ids),('scrollAncestorIds',region_ids)]:
            values=node.get(key)
            if not isinstance(values,list) or any(not isinstance(v,str) or v not in allowed for v in values) or len(set(str(v) for v in values))!=len(values):errors.append('malformed node relation')
        clips=node.get('ancestorClips')
        if not isinstance(clips,list) or not clips or not all(box(c) for c in clips):errors.append('missing clip census')
    document=sample.get('document')
    if not isinstance(document,dict) or any(not finite(document.get(k)) or document[k]<0 for k in ('scrollWidth','clientWidth','scrollHeight','clientHeight')):errors.append('missing document geometry')
    for region in regions:
        if not box(region.get('box')) or any(not finite(region.get(k)) for k in ('scrollWidth','clientWidth','scrollHeight','clientHeight','scrollLeft','scrollTop')):errors.append('malformed scroll region')
    return errors

def proof_problems(receipt, directory, source_digest, selection_digest):
    proof = receipt.get('observations', {}).get('familyProof')
    if not isinstance(proof, dict) or proof.get('schema') != 'family-proof-observations/1':
        return ['proof not measured; legacy evidence is not converted']
    problems = []
    if proof.get('sourceManifestSha256') != source_digest or proof.get('selectionSha256') != selection_digest or proof.get('acceptancePromoted') is not False:
        problems.append('unbound source/selection or acceptance promotion')
    spatial = proof.get('spatial', {})
    frames = spatial.get('frames')
    if not isinstance(frames, list) or len(frames) != 4 or [f.get('phase') for f in frames if isinstance(f,dict)] != list(PHASES):
        return problems+['four exact bounded phases required']
    if spatial.get('complete') is not True or spatial.get('errors') != []:
        problems.append('incomplete observation, not collection success')
    if spatial.get('budget') != {'captures':4,'viewportChanges':3,'referenceHeights':[1600,1720],'retries':0}:
        problems.append('unexpected capture budget')
    view = receipt['viewport']
    expected_heights = [view['height'],1600,1720,view['height']]
    changes = [{'width':view['width'],'height':height,'phase':phase} for height,phase in [(1600,'reference-1600'),(1720,'reference-1720'),(view['height'],'restore')]]
    if spatial.get('viewportChanges') != changes:
        problems.append('viewport transitions outside explicit budget')
    names, times = [], []
    candidates=read_json(HERE/'source-adapter.json')['cases']
    expected=next((c['spatial'] for c in candidates if c['route']==receipt['route'] and c['viewportId']==view['id']),None)
    if expected is None:return problems+['unbound source case']
    for frame,height in zip(frames,expected_heights):
        sample, after = frame.get('sample'), frame.get('afterCapture')
        if not isinstance(sample,dict) or not isinstance(after,dict):
            problems.append('missing actual before/after sample');continue
        if sample.get('schema') != 'source-spatial-observation/1' or sample.get('observedRoute') != receipt['route'] or sample.get('referenceSha') != receipt['referenceSha'] or sample.get('viewport') != {'x':0,'y':0,'width':view['width'],'height':height}:
            problems.append('snapshot identity or viewport mismatch')
        problems.extend(snapshot_problems(sample,expected))
        problems.extend(snapshot_problems(after,expected))
        for value in (sample.get('sampleMs'),after.get('sampleMs')):
            if type(value) not in (int,float) or not math.isfinite(value):problems.append('invalid sample timestamp')
        before_fields={k:v for k,v in sample.items() if k!='sampleMs'}
        after_fields={k:v for k,v in after.items() if k!='sampleMs'}
        if before_fields != after_fields or frame.get('captureStable') is not True:
            problems.append('capture stability not established')
        times.extend([sample.get('sampleMs'),after.get('sampleMs')])
        capture=frame.get('capture');names.append(capture.get('file') if isinstance(capture,dict) else None)
        problems.extend(audit.validate_captures([capture],Path(directory),{'width':view['width'],'height':height,'deviceScaleFactor':1}))
    if len(set(names)) != 4:problems.append('duplicate proof captures')
    if all(type(t) in (int,float) and math.isfinite(t) for t in times) and any(b<=a for a,b in zip(times,times[1:])):
        problems.append('unordered snapshots')
    metadata=proof.get('buildMetadata')
    if not isinstance(metadata,dict) or not isinstance(metadata.get('raw'),str) or hashlib.sha256(metadata['raw'].encode()).hexdigest()!=metadata.get('sha256'):
        problems.append('unbound build metadata')
    else:
        try:
            if json.loads(metadata['raw'])['repository']['revision']['sha']!=receipt['referenceSha']:problems.append('stale build metadata')
        except (ValueError,KeyError,TypeError):problems.append('malformed build metadata')
    return problems

def aggregate(directory, candidate):
    _,_,expected=inventory();directory=Path(directory)
    source_digest=hashlib.sha256((HERE/'source-adapter.json').read_bytes()).hexdigest()
    selection_digest=hashlib.sha256((HERE/'proof-selection.json').read_bytes()).hexdigest()
    full=audit.aggregate(directory/'cases',candidate_sha=candidate)
    seen=set();problems=[]
    for file in sorted((directory/'cases').rglob(audit.RECEIPT_NAME)):
        try:
            if file.is_symlink():raise ValueError('symlink receipt')
            receipt=read_json(file);key=(receipt['route'],receipt['viewport']['id'])
            if key in seen or key not in expected:raise ValueError('duplicate or unexpected pair')
            seen.add(key);issues=proof_problems(receipt,file.parent,source_digest,selection_digest)
        except (ValueError,KeyError,TypeError,OSError) as error:issues=[str(error)]
        if issues:problems.append({'receipt':str(file.relative_to(directory)),'problems':issues})
    valid=seen==expected and not problems and not full['problems'] and not full['duplicates']
    return {'schema':'flutter-proof-discovery-summary/1','collectionEvidenceValid':valid,'proofProblems':problems,'expectedPairs':sorted(expected),
            'observedPairs':sorted(seen),'acceptancePromoted':False,'uiAcceptance':'unverified','liveExecutionEnabled':False,
            'full430Result':full['result'],'full430Complete':full['coverage']['completeExactlyOnce']}

if __name__=='__main__':
    if sys.argv[1:]==['check-source']:
        inventory();print('Offline source hashes and disabled-live policy verified; no browser measurements.')
    else:
        raise SystemExit('Only offline check-source CLI is enabled. No live measurement is requested.')
