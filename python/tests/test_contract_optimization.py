"""Public contract validation and JUnit reporting must survive python -O."""
import json, subprocess, sys, tempfile, unittest, xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class OptimizedContractTests(unittest.TestCase):
    def run_code(self, code, optimized):
        return subprocess.run(
            [sys.executable, '-S', *(['-O'] if optimized else []), '-c', code],
            cwd=ROOT / 'python', text=True, capture_output=True, timeout=30,
        )

    def test_metadata_acceptance_and_rejection(self):
        for optimized in (False, True):
            for change in ('none', 'duplicate', 'domain', 'translation'):
                with self.subTest(optimized=optimized, change=change):
                    result = self.run_code("""
import json
from metadata_contracts import ROOT, validate_screens, validate_locales
screens = json.loads((ROOT / 'assets/screens.json').read_text())['screens']
locales = json.loads((ROOT / 'assets/display/app_text.json').read_text())['locales']
change = %r
if change == 'duplicate': screens[0]['emoji'] = screens[1]['emoji']
if change == 'domain': screens[0]['domainKey'] = 'wrong'
if change == 'translation': locales['jpn'].pop('urlParameters.case')
validate_screens(screens)
validate_locales(locales)
print('accepted')
""" % change, optimized)
                    self.assertEqual(result.returncode, 0 if change == 'none' else 1, result.stderr)
                    self.assertEqual(result.stdout, 'accepted\n' if change == 'none' else '')
                    if change != 'none':
                        self.assertIn('AssertionError', result.stderr)

    def test_header_acceptance_and_rejection(self):
        for optimized in (False, True):
            for change in ('none', 'overflow', 'schema', 'overlap'):
                with self.subTest(optimized=optimized, change=change):
                    result = self.run_code("""
from header_contracts import validate
from generate_page_identities import identities
names = ('shared-header-title', 'shared-header-home', 'shared-header-favorite', 'shared-header-menu')
data = {'schemaVersion': 1, 'route': '/hub', 'title': 'Hub ' + identities()['/hub'],
        'viewport': {'width': 390}, 'requiresSecondary': True,
        'boxes': {name: {'x': i * 80, 'y': 0, 'width': 48, 'height': 48} for i, name in enumerate(names)}}
data['boxes']['shared-header-secondary'] = {'x': 0, 'y': 50, 'width': 390, 'height': 48}
change = %r
if change == 'overflow': data['boxes']['shared-header-title']['width'] = 1000
if change == 'schema': data['schemaVersion'] = 2
if change == 'overlap': data['boxes']['shared-header-secondary']['y'] = 0
validate(data)
print('accepted')
""" % change, optimized)
                    self.assertEqual(result.returncode, 0 if change == 'none' else 1, result.stderr)
                    self.assertEqual(result.stdout, 'accepted\n' if change == 'none' else '')
                    if change != 'none':
                        self.assertIn('AssertionError', result.stderr)

    def test_pattern_cli_and_junit(self):
        cases = {f'{family}/{i:03}': {'encoded': {'message': 'test'}, 'restored': {'message': 'test'}, 'service': {'message': 'stub'}}
                 for family in ('api', 'navigation', 'ui_theme') for i in range(1, 199)}
        for identity, verb, field, payload in [('api/001', 'GET', 'body', {'url': 'https://example.com'}), ('api/002', 'POST', 'echo', {'title': 'foo'})]:
            expected = {'message': verb + ' https://example.com → 200', 'statusCode': 200, field: payload}
            cases[identity] = {'encoded': expected, 'restored': expected,
                               'defaults': {'message': 'test', 'statusCode': 200, field: {}},
                               'missingOptional': {'message': 'hello', 'statusCode': 200, field: {}}}
        for optimized in (False, True):
            for change in ('none', 'schema', 'encoded'):
                with self.subTest(optimized=optimized, change=change), tempfile.TemporaryDirectory() as tmp:
                    document = json.loads(json.dumps({'schemaVersion': 1, 'producer': 'dart-production-patterns', 'cases': cases}))
                    if change == 'schema': document['schemaVersion'] = 2
                    if change == 'encoded': document['cases']['navigation/001']['encoded'] = {'message': 'wrong'}
                    source, receipt = Path(tmp) / 'input.json', Path(tmp) / 'junit.xml'
                    source.write_text(json.dumps(document))
                    result = subprocess.run([sys.executable, '-S', *(['-O'] if optimized else []),
                                             str(ROOT / 'python/pattern_contracts.py'), str(source), '--junit', str(receipt)],
                                            text=True, capture_output=True, timeout=30)
                    self.assertEqual(result.returncode, 0 if change == 'none' else 1, result.stderr)
                    suite = ET.parse(receipt).getroot()
                    self.assertEqual(suite.get('tests'), '595')
                    self.assertEqual(suite.get('failures'), '0' if change == 'none' else '1')
                    self.assertEqual(len(suite.findall('testcase/failure')), 0 if change == 'none' else 1)


if __name__ == '__main__':
    unittest.main()
