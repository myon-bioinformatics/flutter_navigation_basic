"""Select Python fallback only when Non-Dart does not own full pytest.

The primary workflow stays byte-identical to its registered vendor hash.
Selection changes exercise the fallback itself; ordinary mixed changes have
one full-suite owner. The regression tests execute the real primary filter.
"""
import argparse
from fnmatch import fnmatchcase
from pathlib import Path
import subprocess

PRIMARY_PATHS = ('python/*', 'assets/time/*', 'assets/data_processing/*',
                 'test/fixtures/photo_studio/import_compat/*', 'lib/features/*_patterns/*',
                 'requirements.txt', '*/requirements.txt', '.github/workflows/non-dart.yml')
PRIMARY_TRIGGERS = ('python/*', 'assets/time/*', 'assets/data_processing/*',
                    'test/fixtures/photo_studio/import_compat/*', 'e2e/*',
                    'requirements.txt', '*/requirements.txt', '.dockerignore',
                    'lib/*.dart', 'test/*.dart', '.github/workflows/non-dart.yml')
SELF_PATHS = {'.github/workflows/dart.yml', 'python/oracle_selection.py',
              'python/tests/test_oracle_selection.py'}


def primary_owns(paths):
    triggered = any(fnmatchcase(path, pattern) for path in paths for pattern in PRIMARY_TRIGGERS)
    selected = any(fnmatchcase(path, pattern) for path in paths for pattern in PRIMARY_PATHS)
    return triggered and selected


def fallback_required(paths):
    return bool(set(paths) & SELF_PATHS) or not primary_owns(paths)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base', required=True)
    parser.add_argument('--head', required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args(argv)
    if args.base and set(args.base) == {'0'}:
        needed = True  # first push: unavailable diff must not remove coverage
    else:
        result = subprocess.run(['git', 'diff', '--name-only', args.base, args.head],
                                capture_output=True, text=True, check=True)
        needed = fallback_required(result.stdout.splitlines())
    with args.output.open('a', encoding='utf-8') as output:
        output.write('run=' + ('true' if needed else 'false') + '\n')
    print('Python oracle fallback: ' + ('selected' if needed else 'Non-Dart owns full pytest'))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
