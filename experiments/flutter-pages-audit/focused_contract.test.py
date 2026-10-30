"""Synthetic focused-summary negative cases; original receipt validator tested separately."""
import importlib.util
import json
from pathlib import Path
import shutil
import tempfile
import unittest
import focused_contract as focused

class FocusedTests(unittest.TestCase):
    def good(self):
        all_pairs = {(r['route'], v['id']) for r in focused.audit.make_catalogue()['routes'] for v in focused.audit.VIEWPORTS}
        return {'missing': [{'route': r, 'viewport': v} for r,v in sorted(all_pairs-focused.EXPECTED)],
            'problems': [], 'duplicates': [], 'coverage': {'receiptFiles':4,'uniqueUrlViewportPairs':4,'validEvidencePairs':4,'completeExactlyOnce':False},
            'referenceSha':focused.audit.REFERENCE_SHA,'candidateShas':['a'*40], 'result':'failed',
            'observedFailed':0,'requiredFailed':0,'requiredUnverified':0,'optionalUnverified':8}
    def test_four_only_keeps_full430_failed(self):
        x=focused.focused_result(self.good()); self.assertEqual(x['result'],'passed');self.assertEqual(x['full430Result'],'failed');self.assertFalse(x['full430Complete']);self.assertEqual(x['optionalUnverified'],8)
    def test_missing_extra_duplicate_invalid_and_wrong_pair_fail(self):
        changes=[lambda x:x['missing'].pop(),lambda x:x['missing'].append(x['missing'][0]),lambda x:x['problems'].append('stale capture'),lambda x:x['duplicates'].append('duplicate')]
        for key in ['receiptFiles','uniqueUrlViewportPairs','validEvidencePairs']:
            changes.append(lambda x,key=key:x['coverage'].__setitem__(key,3))
        changes.append(lambda x:x['missing'].__setitem__(0,{'route':'/tools/http/request-draft','viewport':'wide-1180x757'}))
        for change in changes:
            x=self.good();change(x);self.assertEqual(focused.focused_result(x)['result'],'failed_or_unverified')
    def test_failed_and_unknown_never_pass(self):
        for key in ['observedFailed','requiredUnverified']:
            x=self.good();x[key]=1;self.assertEqual(focused.focused_result(x)['result'],'failed_or_unverified')
    def test_zero_coverage_fails(self):
        x=self.good();x['coverage']={'receiptFiles':0,'uniqueUrlViewportPairs':0,'validEvidencePairs':0,'completeExactlyOnce':False};self.assertFalse(focused.focused_result(x)['focusedEvidenceValid'])

class ReceiptIntegrationTests(unittest.TestCase):
    def test_real_validator_four_receipts_and_invalid_evidence(self):
        spec=importlib.util.spec_from_file_location('fixtures',Path(__file__).with_name('audit_contract.test.py'))
        fixtures=importlib.util.module_from_spec(spec);spec.loader.exec_module(fixtures)
        cls=fixtures.AuditContractTests;cls.setUpClass()
        try:
            with tempfile.TemporaryDirectory() as tmp:
                root=Path(tmp)
                for file in cls.paths:
                    data=json.loads(file.read_text())
                    if (data['route'],data['viewport']['id']) in focused.EXPECTED:
                        shutil.copytree(file.parent,root/file.parent.name)
                result=lambda:focused.focused_result(focused.audit.aggregate(root,candidate_sha=fixtures.CANDIDATE))
                self.assertEqual(result()['result'],'passed')
                receipt=next(root.rglob(focused.audit.RECEIPT_NAME));original=receipt.read_bytes()
                data=json.loads(original);data['candidateSha']='b'*40;receipt.write_text(json.dumps(data))
                self.assertEqual(result()['result'],'failed_or_unverified');receipt.write_bytes(original)
                image=receipt.parent/'initial.png';original_image=image.read_bytes();image.write_bytes(b'tampered')
                self.assertEqual(result()['result'],'failed_or_unverified');image.write_bytes(original_image)
                shutil.copytree(receipt.parent,root/'duplicate')
                self.assertEqual(result()['result'],'failed_or_unverified');shutil.rmtree(root/'duplicate')
                receipt.unlink();self.assertEqual(result()['result'],'failed_or_unverified')
        finally:cls.tearDownClass()

if __name__=='__main__':unittest.main()
