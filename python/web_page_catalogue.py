"""Read this app's existing route declarations; no Dart SDK and no second route list."""
import hashlib
from pathlib import Path
import re
import tomllib

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ('lib/core/navigation/route_names.dart', 'lib/core/navigation/app_route_registry.dart',
           'lib/config/routes.dart', 'ci/numbered_routes.toml')


def catalogue(root=ROOT):
    raw = {name: (root / name).read_bytes() for name in SOURCES}
    names = raw[SOURCES[0]].decode()
    registry = raw[SOURCES[1]].decode()
    config = raw[SOURCES[2]].decode()
    declared = dict(re.findall(r"static const String (\w+)\s*=\s*'([^'$]+)'\s*;", names))
    used = set(re.findall(r'RouteNames\.(\w+)\s*:', registry))
    if used - declared.keys():
        raise ValueError('unresolved RouteNames in registry: ' + str(sorted(used - declared.keys())))
    paths = {declared[key] for key in used}
    paths.update(re.findall(r"^\s*'(/[^'$]*)'\s*:", registry, re.M))
    # AppRoutes registers the legacy mockApi alias outside the shared registry.
    mock = re.search(r"static const String mockApi\s*=\s*'([^'$]+)'\s*;", config)
    if not mock or 'map[mockApi]' not in config:
        raise ValueError('review changed AppRoutes alias declaration')
    paths.add(mock[1])
    routes = tomllib.loads(raw[SOURCES[3]].decode())['routes']
    paths.update('/screen' + str(int(key)) for key in routes)
    return {'schema': 'flutter-web-page-catalogue/1', 'routes': sorted(paths),
            'sources': {name: hashlib.sha256(value).hexdigest() for name, value in raw.items()}}
