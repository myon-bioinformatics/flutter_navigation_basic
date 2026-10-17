#!/usr/bin/env python3
"""Verify saved Web receipts and optional layout baselines, without browser/SDK.

This checks historical evidence, never runs the current application. Exit 0:
verified, 1: evidence/layout mismatch, 2: invalid CLI/input. Stdlib only.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import re
import sys
from urllib.parse import urlsplit


def _route(data):
    # Flutter normalizes Home from #/ to an empty fragment. Both mean '/'.
    return urlsplit(data['url']).fragment or '/'


def _number(value):
    return type(value) in (int, float) and math.isfinite(value)


def validate(data, directory, expected_sha=None):
    if not isinstance(data, dict) or data.get('schema') != 'flutter-web-observation/1':
        return ['unexpected observation schema']
    errors = []
    if data.get('status') != 'passed' or data.get('expected_status') != 'passed':
        errors.append('test did not pass normally')
    if data.get('capture_errors') != []:
        errors.append('capture incomplete')
    if not re.fullmatch(r'[0-9a-f]{40}', str(data.get('build_sha', ''))):
        errors.append('missing full build SHA')
    if expected_sha and data.get('build_sha') != expected_sha:
        errors.append('build SHA mismatch')
    if not data.get('test') or not data.get('project'):
        errors.append('missing test/project identity')
    try:
        if urlsplit(data.get('url', '')).scheme not in ('http', 'https'):
            errors.append('missing HTTP(S) source URL')
        runtime = data['runtime']
        display = runtime['display']
        if not runtime['browser'] or not runtime['browser_version']:
            errors.append('missing browser identity')
        if not all(_number(display['viewport'][key]) and display['viewport'][key] > 0 for key in ('width', 'height')):
            errors.append('invalid viewport')
        if not _number(display['device_scale_factor']) or display['device_scale_factor'] <= 0:
            errors.append('invalid device scale')
        controls = display['controls']
        if not isinstance(controls, list) or not controls:
            errors.append('no observed controls')
        else:
            for control in controls:
                if (not isinstance(control['label'], str) or not control['label']
                        or type(control['visible']) is not bool
                        or not all(_number(control['box'][key]) for key in ('x', 'y', 'width', 'height'))
                        or control['box']['width'] < 0 or control['box']['height'] < 0):
                    errors.append('invalid control geometry')
        fixture = data['fixture']
        if fixture is not None and (not fixture['file'] or not re.fullmatch(r'[0-9a-f]{64}', fixture['sha256'])):
            errors.append('missing fixture identity')
        screenshot = data['screenshot']
        name = screenshot['file']
        if not isinstance(name, str) or Path(name).name != name or name in ('.', '..'):
            errors.append('screenshot must be a sibling file')
        else:
            image = directory / name
            if image.is_symlink():
                errors.append('screenshot must not be a symlink')
            else:
                raw = image.read_bytes()
                if (not raw.startswith(b'\x89PNG\r\n\x1a\n')
                        or len(raw) != screenshot['bytes']
                        or hashlib.sha256(raw).hexdigest() != screenshot['sha256']):
                    errors.append('screenshot bytes/hash mismatch')
        # Console warnings remain diagnostic; uncaught JS errors invalidate evidence.
        if any(error['kind'] == 'pageerror' for error in data['errors']):
            errors.append('uncaught page error')
    except (KeyError, TypeError, ValueError, OSError, AttributeError):
        errors.append('incomplete/malformed observation or missing screenshot')
    return errors


def compare(baseline, observed, tolerance):
    errors = []
    for key in ('test', 'project', 'fixture'):
        if baseline[key] != observed[key]:
            errors.append(f'{key} mismatch')
    if _route(baseline) != _route(observed):
        errors.append('route mismatch')
    for key in ('browser',):
        if baseline['runtime'][key] != observed['runtime'][key]:
            errors.append(f'{key} mismatch')
    a, b = baseline['runtime']['display'], observed['runtime']['display']
    for key in ('viewport', 'device_scale_factor'):
        if a[key] != b[key]:
            errors.append(f'{key} mismatch')
    # Preserve duplicate labels rather than accidentally collapsing controls.
    left = sorted(a['controls'], key=lambda c: (c['label'], c['box']['y'], c['box']['x']))
    right = sorted(b['controls'], key=lambda c: (c['label'], c['box']['y'], c['box']['x']))
    if [c['label'] for c in left] != [c['label'] for c in right]:
        errors.append('control labels/count mismatch')
    else:
        for before, after in zip(left, right):
            if before['visible'] != after['visible']:
                errors.append(f"{before['label']}: visibility mismatch")
            if any(abs(before['box'][k] - after['box'][k]) > tolerance for k in ('x', 'y', 'width', 'height')):
                errors.append(f"{before['label']}: geometry mismatch")
    return errors


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('observation', type=Path)
    parser.add_argument('--baseline', type=Path)
    parser.add_argument('--expected-sha')
    parser.add_argument('--tolerance', type=float, default=2.0, help='CSS pixels (default: 2)')
    args = parser.parse_args(argv)
    if not math.isfinite(args.tolerance) or args.tolerance < 0:
        parser.error('--tolerance must be finite and nonnegative')
    if args.expected_sha and not re.fullmatch(r'[0-9a-f]{40}', args.expected_sha):
        parser.error('--expected-sha must be a full lowercase SHA')
    try:
        if args.observation.is_dir():
            records = sorted(args.observation.rglob('web-observation.json'))
            problems = []
            seen = set()
            captured = {}
            catalogue = None
            revisions = set()
            if args.baseline and not args.baseline.is_dir():
                parser.error('directory observations require a baseline directory')
            if not records:
                problems.append('no observation receipts found')
            for record in records:
                data = json.loads(record.read_bytes())
                issues = validate(data, record.parent, args.expected_sha)
                problems += [str(record) + ': ' + issue for issue in issues]
                if issues:
                    continue
                current = data.get('catalogue')
                if not isinstance(current, dict) or current.get('schema') != 'flutter-web-page-catalogue/1':
                    problems.append(str(record) + ': missing page catalogue')
                    continue
                if catalogue is None:
                    catalogue = current
                elif current != catalogue:
                    problems.append('mixed page catalogues')
                key = (data['project'], _route(data))
                if key in seen:
                    problems.append('duplicate page receipt: ' + str(key))
                seen.add(key)
                captured[key] = data
                revisions.add(data['build_sha'])
            if len(revisions) > 1:
                problems.append('mixed build SHAs')
            if catalogue:
                routes = catalogue.get('routes')
                if not isinstance(routes, list) or not routes or not all(isinstance(route, str) for route in routes):
                    problems.append('invalid page catalogue routes')
                else:
                    projects = catalogue.get('projects')
                    if not isinstance(projects, list) or not projects or not all(isinstance(project, str) for project in projects):
                        problems.append('missing expected browser projects')
                        projects = []
                    if set(projects) != {project for project, _ in seen}:
                        problems.append('missing/unexpected browser projects')
                    for project in sorted(projects):
                        observed = {route for owner, route in seen if owner == project}
                        if observed != set(routes):
                            problems.append(f'{project}: missing/unexpected routes: '
                                            + str(sorted(observed ^ set(routes))))
            if args.baseline:
                prior = {}
                for record in sorted(args.baseline.rglob('web-observation.json')):
                    data = json.loads(record.read_bytes())
                    issues = validate(data, record.parent)
                    problems += ['baseline: ' + issue for issue in issues]
                    if issues:
                        continue
                    key = (data['project'], _route(data))
                    if key in prior:
                        problems.append('duplicate baseline receipt: ' + str(key))
                    prior[key] = data
                if set(prior) != set(captured):
                    problems.append('baseline page/project coverage mismatch')
                if not problems:
                    for key in captured:
                        problems += [str(key) + ': ' + issue
                                     for issue in compare(prior[key], captured[key], args.tolerance)]
        else:
            data = json.loads(args.observation.read_bytes())
            problems = validate(data, args.observation.parent, args.expected_sha)
            if args.baseline:
                baseline = json.loads(args.baseline.read_bytes())
                problems += ['baseline: ' + p for p in validate(baseline, args.baseline.parent)]
                if not problems:
                    problems += compare(baseline, data, args.tolerance)
    except (OSError, ValueError) as error:
        print(f'observation: cannot read input: {error}', file=sys.stderr)
        return 2
    print(json.dumps({'scope': 'historical-web-observation', 'result': 'failed' if problems else 'passed',
                      'current_code_executed': False, 'problems': problems}, sort_keys=True))
    return 1 if problems else 0


if __name__ == '__main__':
    raise SystemExit(main())
