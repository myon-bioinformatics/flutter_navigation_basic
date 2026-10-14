import copy
import xml.etree.ElementTree as ET
import pytest
from pattern_contracts import EXPECTED_IDS, validate, write_junit
from generate_pattern_contracts import TARGET, generate


def valid_document():
    cases = {identity: {'encoded': {'message': 'test'}, 'restored': {'message': 'test'}, 'service': {'message': 'stub'}} for identity in EXPECTED_IDS}
    for identity, verb, field, payload in [('api/001', 'GET', 'body', {'url': 'https://example.com'}), ('api/002', 'POST', 'echo', {'title': 'foo'})]:
        expected = {'message': verb + ' https://example.com → 200', 'statusCode': 200, field: payload}
        cases[identity] = {'encoded': expected, 'restored': copy.deepcopy(expected), 'defaults': {'message': 'test', 'statusCode': 200, field: {}}, 'missingOptional': {'message': 'hello', 'statusCode': 200, field: {}}}
    return {'schemaVersion': 1, 'producer': 'dart-production-patterns', 'cases': cases}


def test_producer_registry_matches_all_production_models():
    assert TARGET.read_text() == generate()


def test_independent_oracle_accepts_valid_contract():
    assert validate(valid_document()) == {}


@pytest.mark.parametrize('change', ['missing', 'extra', 'encode', 'roundtrip', 'defaults', 'missingOptional', 'stub', 'exception'])
def test_oracle_rejects_runtime_regressions(change):
    document = valid_document()
    cases = document['cases']
    if change == 'missing': cases.pop('navigation/198')
    elif change == 'extra': cases['unexpected/199'] = {}
    elif change == 'encode': cases['navigation/001']['encoded']['message'] = 'broken'
    elif change == 'roundtrip': cases['api/002']['restored']['echo'] = {}
    elif change == 'defaults': cases['api/001']['defaults']['statusCode'] = 500
    elif change == 'missingOptional': cases['api/001']['missingOptional']['body'] = {'unexpected': True}
    elif change == 'stub': cases['ui_theme/001']['service']['message'] = ''
    else: cases['navigation/001'] = {'error': 'runtime exception'}
    assert validate(document)


def test_junit_contains_real_failures(tmp_path):
    output = tmp_path/'result.xml'
    write_junit(output, {'api/001': 'sentinel failure'})
    root = ET.parse(output).getroot()
    assert root.get('tests') == '595'
    assert root.get('failures') == '1'
    assert len(root.findall('testcase/failure')) == 1
