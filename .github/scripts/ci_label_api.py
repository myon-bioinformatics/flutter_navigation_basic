"""Strict read-only pagination shared by the ADD-only runner. No removal policy."""
import re

SHA = re.compile(r'[0-9a-f]{40}\Z')
REPO = re.compile(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\Z')
BAD = {'failure', 'timed_out', 'action_required', 'startup_failure'}


def _repo(value):
    if not isinstance(value, str) or not REPO.fullmatch(value) or any(p in ('.', '..') for p in value.split('/')):
        raise ValueError('explicit owner/repository required')
    return 'repos/' + value


def pages(request, path, key=None):
    """Strict sequential Link pages; stable check totals and unique item IDs."""
    rows, ids, total, page = [], set(), None, 1
    stem = path + ('&' if '?' in path else '?') + 'per_page=100&page='
    while True:
        data, next_path = request(stem + str(page))
        batch = data.get(key) if key and isinstance(data, dict) else data if key is None else None
        if not isinstance(batch, list) or len(batch) > 100:
            raise ValueError('invalid page')
        if key:
            count = data.get('total_count')
            if type(count) is not int or count < 0 or total is not None and count != total:
                raise ValueError('unstable total')
            total = count
        for row in batch:
            if not isinstance(row, dict) or type(row.get('id')) is not int or row['id'] in ids:
                raise ValueError('invalid/duplicate record')
            ids.add(row['id']); rows.append(row)
        if next_path is None:
            if total is not None and len(rows) != total:
                raise ValueError('incomplete pagination')
            return rows
        if not batch or next_path != stem + str(page + 1):
            raise ValueError('unexpected/cyclic pagination link')
        page += 1
        if page > 1000:
            raise ValueError('pagination budget exhausted; never complete')


def open_pulls(repository, request):
    return pages(request, _repo(repository) + '/pulls?state=open')
