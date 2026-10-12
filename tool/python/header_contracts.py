"""Validate measured browser header geometry exported by Playwright (stdlib)."""
import json
from pathlib import Path
import sys


def validate(snapshot):
    assert snapshot['schemaVersion'] == 1
    title = snapshot['title']
    assert any(0x1f000 <= ord(c) <= 0x1faff or 0x2600 <= ord(c) <= 0x27bf for c in title), 'title must include an emoji'
    boxes = snapshot['boxes']
    required = ('shared-header-title', 'shared-header-home', 'shared-header-favorite', 'shared-header-menu')
    for identity in required:
        box = boxes[identity]
        assert box['width'] > 0 and box['height'] > 0, f'{identity}: empty bounds'
        assert box['x'] >= -1 and box['x']+box['width'] <= snapshot['viewport']['width']+1, f'{identity}: horizontal overflow'
    title_box = boxes['shared-header-title']
    title_center = title_box['y']+title_box['height']/2
    for identity in required[1:]:
        box = boxes[identity]
        assert abs(box['y']+box['height']/2-title_center) <= 2, f'{identity}: outside common row'
    if snapshot['requiresSecondary']:
        secondary = boxes['shared-header-secondary']
        assert secondary['y'] >= max(boxes[i]['y']+boxes[i]['height'] for i in required)-1, 'page actions overlap common row'
        assert secondary['height'] >= 40, 'page action row too small'


if __name__ == '__main__':
    validate(json.loads(Path(sys.argv[1]).read_text()))
    print('Browser header JSON contract passed')
