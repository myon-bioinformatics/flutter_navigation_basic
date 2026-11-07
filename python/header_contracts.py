"""Validate measured browser header geometry exported by Playwright (stdlib)."""
import json, sys
from pathlib import Path
from generate_page_identities import ALIASES, identities


def validate(snapshot):
    if not (snapshot['schemaVersion'] == 1):
        raise AssertionError('header_contracts:9: validation failed')
    title = snapshot['title']
    route = snapshot['route']
    expected = identities()[ALIASES.get(route, route)]
    if not (title.endswith(' ' + expected)):
        raise AssertionError(f'{route}: wrong page emoji')
    if not (any(0x1f000 <= ord(c) <= 0x1faff or 0x2600 <= ord(c) <= 0x27bf for c in title)):
        raise AssertionError('title must include an emoji')
    boxes = snapshot['boxes']
    required = ('shared-header-title', 'shared-header-home', 'shared-header-favorite', 'shared-header-menu')
    for identity in required:
        box = boxes[identity]
        if not (box['width'] > 0 and box['height'] > 0):
            raise AssertionError(f'{identity}: empty bounds')
        if not (box['x'] >= -1 and box['x']+box['width'] <= snapshot['viewport']['width']+1):
            raise AssertionError(f'{identity}: horizontal overflow')
    title_box = boxes['shared-header-title']
    title_center = title_box['y']+title_box['height']/2
    for identity in required[1:]:
        box = boxes[identity]
        if not (abs(box['y']+box['height']/2-title_center) <= 2):
            raise AssertionError(f'{identity}: outside common row')
    if snapshot['requiresSecondary']:
        secondary = boxes['shared-header-secondary']
        if not (secondary['y'] >= max(boxes[i]['y']+boxes[i]['height'] for i in required)-1):
            raise AssertionError('page actions overlap common row')
        if not (secondary['height'] >= 40):
            raise AssertionError('page action row too small')


if __name__ == '__main__':
    validate(json.loads(Path(sys.argv[1]).read_text()))
    print('Browser header JSON contract passed')
