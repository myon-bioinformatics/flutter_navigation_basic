"""Validate real Dart output. Stdlib only; nonzero exit + per-case JUnit failures.

Usage: python python/pattern_contracts.py output.json --junit output.xml
"""
import argparse
import json
from pathlib import Path
import xml.etree.ElementTree as ET

FAMILIES = ('api', 'navigation', 'ui_theme')
EXPECTED_IDS = {f'{family}/{i:03}' for family in FAMILIES for i in range(1, 199)}


def validate_case(identity, value):
    if not (isinstance(value, dict) and 'error' not in value):
        raise AssertionError(f'producer error: {value}')
    special = identity in ('api/001', 'api/002')
    expected = {'message': 'test'}
    if special:
        field = 'body' if identity == 'api/001' else 'echo'
        expected = {
            'message': ('GET' if field == 'body' else 'POST') + ' https://example.com → 200',
            'statusCode': 200,
            field: {'url': 'https://example.com'} if field == 'body' else {'title': 'foo'},
        }
        if not (value['defaults'] == {'message': 'test', 'statusCode': 200, field: {}}):
            raise AssertionError('constructor defaults')
        if not (value['missingOptional'] == {'message': 'hello', 'statusCode': 200, field: {}}):
            raise AssertionError('missing optional defaults')
    if not (value['encoded'] == expected):
        raise AssertionError('toJson differs from independent expected values')
    if not (value['restored'] == expected):
        raise AssertionError('fromJson round trip differs from expected values')
    if not special:
        message = value['service']['message']
        if not (isinstance(message, str) and message):
            raise AssertionError('stub service result must contain a nonempty message')


def validate(document):
    failures = {}
    if not isinstance(document, dict):
        document = {}
    try:
        if not (document['schemaVersion'] == 1):
            raise AssertionError('pattern_contracts:39: validation failed')
        if not (document['producer'] == 'dart-production-patterns'):
            raise AssertionError('pattern_contracts:40: validation failed')
        if not (isinstance(document['cases'], dict)):
            raise AssertionError('pattern_contracts:41: validation failed')
        actual = set(document['cases'])
        if not (actual == EXPECTED_IDS):
            raise AssertionError(f'missing={sorted(EXPECTED_IDS-actual)}, extra={sorted(actual-EXPECTED_IDS)}')
    except (AssertionError, KeyError, TypeError) as error:
        failures['inventory'] = str(error) or 'invalid contract envelope'
    cases = document.get('cases', {}) if isinstance(document, dict) else {}
    for identity in sorted(EXPECTED_IDS):
        try:
            validate_case(identity, cases[identity])
        except (AssertionError, KeyError, TypeError) as error:
            failures[identity] = str(error)
    return failures


def write_junit(path, failures):
    names = ['inventory', *sorted(EXPECTED_IDS)]
    suite = ET.Element('testsuite', name='dart-pattern-contracts', tests=str(len(names)), failures=str(len(failures)), errors='0', skipped='0')
    for name in names:
        case = ET.SubElement(suite, 'testcase', classname='dart.patterns', name=name, time='0')
        if name in failures:
            ET.SubElement(case, 'failure', message=failures[name]).text = failures[name]
    path.parent.mkdir(parents=True, exist_ok=True)
    ET.ElementTree(suite).write(path, encoding='utf-8', xml_declaration=True)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input', type=Path)
    parser.add_argument('--junit', type=Path)
    args = parser.parse_args(argv)
    try:
        document = json.loads(args.input.read_text())
    except (OSError, ValueError) as error:
        document = {}
        print(f'Cannot load producer output: {error}')
    failures = validate(document)
    if args.junit:
        write_junit(args.junit, failures)
    for identity, message in failures.items():
        print(f'FAIL {identity}: {message}')
    print(f'{595-len(failures)} passed, {len(failures)} failed')
    raise SystemExit(bool(failures))


if __name__ == '__main__':
    main()
