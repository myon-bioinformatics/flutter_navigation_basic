#!/usr/bin/env python3
"""Execute production Dart contracts with Dart SDK only, then check in Python.

No Flutter, pub get, pip, Node, browser or native build. --preflight checks the
current source graph only; it must never be reported as a Dart execution pass.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys

from generate_pattern_contracts import generate, TARGET
from pattern_contracts import validate, write_junit

ROOT = Path(__file__).resolve().parents[1]
ENTRY = ROOT / 'build_tools/export_pattern_contracts.dart'


def source_graph(entry=ENTRY, root=ROOT):
    """Conservative preflight for this producer's literal import directives.

    The real Dart compiler remains authoritative. External packages, dart:ui,
    missing files and paths outside this checkout fail rather than being mocked.
    """
    pending, sources = [entry.resolve()], {}
    while pending:
        file = pending.pop()
        if file in sources:
            continue
        file.relative_to(root.resolve())
        raw = file.read_bytes()
        sources[file] = hashlib.sha256(raw).hexdigest()
        text = re.sub(r'/\*.*?\*/|//[^\n]*', '', raw.decode(), flags=re.S)
        for kind, directive in re.findall(r'^\s*(import|export|part)\s+([^;]+);', text, re.M):
            if kind == 'part' and directive.startswith('of '):
                continue
            uris = re.findall(r'''['"]([^'"]+)['"]''', directive)
            if not uris:
                raise ValueError(f'nonliteral directive: {file}')
            for uri in uris:
                if uri.startswith('dart:'):
                    if uri in ('dart:ui', 'dart:html', 'dart:js', 'dart:js_interop'):
                        raise ValueError(f'non-VM SDK dependency: {uri}')
                    continue
                if uri.startswith('package:flutter_application_1/'):
                    target = root / 'lib' / uri.removeprefix('package:flutter_application_1/')
                elif ':' in uri:
                    raise ValueError(f'external dependency: {uri}')
                else:
                    target = file.parent / uri
                pending.append(target.resolve())
    return {file.relative_to(root.resolve()).as_posix(): sha for file, sha in sorted(sources.items())}


def package_config(root=ROOT):
    pubspec = (root/'pubspec.yaml').read_text(encoding='utf-8')
    match = re.search(r"sdk:\s*['\"]>=([0-9]+\.[0-9]+)\.[0-9]+", pubspec)
    if not match:
        raise ValueError('review changed SDK lower-bound syntax in pubspec.yaml')
    return {'configVersion': 2, 'packages': [{'name': 'flutter_application_1',
            'rootUri': root.resolve().as_uri()+'/', 'packageUri': 'lib/', 'languageVersion': match[1]}]}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--preflight', action='store_true')
    parser.add_argument('--dart', default='dart', help='Dart SDK executable')
    parser.add_argument('--output-dir', type=Path, default=ROOT/'build/test-results')
    args = parser.parse_args(argv)
    try:
        if TARGET.read_text(encoding='utf-8') != generate():
            raise ValueError('stale producer registry: run python/generate_pattern_contracts.py')
        sources = source_graph()
        config = package_config()
        if args.preflight:
            print(json.dumps({'scope': 'source-preflight', 'current_dart_executed': False,
                              'sources': len(sources), 'external_packages': []}))
            return 0
        dart = shutil.which(args.dart)
        if dart is None:
            raise ValueError('Dart SDK is required; Flutter is not. Install Dart or use --preflight for source inspection only.')
        output = args.output_dir.resolve()
        output.mkdir(parents=True, exist_ok=True)
        packages = output/'dart-pure-package-config.json'
        packages.write_text(json.dumps(config, indent=2)+'\n', encoding='utf-8')
        document_path = output/'pattern-contracts.json'
        junit = output/'pattern-contracts.xml'
        # Remove previous producer results before execution, so a failed command
        # cannot reuse a stale successful JSON/JUnit from this output directory.
        for path in (document_path, junit, output/'dart-pure-run.json'):
            if path.exists():
                path.unlink()
        version = subprocess.run([dart, '--version'], check=True, capture_output=True, text=True, timeout=10)
        command = [dart, '--disable-dart-dev', f'--packages={packages}', str(ENTRY), str(document_path)]
        result = subprocess.run(command, cwd=ROOT, check=False, timeout=120)
        if result.returncode:
            return result.returncode
        document = json.loads(document_path.read_bytes())
        failures = validate(document)
        write_junit(junit, failures)
        evidence = {'schema': 'dart-pure-contract-run/1', 'current_dart_executed': True,
                    'dart_version': (version.stdout+version.stderr).strip(), 'sources': sources,
                    'output_sha256': hashlib.sha256(document_path.read_bytes()).hexdigest(),
                    'failures': failures}
        (output/'dart-pure-run.json').write_text(json.dumps(evidence, indent=2)+'\n', encoding='utf-8')
        print(f'Production Dart contracts: {595-len(failures)} passed, {len(failures)} failed; Flutter not required')
        return 1 if failures else 0
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f'dart contracts: {error}', file=sys.stderr)
        return 2


if __name__ == '__main__':
    raise SystemExit(main())
