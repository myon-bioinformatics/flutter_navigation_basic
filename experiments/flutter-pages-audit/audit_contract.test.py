"""Synthetic saved-evidence unit tests, not browser or Flutter execution proof."""
from __future__ import annotations

from contextlib import contextmanager
import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess
import sys
import tempfile
import unittest
import zlib

SPEC = importlib.util.spec_from_file_location('audit_contract', Path(__file__).with_name('audit_contract.py'))
audit = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(audit)
CANDIDATE = 'a' * 40


def png(width, height):
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
    return (b'\x89PNG\r\n\x1a\n'
            + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress((b'\0' + b'\xff\xff\xff' * width) * height))
            + chunk(b'IEND', b''))


class AuditContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix='flutter-audit-contract-')
        cls.root = Path(cls.temp.name)
        cls.manifest = audit.make_catalogue()
        cls.paths = []
        images = {v['id']: png(v['width'], v['height']) for v in audit.VIEWPORTS}
        for index, entry in enumerate(cls.manifest['routes']):
            for viewport in audit.VIEWPORTS:
                directory = cls.root / f'{index:03d}-{viewport["id"]}'
                directory.mkdir()
                image = images[viewport['id']]
                (directory / 'initial.png').write_bytes(image)
                data = {
                    'schema': audit.RECEIPT_SCHEMA, 'route': entry['route'],
                    'canonical': entry['canonical'], 'viewport': viewport,
                    'referenceSha': audit.REFERENCE_SHA,
                    'servedShaBefore': audit.REFERENCE_SHA, 'servedShaAfter': audit.REFERENCE_SHA,
                    'candidateSha': CANDIDATE,
                    'checks': {name: {'status': 'passed'} for name in audit.REQUIRED_CHECKS},
                    'errors': [], 'captures': [{'file': 'initial.png', 'bytes': len(image),
                                              'sha256': hashlib.sha256(image).hexdigest()}],
                }
                data['checks'].update({name: {'status': 'unverified', 'reason': 'No generic behavior proof claimed.'}
                                       for name in audit.OPTIONAL_CHECKS})
                file = directory / audit.RECEIPT_NAME
                file.write_text(json.dumps(data), encoding='utf-8')
                cls.paths.append(file)

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    @contextmanager
    def changed(self, mutate):
        file = self.paths[0]
        original = file.read_bytes()
        data = json.loads(original)
        mutate(data)
        file.write_text(json.dumps(data), encoding='utf-8')
        try:
            yield data
        finally:
            file.write_bytes(original)

    def result(self):
        return audit.aggregate(self.root, candidate_sha=CANDIDATE)

    def test_catalogue_reuses_real_215_routes_210_identities_and_five_aliases(self):
        self.assertEqual(self.manifest['counts'], {'urls': 215, 'canonicalDestinations': 210, 'aliases': 5, 'routeViewportPairs': 430})
        entries = {item['route']: item for item in self.manifest['routes']}
        self.assertTrue(all(f'/screen{i}' in entries for i in range(1, 199)))
        self.assertEqual(entries['/examples/mock-api']['canonical'], '/tools/http/request-draft')
        self.assertEqual(entries['/examples/composition-generator/seed']['canonical'], '/examples/composition-generator')
        self.assertTrue(all(item['emoji'] for item in entries.values()))
        self.assertFalse(any('/data-processing-interactions/' in route for route in entries))
        self.assertTrue(all(len(value) == 64 for value in self.manifest['sourceHashes'].values()))

    def test_complete_required_evidence_passes_without_claiming_optional_verification(self):
        result = self.result()
        self.assertEqual(result['result'], 'passed')
        self.assertTrue(result['coverage']['completeExactlyOnce'])
        self.assertEqual(result['coverage']['validEvidencePairs'], 430)
        self.assertEqual(result['coverage']['observedCanonicalDestinationPairs'], 420)
        self.assertEqual(result['coverage']['observedAliasPairs'], 10)
        self.assertEqual(result['perCheck']['favorite_keyboard']['passed'], 430)
        self.assertEqual(result['perCheck']['page_action']['unverified'], 430)
        self.assertEqual(result['perCheck']['page_action']['passed'], 0)
        self.assertEqual(result['optionalUnverified'], 860)
        self.assertFalse(result['currentCodeExecuted'])

    def test_missing_receipt_is_hard_failure(self):
        file = self.paths[0]
        moved = file.with_suffix('.held')
        file.rename(moved)
        try:
            result = self.result()
            self.assertEqual(result['result'], 'failed')
            self.assertEqual(len(result['missing']), 1)
            self.assertFalse(result['coverage']['completeExactlyOnce'])
        finally:
            moved.rename(file)

    def test_duplicate_receipt_is_not_extra_coverage(self):
        duplicate = self.root / 'duplicate'
        shutil.copytree(self.paths[0].parent, duplicate)
        try:
            result = self.result()
            self.assertEqual(result['result'], 'failed')
            self.assertEqual(len(result['duplicates']), 1)
            self.assertEqual(result['coverage']['uniqueUrlViewportPairs'], 430)
            self.assertEqual(result['perCheck']['navigation']['passed'], 430)
        finally:
            shutil.rmtree(duplicate)

    def test_each_missing_or_wrong_sha_fails(self):
        for key in ('referenceSha', 'servedShaBefore', 'servedShaAfter', 'candidateSha'):
            with self.subTest(key=key), self.changed(lambda data: data.__setitem__(key, 'b' * 40)):
                self.assertEqual(self.result()['result'], 'failed')
        with self.changed(lambda data: data.pop('candidateSha')):
            self.assertEqual(self.result()['result'], 'failed')

    def test_required_unverified_is_partial_and_not_passed(self):
        with self.changed(lambda data: data['checks'].__setitem__('scroll', {'status': 'unverified', 'reason': 'No unambiguous scroll witness.'})):
            result = self.result()
            self.assertEqual(result['result'], 'partial')
            self.assertTrue(result['coverage']['completeExactlyOnce'])
            self.assertEqual(result['requiredUnverified'], 1)
            self.assertEqual(result['perCheck']['scroll']['passed'], 429)

    def test_required_failure_and_missing_contract_fail(self):
        with self.changed(lambda data: data['checks'].__setitem__('favorite_pointer', {'status': 'failed', 'reason': 'No state change observed.'})):
            self.assertEqual(self.result()['requiredFailed'], 1)
            self.assertEqual(self.result()['result'], 'failed')
        with self.changed(lambda data: data['checks'].pop('favorite_reset')):
            result = self.result()
            self.assertEqual(result['result'], 'failed')
            self.assertEqual(result['perCheck']['favorite_reset']['missing'], 1)

    def test_only_positive_fitting_scroll_can_be_not_applicable(self):
        region = {'id': 'measured-body', 'box': {'x': 0, 'y': 104, 'width': 390, 'height': 162},
                  'clip': {'x': 0, 'y': 104, 'width': 390, 'height': 162},
                  'scrollHeight': 162, 'clientHeight': 162,
                  'descendantBounds': [{'x': 24, 'y': 128, 'width': 300, 'height': 30}]}
        fit = {'status': 'not_applicable', 'reason': 'Measured content fits its viewport.',
               'evidence': {'fits': True, 'overflow': False, 'regions': [region]}}
        with self.changed(lambda data: data['checks'].__setitem__('scroll', fit)):
            result = self.result()
            self.assertEqual(result['result'], 'passed')
            self.assertEqual(result['perCheck']['scroll']['not_applicable'], 1)
            self.assertEqual(result['perCheck']['scroll']['passed'], 429)
        for name in ('favorite_pointer', 'favorite_keyboard', 'favorite_reset', 'header_geometry'):
            with self.subTest(name=name), self.changed(lambda data: data['checks'].__setitem__(name, fit)):
                self.assertEqual(self.result()['result'], 'failed')
        for invalid in ({'status': 'not_applicable', 'reason': 'Unknown'},
                        {'status': 'not_applicable', 'reason': 'Booleans only',
                         'evidence': {'fits': True, 'overflow': False}},
                        {'status': 'not_applicable', 'evidence': fit['evidence']}):
            with self.changed(lambda data: data['checks'].__setitem__('scroll', invalid)):
                self.assertEqual(self.result()['result'], 'failed')
        mutations = [lambda e: e.__setitem__('regions', []),
                     lambda e: e['regions'][0].__setitem__('id', ''),
                     lambda e: e['regions'][0].__setitem__('scrollHeight', 300),
                     lambda e: e['regions'][0].__setitem__('clientHeight', 0),
                     lambda e: e['regions'][0]['box'].__setitem__('width', 0),
                     lambda e: e['regions'][0]['clip'].__setitem__('height', 150),
                     lambda e: e['regions'][0]['clip'].__setitem__('x', 1000),
                     lambda e: e['regions'][0].__setitem__('descendantBounds', []),
                     lambda e: e['regions'][0]['descendantBounds'][0].__setitem__('y', 500),
                     lambda e: e['regions'][0]['descendantBounds'][0].__setitem__('width', float('nan'))]
        for mutate in mutations:
            invalid = copy.deepcopy(fit)
            mutate(invalid['evidence'])
            with self.subTest(mutate=mutate), self.changed(lambda data: data['checks'].__setitem__('scroll', invalid)):
                self.assertEqual(self.result()['result'], 'failed')

    def test_bad_viewport_route_canonical_and_status_fail(self):
        mutations = [lambda d: d['viewport'].__setitem__('deviceScaleFactor', 2),
                     lambda d: d['viewport'].__setitem__('deviceScaleFactor', True),
                     lambda d: d.__setitem__('route', '/not-registered'),
                     lambda d: d.__setitem__('canonical', '/hub'),
                     lambda d: d['checks']['navigation'].__setitem__('status', 'skipped')]
        for mutate in mutations:
            with self.subTest(mutate=mutate), self.changed(mutate):
                self.assertEqual(self.result()['result'], 'failed')

    def test_additional_failed_observation_is_not_a_green_result(self):
        with self.changed(lambda data: data['checks'].__setitem__('local_action', {'status': 'failed', 'reason': 'Local postcondition did not change.'})):
            result = self.result()
            self.assertEqual(result['result'], 'failed')
            self.assertEqual(result['perCheck']['local_action']['failed'], 1)
            self.assertEqual(result['observedFailed'], 1)

    def test_missing_tampered_traversing_or_wrong_size_screenshot_fails(self):
        mutations = [lambda d: d.__setitem__('captures', []),
                     lambda d: d['captures'][0].__setitem__('sha256', '0' * 64),
                     lambda d: d['captures'][0].__setitem__('file', '../initial.png'),
                     lambda d: d['captures'][0].__setitem__('file', 'missing.png')]
        for mutate in mutations:
            with self.subTest(mutate=mutate), self.changed(mutate):
                self.assertEqual(self.result()['result'], 'failed')
        file = self.paths[0].parent / 'initial.png'
        original = file.read_bytes()
        wrong = png(1, 1)
        file.write_bytes(wrong)
        try:
            def replace(data):
                data['captures'][0].update(bytes=len(wrong), sha256=hashlib.sha256(wrong).hexdigest())
            with self.changed(replace):
                self.assertEqual(self.result()['result'], 'failed')
        finally:
            file.write_bytes(original)

    def test_malformed_json_and_reported_errors_fail(self):
        file = self.paths[0]
        original = file.read_bytes()
        file.write_text('{incomplete')
        try:
            self.assertEqual(self.result()['result'], 'failed')
        finally:
            file.write_bytes(original)
        with self.changed(lambda data: data.__setitem__('errors', ['uncaught application error'])):
            self.assertEqual(self.result()['result'], 'failed')

    def test_cli_is_stdlib_only_and_writes_explicit_outputs(self):
        env = {key: value for key, value in os.environ.items() if key != 'CANDIDATE_SHA'}
        with tempfile.TemporaryDirectory(prefix='audit-cli-') as directory:
            for command in (['catalogue'], ['aggregate', str(self.root), '--candidate-sha', CANDIDATE]):
                output = Path(directory) / (command[0] + '.json')
                run = subprocess.run([sys.executable, '-B', '-S', str(audit.__file__), *command, '--output', str(output)],
                                     capture_output=True, text=True, env=env)
                self.assertEqual(run.returncode, 0, run.stderr)
                self.assertTrue(output.is_file())
                self.assertEqual(json.loads(run.stdout)['output'], str(output))
            with self.changed(lambda data: data['checks'].__setitem__('scroll', {'status': 'unverified', 'reason': 'Unknown'})):
                run = subprocess.run([sys.executable, '-B', '-S', str(audit.__file__), 'aggregate', str(self.root)],
                                     capture_output=True, text=True, env=env)
                self.assertEqual(run.returncode, 1)
                self.assertEqual(json.loads(run.stdout)['result'], 'partial')


if __name__ == '__main__':
    unittest.main(verbosity=2)
