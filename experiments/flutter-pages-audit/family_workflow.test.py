"""Offline event/scope guard regressions; never dispatches a workflow."""
import copy
import json
from pathlib import Path
import re
import unittest
ROOT=Path(__file__).resolve().parents[2]
WORKFLOW=ROOT/'.github/workflows/flutter-audit-focused-diagnostic.yml'
OLD='Diagnostic: four bounded Door-motion observations for #223'
PREFIX='Diagnostic: 48 source-family observations for #223 @ '
BRANCH='diagnostic/flutter-223-focused-d65322c1'

def eligible(event):
    return (event.get('event')=='pull_request' and event.get('action')=='edited' and event.get('base')=='main' and
            event.get('branch')==BRANCH and event.get('old_title')==OLD and
            isinstance(event.get('head'),str) and bool(re.fullmatch('[0-9a-f]{40}',event['head'])) and
            event.get('title')==PREFIX+event['head'])

class GuardTests(unittest.TestCase):
 def test_only_exact_newhead_title_transition(self):
  good=dict(event='pull_request',action='edited',base='main',branch=BRANCH,old_title=OLD,head='a'*40,title=PREFIX+'a'*40)
  self.assertTrue(eligible(good))
  for k,v in [('event','push'),('event','workflow_dispatch'),('action','opened'),('action','synchronize'),('action','ready_for_review'),('base','other'),('branch','other'),('old_title',None),('old_title','arbitrary'),('title',PREFIX+'b'*40),('head','b'*40),('head','short'),('title','Diagnostic: 48 source-family observations for #223')]:
   d=copy.deepcopy(good);d[k]=v
   with self.subTest(k=k,v=v):self.assertFalse(eligible(d))
 def test_workflow_guard_matches_model_and_no_unbounded_lane(self):
  s=WORKFLOW.read_text()
  for fragment in ['types: [edited]','branches: [main]',"github.head_ref == '"+BRANCH+"'", "github.event.changes.title.from == '"+OLD+"'", "github.event.pull_request.title == format('"+PREFIX+"{0}', github.event.pull_request.head.sha)", 'timeout-minutes: 45','contents: read','persist-credentials: false','retention-days: 7']:
   self.assertIn(fragment,s)
  for pin in ['actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1', 'actions/upload-artifact@cf430e030ddbb5b0abf93d22962f4752f3646cd9']:
   self.assertIn(pin,s)
  self.assertIn('if: always()\n        run: python3 -B -S experiments/flutter-pages-audit/family_contract.py preflight \"$AUDIT_OUTPUT/postflight\"',s)
  self.assertLess(s.index('Discover exactly 24'),s.index('Recheck source hashes'))
  self.assertLess(s.index('Recheck source hashes'),s.index('Validate exactly 48'))
  self.assertNotIn('workflow_dispatch:',s);self.assertNotIn('pull_request_target:',s)
  self.assertFalse((ROOT/'.github/workflows/flutter-pages-audit.yml').exists())
  cfg=(ROOT/'experiments/flutter-pages-audit/playwright.config.cjs').read_text()
  for fragment in ['workers: 2','retries: 0','timeout: 90_000','family.contracts.map'] :self.assertIn(fragment,cfg)
 def test_manifest_exact24unique_routes_two_viewports(self):
  d=json.loads((ROOT/'experiments/flutter-pages-audit/family-inventory.json').read_text())
  self.assertEqual(d['caseCount'],48);self.assertEqual(len(d['contracts']),24);self.assertEqual(len({c['route']for c in d['contracts']}),24)
  self.assertEqual(d['viewports'],['wide-1180x757','compact-390x500'])
if __name__=='__main__':unittest.main()
