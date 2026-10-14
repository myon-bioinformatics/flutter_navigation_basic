import pytest
from header_contracts import validate


def snapshot():
    return {'schemaVersion': 1, 'route': '/hub', 'title': 'Navigation Hub 🗺️', 'viewport': {'width': 390}, 'requiresSecondary': True, 'boxes': {
        'shared-header-title': {'x': 8, 'y': 14, 'width': 180, 'height': 28},
        'shared-header-home': {'x': 230, 'y': 4, 'width': 48, 'height': 48},
        'shared-header-favorite': {'x': 278, 'y': 4, 'width': 48, 'height': 48},
        'shared-header-menu': {'x': 326, 'y': 4, 'width': 48, 'height': 48},
        'shared-header-secondary': {'x': 0, 'y': 56, 'width': 390, 'height': 48},
    }}


def test_accepts_measured_two_row_contract():
    validate(snapshot())


@pytest.mark.parametrize('change', ['emoji', 'wrongEmoji', 'missing', 'overlap', 'overflow', 'commonRow'])
def test_rejects_broken_header_contract(change):
    data = snapshot()
    if change == 'emoji': data['title'] = 'Navigation Hub'
    elif change == 'wrongEmoji': data['title'] = 'Navigation Hub 🧭'
    elif change == 'missing': data['boxes'].pop('shared-header-menu')
    elif change == 'overlap': data['boxes']['shared-header-secondary']['y'] = 0
    elif change == 'overflow': data['boxes']['shared-header-title']['width'] = 1000
    else: data['boxes']['shared-header-home']['y'] += 48
    with pytest.raises((AssertionError, KeyError)):
        validate(data)
