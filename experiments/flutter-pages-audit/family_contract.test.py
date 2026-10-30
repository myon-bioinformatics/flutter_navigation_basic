"""Synthetic 48-receipt discovery tests; never browser execution evidence."""
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import patch
import family_contract as family

class FamilyTests(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  spec=importlib.util.spec_from_file_location('fixtures',Path(__file__).with_name('audit_contract.test.py'))
  cls.fixtures=importlib.util.module_from_spec(spec);spec.loader.exec_module(cls.fixtures)
  cls.fx=cls.fixtures.AuditContractTests;cls.fx.setUpClass()
  manifest=json.loads(family.MANIFEST.read_text())
  cls.routes={r['route'] for r in manifest['contracts']};cls.source_contracts=manifest['contracts']
 @classmethod
 def tearDownClass(cls):cls.fx.tearDownClass()
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.root=Path(self.tmp.name);self.manifest=self.root/'inventory.json'
  source='assets/screens.json'
  self.manifest.write_text(json.dumps({'schema':'flutter-source-family-discovery/1','caseCount':48,'viewports':[v['id'] for v in family.audit.VIEWPORTS],'referenceSha':family.audit.REFERENCE_SHA,'sourceHashes':{source:hashlib.sha256((family.audit.ROOT/source).read_bytes()).hexdigest()},'contracts':self.source_contracts}))
  self.pin=patch.object(family,'MANIFEST',self.manifest);self.pin.start()
  digest=hashlib.sha256(self.manifest.read_bytes()).hexdigest()
  for file in self.fx.paths:
   data=json.loads(file.read_text())
   if data['route'] not in self.routes:continue
   target=self.root/'cases'/file.parent.name;shutil.copytree(file.parent,target)
   shutil.copyfile(target/'initial.png',target/'stable.png')
   initial=data['captures'][0];stable=dict(initial,file='stable.png');data['captures'].append(stable)
   collector={'schema':'local-semantic-inventory-prototype/1','viewport':{'x':0,'y':0,'width':data['viewport']['width'],'height':data['viewport']['height']},'items':[{'key':key,'count':0,'nodes':[]} for key in sorted(family.expected_keys(next(c for c in self.source_contracts if c['route']==data['route']),data['viewport']))],'groups':[],'rawTruncated':False,'observedSemanticCount':0,'rawSemanticNodes':[],'limitations':['synthetic unknown matches']}
   data['observations']={'familyObservation':{'manifestSha256':digest,'scope':family.SCOPE,'snapshots':[{'phase':phase,'sampleMs':i*600,'collector':dict(collector,sampleMs=i*600),'capture':capture} for i,(phase,capture) in enumerate(zip(family.PHASES,[initial,stable]))]}}
   (target/family.audit.RECEIPT_NAME).write_text(json.dumps(data))
  self.file=next((self.root/'cases').rglob(family.audit.RECEIPT_NAME));self.original=self.file.read_bytes()
 def tearDown(self):self.pin.stop();self.tmp.cleanup()
 def result(self):return family.aggregate(self.root,self.fixtures.CANDIDATE)
 def change(self,fn):
  data=json.loads(self.original);fn(data);self.file.write_text(json.dumps(data))
 def test_actual48_valid_receipts_never_full_or_binding_pass(self):
  full,out=self.result();self.assertTrue(out['collectionEvidenceValid']);self.assertEqual(out['result'],'discovery_only');self.assertEqual(out['familyBindingUnverifiedPairs'],48)
  self.assertEqual(full['result'],'failed');self.assertEqual(out['full430MissingPairs'],382);self.assertFalse(out['acceptancePromoted']);self.assertFalse(out['familyBindingsVerified'])
 def test_unknown_and_failure_retained(self):
  for status in ['failed','unverified']:
   self.change(lambda d:d['checks'].__setitem__('scroll',{'status':status,'reason':'synthetic unresolved original contract'}))
   full,out=self.result();self.assertTrue(out['collectionEvidenceValid']);self.assertEqual(out['result'],'failed_or_unverified');self.assertEqual(full['requiredFailed']+full['requiredUnverified'],1)
 def test_family_provenance_snapshot_negatives(self):
  mutations=[lambda o:o.update(manifestSha256='0'*64),lambda o:o.update(scope='passed'),lambda o:o['snapshots'].pop(),lambda o:o['snapshots'][1].update(sampleMs=0),lambda o:o['snapshots'][1].update(sampleMs=599),lambda o:o.update(snapshots=o['snapshots']*13),lambda o:o['snapshots'][1].update(phase=family.PHASES[0]),lambda o:o['snapshots'][0].update(collector={}),lambda o:o['snapshots'][0].update(capture={}),lambda o:o['snapshots'][0].update(sampleMs=float('nan')),lambda o:o['snapshots'][1].update(capture=o['snapshots'][0]['capture'])]
  for mutation in mutations:
   self.change(lambda d:mutation(d['observations']['familyObservation']))
   with self.subTest(mutation=mutation):self.assertFalse(self.result()[1]['collectionEvidenceValid'])
 def test_raw_collector_and_keys_negative(self):
  mutations=[lambda c:c.update(items=[]),lambda c:c['items'].pop(),lambda c:c['items'].__setitem__(0,c['items'][1]),lambda c:c['items'][0].update(key='foreign'),lambda c:c['items'][0].update(count=-1),lambda c:c['items'][0].update(count=True),lambda c:c['items'][0].update(count=1),lambda c:c.update(rawTruncated=True),lambda c:c.pop('rawTruncated'),lambda c:c.update(rawSemanticNodes=None),lambda c:c.update(observedSemanticCount=-1),lambda c:c.update(sampleMs=123)]
  for mutation in mutations:
   self.change(lambda d:mutation(d['observations']['familyObservation']['snapshots'][0]['collector']))
   with self.subTest(mutation=mutation):self.assertFalse(self.result()[1]['collectionEvidenceValid'])
 def test_expected_navigation_keys_are_viewport_specific(self):
  contract=next(c for c in self.source_contracts if 'separateNavigation' in c)
  wide=family.expected_keys(contract,{'width':1180});compact=family.expected_keys(contract,{'width':390})
  self.assertIn('rail-home',wide);self.assertNotIn('rail-home',compact)
 def test_candidate_png_and_missing_extra_duplicate(self):
  self.change(lambda d:d.update(candidateSha='b'*40));self.assertFalse(self.result()[1]['collectionEvidenceValid']);self.file.write_bytes(self.original)
  image=self.file.parent/'stable.png';raw=image.read_bytes();image.write_bytes(b'tampered');self.assertFalse(self.result()[1]['collectionEvidenceValid']);image.write_bytes(raw)
  shutil.copytree(self.file.parent,self.root/'cases'/'duplicate');self.assertFalse(self.result()[1]['collectionEvidenceValid']);shutil.rmtree(self.root/'cases'/'duplicate')
  self.file.unlink();self.assertFalse(self.result()[1]['collectionEvidenceValid'])
 def test_manifest_source_reference_route_negative(self):
  original=json.loads(self.manifest.read_text())
  for mutation in [lambda d:d.update(schema='wrong'),lambda d:d.update(caseCount=4),lambda d:d.update(viewports=[]),lambda d:d.update(referenceSha='b'*40),lambda d:d['sourceHashes'].update({'assets/screens.json':'0'*64}),lambda d:d['contracts'].pop(),lambda d:d['contracts'].__setitem__(0,d['contracts'][1]),lambda d:d['contracts'][0].update(route='/not-public')]:
   data=copy.deepcopy(original);mutation(data);self.manifest.write_text(json.dumps(data))
   with self.assertRaises(ValueError):family.inventory()
 def test_preflight_delegates_live_pin_and_preserves_failure(self):
  with patch.object(family.focused,'preflight') as pre:
   out=family.preflight(self.root);pre.assert_called_once_with(self.root/'preflight.json');self.assertEqual(out['expectedCaseCount'],48)
  with patch.object(family.focused,'preflight',side_effect=ValueError('STALE_BASELINE')):
   with self.assertRaisesRegex(ValueError,'STALE_BASELINE'):family.preflight(self.root)
 def test_explicit_candidate_required(self):
  for value in [None,'','short','A'*40]:
   with self.assertRaises(ValueError):family.aggregate(self.root,value)
if __name__=='__main__':unittest.main()
