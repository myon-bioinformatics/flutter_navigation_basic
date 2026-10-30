import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import struct
import tempfile
import unittest
import zlib
import proof_contract as proof
import audit_contract as audit


def png(width,height):
    def chunk(kind,data):return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
    return b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',width,height,8,2,0,0,0))+chunk(b'IDAT',zlib.compress((b'\0'+b'\0'*(width*3))*height))+chunk(b'IEND',b'')


class ProofContracts(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.directory=Path(self.temp.name)
        source_digest='a'*64;selection_digest='b'*64
        viewport={'id':'compact-390x500','width':390,'height':500,'deviceScaleFactor':1}
        frames=[]
        for i,(phase,height) in enumerate(zip(proof.PHASES,[500,1600,1720,500])):
            raw=png(390,height);name=phase+'.png';(self.directory/name).write_bytes(raw)
            sample={'schema':'source-spatial-observation/1','sampleMs':1000+i*1000,'observedRoute':'/screen136','referenceSha':audit.REFERENCE_SHA,'viewport':{'x':0,'y':0,'width':390,'height':height}}
            expected=next(c['spatial'] for c in proof.read_json(proof.HERE/'source-adapter.json')['cases'] if c['route']=='/screen136' and c['viewportId']==viewport['id'])
            sample.update({k:copy.deepcopy(expected[k]) for k in ('route','referenceSha','sourceHashes','locale','stateKey')})
            rect={'x':0,'y':0,'width':390,'height':height}
            sample.update(contextOrigin='driver-verified-context-not-independent-proof',enumerationComplete=True,nativeEnumerationComplete=True,rawTruncated=False,problems=[],traversalErrors=[],opaqueBoundaries=[],envelope=rect.copy(),header=rect.copy(),footer=None,location={'hash':'#/screen136'},displayObservation={'flutterTextScaleObserved':False,'flutterThemeObserved':False},semanticCount=1,nativeCount=0,observedElementCount=1,observedCandidateCount=1,scrollRegions=[],document={'scrollWidth':390,'clientWidth':390,'scrollHeight':height,'clientHeight':height})
            sample['nodes']=[{'id':'synthetic-only','type':'semantic','tag':'FLT-SEMANTICS','label':'Synthetic fixture, not UI evidence','role':None,'box':rect.copy(),'clip':rect.copy(),'visible':True,'unsupportedClip':False,'completeAncestry':True,'clipEnumerationComplete':True,'descendantEnumerationComplete':True,'ancestorIds':[],'rawDescendantIds':[],'scrollAncestorIds':[],'ancestorClips':[rect.copy()]}]
            after=copy.deepcopy(sample);after['sampleMs']+=1
            frames.append({'phase':phase,'sample':sample,'afterCapture':after,'captureStable':True,'capture':{'file':name,'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}})
        raw=json.dumps({'repository':{'revision':{'sha':audit.REFERENCE_SHA}}})
        self.receipt={'route':'/screen136','referenceSha':audit.REFERENCE_SHA,'viewport':viewport,'observations':{'familyProof':{'schema':'family-proof-observations/1','sourceManifestSha256':source_digest,'selectionSha256':selection_digest,'acceptancePromoted':False,'spatial':{'complete':True,'errors':[],'budget':{'captures':4,'viewportChanges':3,'referenceHeights':[1600,1720],'retries':0},'viewportChanges':[{'width':390,'height':h,'phase':p} for h,p in [(1600,'reference-1600'),(1720,'reference-1720'),(500,'restore')]],'frames':frames},'buildMetadata':{'raw':raw,'sha256':hashlib.sha256(raw.encode()).hexdigest()}}}}
        self.args=(self.directory,source_digest,selection_digest)
    def tearDown(self):self.temp.cleanup()
    def problems(self):return proof.proof_problems(self.receipt,*self.args)
    def test_valid_capture_packet_is_not_ui_acceptance(self):self.assertEqual(self.problems(),[]);self.assertFalse(self.receipt['observations']['familyProof']['acceptancePromoted'])
    def test_legacy_remains_unmeasured(self):self.receipt['observations'].clear();self.assertIn('legacy',self.problems()[0])
    def test_disabled_live_source_inventory(self):source,selection,pairs=proof.inventory();self.assertFalse(selection['liveExecutionEnabled']);self.assertEqual(len(pairs),8)

for name, mutate in {
 'wrong_source_digest':lambda p:p.update(sourceManifestSha256='c'*64),
 'promoted':lambda p:p.update(acceptancePromoted=True),
 'extra_frame':lambda p:p['spatial']['frames'].append(copy.deepcopy(p['spatial']['frames'][0])),
 'missing_frame':lambda p:p['spatial']['frames'].pop(),
 'error_hidden':lambda p:p['spatial']['errors'].append('failure'),
 'retry_budget':lambda p:p['spatial']['budget'].update(retries=1),
 'missing_restore':lambda p:p['spatial']['viewportChanges'].pop(),
 'wrong_dimensions':lambda p:p['spatial']['frames'][1]['sample']['viewport'].update(height=500),
 'changed_after_capture':lambda p:p['spatial']['frames'][0]['afterCapture'].update(observedRoute='/screen5'),
 'forged_stability':lambda p:p['spatial']['frames'][0].update(captureStable=False),
 'duplicate_capture':lambda p:p['spatial']['frames'][1].update(capture=copy.deepcopy(p['spatial']['frames'][0]['capture'])),
 'bad_capture_hash':lambda p:p['spatial']['frames'][0]['capture'].update(sha256='0'*64),
 'bad_metadata_hash':lambda p:p['buildMetadata'].update(sha256='0'*64),
 'bad_metadata_json':lambda p:p.update(buildMetadata={'raw':'x','sha256':hashlib.sha256(b'x').hexdigest()}),
 'capture_time_reversed':lambda p:p['spatial']['frames'][0]['afterCapture'].update(sampleMs=999),
 'capture_crosses_next_phase':lambda p:p['spatial']['frames'][0]['afterCapture'].update(sampleMs=2001),
 'missing_nodes':lambda p:p['spatial']['frames'][0]['sample'].pop('nodes'),
 'extra_candidate_count':lambda p:p['spatial']['frames'][0]['sample'].update(observedCandidateCount=2),
 'too_few_elements':lambda p:p['spatial']['frames'][0]['sample'].update(observedElementCount=0),
 'wrong_counts':lambda p:p['spatial']['frames'][0]['sample'].update(nativeCount=1),
 'missing_hashes':lambda p:p['spatial']['frames'][0]['sample'].pop('sourceHashes'),
 'missing_enumeration':lambda p:p['spatial']['frames'][0]['sample'].pop('enumerationComplete'),
 'unknown_descendant':lambda p:p['spatial']['frames'][0]['sample']['nodes'][0].update(rawDescendantIds=['missing']),
 'missing_timestamp':lambda p:p['spatial']['frames'][0]['sample'].pop('sampleMs'),
}.items():
 def check(self, mutate=mutate):mutate(self.receipt['observations']['familyProof']);self.assertTrue(self.problems())
 setattr(ProofContracts,'test_'+name,check)

if __name__=='__main__':unittest.main()
