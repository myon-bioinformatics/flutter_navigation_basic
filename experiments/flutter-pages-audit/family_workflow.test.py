"""Offline workflow event/scope tests; no workflow or browser is dispatched."""
import json
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[2]
WORKFLOW=ROOT/'.github/workflows/flutter-audit-focused-diagnostic.yml'

def eligible(event):
    return event.get('event')=='workflow_dispatch' and event.get('run_live_audit') is True

class GuardTests(unittest.TestCase):
    def test_only_explicit_manual_request(self):
        self.assertTrue(eligible({'event':'workflow_dispatch','run_live_audit':True}))
        for event in ['push','pull_request','pull_request_target','edited','synchronize','ready_for_review']:
            self.assertFalse(eligible({'event':event,'run_live_audit':True}))
        for flag in [None,False,'true',1]:self.assertFalse(eligible({'event':'workflow_dispatch','run_live_audit':flag}))
    def test_live_workflow_has_no_automatic_entry(self):
        text=WORKFLOW.read_text()
        for fragment in ['workflow_dispatch:','default: false',"if: github.event_name == 'workflow_dispatch' && inputs.run_live_audit == true",'timeout-minutes: 45','contents: read','persist-credentials: false','retention-days: 7']:
            self.assertIn(fragment,text)
        for fragment in ['pull_request:','push:','schedule:','pull_request_target:','types: [edited]']:self.assertNotIn(fragment,text)
        self.assertIn('ref: ${{ github.sha }}',text)
    def test_offline_ci_does_not_claim_or_run_browser_acceptance(self):
        text=(ROOT/'.github/workflows/flutter-audit-contracts.yml').read_text()
        self.assertIn('offline-contracts:',text);self.assertIn('proof_contract.py check-source',text)
        self.assertIn('does NOT mean',text)
        for forbidden in ['npm install','npm exec','playwright install','playwright test','workflow_dispatch:','family_contract.py preflight']:
            self.assertNotIn(forbidden,text)
    def test_new_probe_configuration_is_disabled(self):
        selection=json.loads((ROOT/'experiments/flutter-pages-audit/proof-selection.json').read_text())
        self.assertFalse(selection['liveExecutionEnabled']);self.assertFalse(selection['sourceProofAcceptanceEnabled'])
        self.assertEqual(selection['maximumProofCaptures'],32);self.assertEqual(selection['maximumViewportChanges'],24)
        config=(ROOT/'experiments/flutter-pages-audit/proof.playwright.config.cjs').read_text()
        self.assertIn('selection.liveExecutionEnabled!==true',config)
        spec=(ROOT/'experiments/flutter-pages-audit/audit.spec.cjs').read_text()
        self.assertIn('if (proofMode && proofSelection.liveExecutionEnabled !== true) throw new Error',spec)
    def test_full_audit_and_comparison_are_also_manual_only(self):
        for name in ['flutter-pages-audit.yml','ui-showcase-comparison.yml']:
            text=(ROOT/'.github/workflows'/name).read_text()
            self.assertIn('workflow_dispatch:',text);self.assertIn('default: false',text)
            self.assertIn("if: github.event_name == 'workflow_dispatch' && inputs.run_live_audit == true",text)
            for automatic in ['pull_request:','push:','schedule:']:self.assertNotIn(automatic,text)
        full=(ROOT/'experiments/flutter-pages-audit/full.playwright.config.cjs').read_text()
        self.assertNotIn('grep:',full)
        self.assertIn('workers: 2',full);self.assertIn('retries: 0',full)
    def test_legacy_manifest_retains24structures_and48pairs(self):
        manifest=json.loads((ROOT/'experiments/flutter-pages-audit/family-inventory.json').read_text())
        self.assertEqual(manifest['caseCount'],48);self.assertEqual(len(manifest['contracts']),24)
        self.assertEqual(len({item['route'] for item in manifest['contracts']}),24)
        self.assertEqual(manifest['viewports'],['wide-1180x757','compact-390x500'])
if __name__=='__main__':unittest.main()
