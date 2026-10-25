#!/usr/bin/env python3
"""Stdlib-only route inventory and fail-closed aggregation of browser evidence.

This reads saved observations; it never launches a browser or executes Flutter.
Only UI Showcase has a native HTML counterpart. This is a Flutter-only audit.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'python'))
from generate_page_identities import ALIASES, identities  # noqa: E402
from web_page_catalogue import catalogue as public_catalogue  # noqa: E402
from vendor.check_png import dimensions as png_dimensions  # noqa: E402

REFERENCE_SHA = '9b38f3e935e9e171cbacc3af63f539ddce9db86b'
CATALOGUE_SCHEMA = 'flutter-pages-audit-catalogue/1'
RECEIPT_SCHEMA = 'flutter-pages-audit/1'
RECEIPT_NAME = 'audit-receipt.json'
VIEWPORTS = (
    {'id': 'wide-1180x757', 'width': 1180, 'height': 757, 'deviceScaleFactor': 1},
    {'id': 'compact-390x500', 'width': 390, 'height': 500, 'deviceScaleFactor': 1},
)
REQUIRED_CHECKS = (
    'navigation', 'build_identity', 'viewport', 'header_geometry', 'body_geometry',
    'favorite_pointer', 'favorite_keyboard', 'favorite_reset', 'scroll', 'runtime_errors',
)
OPTIONAL_CHECKS = ('page_action', 'painted_text_overflow')
STATUSES = ('passed', 'failed', 'unverified', 'not_applicable')
SHA40 = re.compile(r'[0-9a-f]{40}\Z')
SHA256 = re.compile(r'[0-9a-f]{64}\Z')


def make_catalogue():
    """Reuse the existing declarations, aliases and emoji source, not a route list."""
    raw = public_catalogue()
    emoji = identities()
    routes = []
    for route in raw['routes']:
        canonical = ALIASES.get(route, route)
        if canonical not in emoji:
            raise ValueError(f'missing canonical page identity: {route} -> {canonical}')
        routes.append({'route': route, 'canonical': canonical,
                       'alias': canonical != route, 'emoji': emoji[canonical]})
    canonical_count = len({entry['canonical'] for entry in routes})
    # A source inventory change requires explicit review of this pinned audit.
    # These are coverage counts, not a second list of route declarations.
    if len(routes) != 215 or canonical_count != 210:
        raise ValueError('pinned route inventory changed; review the reference before updating coverage')
    source_hashes = dict(raw['sources'])
    for name in ('python/generate_page_identities.py', 'assets/screens.json',
                 'lib/shared/navigation/page_identities.g.dart'):
        source_hashes[name] = hashlib.sha256((ROOT / name).read_bytes()).hexdigest()
    return {
        'schema': CATALOGUE_SCHEMA, 'referenceSha': REFERENCE_SHA,
        'routes': routes, 'viewports': [dict(viewport) for viewport in VIEWPORTS], 'sourceHashes': source_hashes,
        'requiredChecks': list(REQUIRED_CHECKS), 'optionalChecks': list(OPTIONAL_CHECKS),
        'counts': {'urls': len(routes), 'canonicalDestinations': canonical_count,
                   'aliases': sum(entry['alias'] for entry in routes),
                   'routeViewportPairs': len(routes) * len(VIEWPORTS)},
    }


def _reason(check):
    return isinstance(check.get('reason'), str) and bool(check['reason'].strip())


def _number(value):
    return type(value) in (int, float) and math.isfinite(value)


def _box(value):
    return (isinstance(value, dict)
            and all(_number(value.get(key)) for key in ('x', 'y', 'width', 'height'))
            and value['width'] > 0 and value['height'] > 0)


def _contains(outer, inner, tolerance=1):
    return (inner['x'] >= outer['x'] - tolerance and inner['y'] >= outer['y'] - tolerance
            and inner['x'] + inner['width'] <= outer['x'] + outer['width'] + tolerance
            and inner['y'] + inner['height'] <= outer['y'] + outer['height'] + tolerance)


def validate_fitting_regions(evidence):
    """Require measured containment, not a positive flag or an empty every()."""
    if not isinstance(evidence, dict):
        return ['scroll: not_applicable requires measured fitting regions']
    regions = evidence.get('regions')
    if not isinstance(regions, list) or not regions:
        return ['scroll: not_applicable requires nonempty measured regions']
    problems = []
    ids = set()
    for index, region in enumerate(regions):
        prefix = f'scroll: fitting region {index}'
        if not isinstance(region, dict):
            problems.append(f'{prefix} must be an object')
            continue
        identity = region.get('id')
        if not isinstance(identity, str) or not identity.strip() or identity in ids:
            problems.append(f'{prefix} needs a unique nonempty id')
        else:
            ids.add(identity)
        box, clip = region.get('box'), region.get('clip')
        if not _box(box) or not _box(clip):
            problems.append(f'{prefix} needs finite positive box and clip geometry')
        elif (clip['width'] < box['width'] - 1 or clip['height'] < box['height'] - 1
              or not _contains(clip, box) or not _contains(box, clip)):
            problems.append(f'{prefix} is clipped, not fully contained in its visible region')
        height, client = region.get('scrollHeight'), region.get('clientHeight')
        if (not _number(height) or not _number(client) or height < 0 or client <= 0
                or height > client + 2):
            problems.append(f'{prefix} lacks a finite non-overflowing scroll measurement')
        descendants = region.get('descendantBounds')
        if not isinstance(descendants, list) or not descendants:
            problems.append(f'{prefix} needs nonempty complete descendant bounds')
        else:
            for child in descendants:
                if not _box(child) or (_box(box) and not _contains(box, child)):
                    problems.append(f'{prefix} has an invalid or out-of-bounds descendant')
    return problems


def validate_checks(checks):
    problems = []
    if not isinstance(checks, dict) or not checks:
        return ['checks must be a nonempty mapping']
    for name in REQUIRED_CHECKS:
        if name not in checks:
            problems.append(f'missing required check: {name}')
    for name, check in checks.items():
        if not isinstance(name, str) or not name or not isinstance(check, dict):
            problems.append('invalid check name or result object')
            continue
        status = check.get('status')
        if status not in STATUSES:
            problems.append(f'{name}: invalid check status')
            continue
        if status != 'passed' and not _reason(check):
            problems.append(f'{name}: {status} requires a nonempty reason')
        if name in REQUIRED_CHECKS and status == 'not_applicable':
            if name != 'scroll':
                problems.append(f'{name}: required shared contract cannot be not_applicable')
            else:
                evidence = check.get('evidence')
                if (not isinstance(evidence, dict) or evidence.get('fits') is not True
                        or evidence.get('overflow') is not False):
                    problems.append('scroll: not_applicable requires positive fits=true, overflow=false evidence')
                problems.extend(validate_fitting_regions(evidence))
    return problems


def validate_captures(captures, directory, viewport):
    problems = []
    if not isinstance(captures, list) or not captures:
        return ['missing screenshot captures']
    names = set()
    for capture in captures:
        if not isinstance(capture, dict):
            problems.append('capture must be an object')
            continue
        name = capture.get('file')
        if (not isinstance(name, str) or not name or Path(name).name != name
                or '/' in name or '\\' in name or not name.lower().endswith('.png')):
            problems.append('capture must name a sibling PNG file')
            continue
        if name in names:
            problems.append(f'duplicate capture file: {name}')
        names.add(name)
        if type(capture.get('bytes')) is not int or capture['bytes'] <= 0:
            problems.append(f'{name}: invalid byte count')
        if not isinstance(capture.get('sha256'), str) or not SHA256.fullmatch(capture['sha256']):
            problems.append(f'{name}: invalid SHA256')
        image = directory / name
        try:
            if image.is_symlink():
                raise ValueError('screenshot must not be a symlink')
            raw = image.read_bytes()
            width, height = png_dimensions(raw)
            if (len(raw) != capture.get('bytes')
                    or hashlib.sha256(raw).hexdigest() != capture.get('sha256')):
                problems.append(f'{name}: screenshot bytes/hash mismatch')
            if viewport is not None:
                expected = (viewport['width'] * viewport['deviceScaleFactor'],
                            viewport['height'] * viewport['deviceScaleFactor'])
                if (width, height) != expected:
                    problems.append(f'{name}: PNG dimensions {(width, height)} do not match viewport {expected}')
        except (OSError, ValueError) as error:
            problems.append(f'{name}: {error}')
    return problems


def _counter():
    return {status: 0 for status in (*STATUSES, 'missing', 'invalid')}


def aggregate(directory, *, candidate_sha=None):
    """Validate the complete 215 URL x 2 viewport set, preserving partial results."""
    directory = Path(directory)
    manifest = make_catalogue()
    routes = {entry['route']: entry for entry in manifest['routes']}
    viewports = {entry['id']: entry for entry in manifest['viewports']}
    expected = {(route, viewport) for route in routes for viewport in viewports}
    seen = {}
    duplicates = []
    problems = []
    records = sorted(directory.rglob(RECEIPT_NAME)) if directory.is_dir() else []
    candidate_shas = set()
    valid_evidence = set()
    counts = {name: _counter() for name in (*REQUIRED_CHECKS, *OPTIONAL_CHECKS)}
    if candidate_sha is not None and (not isinstance(candidate_sha, str) or not SHA40.fullmatch(candidate_sha)):
        raise ValueError('expected candidate SHA must be a full lowercase commit SHA')
    if not directory.is_dir():
        problems.append({'receipt': str(directory), 'problems': ['receipt directory does not exist']})
    for file in records:
        label = str(file.relative_to(directory))
        issues = []
        try:
            if file.is_symlink():
                raise ValueError('receipt must not be a symlink')
            data = json.loads(file.read_text(encoding='utf-8'),
                              parse_constant=lambda value: (_ for _ in ()).throw(ValueError(f'non-finite JSON value: {value}')))
            if not isinstance(data, dict) or not data:
                raise ValueError('receipt must be a nonempty JSON object')
        except (OSError, ValueError) as error:
            problems.append({'receipt': label, 'problems': [str(error)]})
            continue
        if data.get('schema') != RECEIPT_SCHEMA:
            issues.append('unexpected receipt schema')
        route = data.get('route')
        entry = routes.get(route) if isinstance(route, str) else None
        if entry is None:
            issues.append('unknown or missing public route')
        elif data.get('canonical') != entry['canonical']:
            issues.append('canonical route mismatch')
        observed_viewport = data.get('viewport')
        viewport_id = observed_viewport.get('id') if isinstance(observed_viewport, dict) else None
        viewport = viewports.get(viewport_id) if isinstance(viewport_id, str) else None
        if (viewport is None or observed_viewport != viewport
                or type(observed_viewport.get('width')) is not int
                or type(observed_viewport.get('height')) is not int
                or type(observed_viewport.get('deviceScaleFactor')) not in (int, float)):
            issues.append('viewport must exactly match an expected width, height and DPR')
        for name in ('referenceSha', 'servedShaBefore', 'servedShaAfter'):
            if data.get(name) != REFERENCE_SHA:
                issues.append(f'{name}: stale/missing baseline SHA')
        candidate = data.get('candidateSha')
        if not isinstance(candidate, str) or not SHA40.fullmatch(candidate):
            issues.append('missing full candidate SHA')
        else:
            candidate_shas.add(candidate)
            if candidate_sha is not None and candidate != candidate_sha:
                issues.append('candidate SHA does not match the expected audited commit')
        errors = data.get('errors')
        if not isinstance(errors, list):
            issues.append('errors must be an array')
        elif errors:
            issues.append('receipt reports errors; do not treat it as successful evidence')
        checks = data.get('checks')
        issues.extend(validate_checks(checks))
        issues.extend(validate_captures(data.get('captures'), file.parent, viewport))
        if entry is not None and viewport is not None:
            key = (route, viewport_id)
            if key in seen:
                duplicates.append({'route': route, 'viewport': viewport_id, 'first': seen[key], 'duplicate': label})
                issues.append('duplicate route/viewport receipt')
            else:
                seen[key] = label
                for name in (*REQUIRED_CHECKS, *OPTIONAL_CHECKS):
                    check = checks.get(name) if isinstance(checks, dict) else None
                    status = check.get('status') if isinstance(check, dict) else None
                    if check is None:
                        status = 'missing' if name in REQUIRED_CHECKS else 'unverified'
                    elif status not in STATUSES:
                        status = 'invalid'
                    counts[name][status] += 1
                # Additional measurements are retained separately, never used
                # to substitute for a missing required contract.
                if isinstance(checks, dict):
                    for name, check in checks.items():
                        if name in REQUIRED_CHECKS or name in OPTIONAL_CHECKS:
                            continue
                        counts.setdefault(name, _counter())
                        status = check.get('status') if isinstance(check, dict) else None
                        counts[name][status if status in STATUSES else 'invalid'] += 1
                if not issues:
                    valid_evidence.add(key)
        if issues:
            problems.append({'receipt': label, 'problems': issues})
    missing = sorted(expected - seen.keys())
    for name in (*REQUIRED_CHECKS, *OPTIONAL_CHECKS):
        counts[name]['missing'] += len(missing)
    if len(candidate_shas) > 1:
        problems.append({'receipt': None, 'problems': ['mixed candidate SHAs across receipts']})
    required_failed = sum(counts[name]['failed'] for name in REQUIRED_CHECKS)
    required_unverified = sum(counts[name]['unverified'] for name in REQUIRED_CHECKS)
    optional_failed = sum(counts[name]['failed'] for name in OPTIONAL_CHECKS)
    optional_unverified = sum(counts[name]['unverified'] for name in OPTIONAL_CHECKS)
    observed_failed = sum(counter['failed'] for counter in counts.values())
    if problems or missing or duplicates or observed_failed:
        result = 'failed'
    elif required_unverified:
        result = 'partial'
    else:
        result = 'passed'
    observed_canonical = {(routes[route]['canonical'], viewport) for route, viewport in seen}
    alias_pairs = sum(routes[route]['alias'] for route, _ in seen)
    complete = not missing and not duplicates and len(seen) == len(expected) and len(records) == len(expected)
    return {
        'schema': 'flutter-pages-audit-summary/1', 'result': result,
        'scope': 'required Flutter route contracts only; not all page actions or painted text parity',
        'currentCodeExecuted': False,
        'referenceSha': REFERENCE_SHA, 'candidateShas': sorted(candidate_shas),
        'sourceHashes': manifest['sourceHashes'],
        'coverage': {
            'expectedUrlViewportPairs': len(expected), 'receiptFiles': len(records),
            'uniqueUrlViewportPairs': len(seen), 'completeExactlyOnce': complete,
            'validEvidencePairs': len(valid_evidence),
            'expectedCanonicalDestinationPairs': 210 * len(VIEWPORTS),
            'observedCanonicalDestinationPairs': len(observed_canonical),
            'canonicalUrlPairs': len(seen) - alias_pairs,
            'expectedAliasPairs': 5 * len(VIEWPORTS), 'observedAliasPairs': alias_pairs,
        },
        'requiredChecks': list(REQUIRED_CHECKS), 'optionalChecks': list(OPTIONAL_CHECKS),
        'perCheck': counts, 'requiredFailed': required_failed,
        'requiredUnverified': required_unverified,
        'optionalFailed': optional_failed, 'optionalUnverified': optional_unverified,
        'observedFailed': observed_failed,
        'missing': [{'route': route, 'viewport': viewport} for route, viewport in missing],
        'duplicates': duplicates, 'problems': problems,
        'note': 'Unverified and not_applicable are reported separately and are never counted as passed. '
                'Optional unverified checks remain outside the verified scope, even when result is passed.',
    }


def _write_or_print(data, output):
    text = json.dumps(data, ensure_ascii=False, indent=2, sort_keys=True) + '\n'
    if output is None:
        print(text, end='')
    else:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(text, encoding='utf-8')
        summary = {key: data[key] for key in ('schema', 'result', 'counts', 'coverage',
                                            'requiredFailed', 'requiredUnverified',
                                            'optionalFailed', 'optionalUnverified') if key in data}
        print(json.dumps({**summary, 'output': str(output)}, ensure_ascii=False, sort_keys=True))


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    inventory = commands.add_parser('catalogue', help='Emit the finite pinned public-route contract')
    inventory.add_argument('--output', type=Path)
    combine = commands.add_parser('aggregate', help='Verify all saved route/viewport receipts and PNGs')
    combine.add_argument('directory', type=Path)
    combine.add_argument('--output', type=Path)
    combine.add_argument('--candidate-sha', default=os.environ.get('CANDIDATE_SHA'))
    args = parser.parse_args(argv)
    try:
        data = make_catalogue() if args.command == 'catalogue' else aggregate(args.directory, candidate_sha=args.candidate_sha)
        _write_or_print(data, args.output)
        return 0 if args.command == 'catalogue' or data['result'] == 'passed' else 1
    except (OSError, ValueError) as error:
        print(f'audit contract: {error}', file=sys.stderr)
        return 2


if __name__ == '__main__':
    raise SystemExit(main())
