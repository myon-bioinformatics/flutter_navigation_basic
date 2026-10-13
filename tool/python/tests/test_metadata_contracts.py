import copy
import json
from pathlib import Path
import struct
import pytest
from metadata_contracts import ROOT, validate_screens, validate_locales


def screens():
    return json.loads((ROOT/'assets/screens.json').read_text())['screens']


def test_screen_catalogue_integrity():
    validate_screens(screens())


def test_locale_catalogue_integrity():
    validate_locales(json.loads((ROOT/'assets/display/app_text.json').read_text())['locales'])


@pytest.mark.parametrize('field,value', [('domainKey', 'wrong'), ('templateJa', 'wrong'), ('emoji', 'duplicate'), ('detail', None)])
def test_screen_oracle_rejects_mutations(field, value):
    data = screens()
    if field == 'emoji': value = data[1]['emoji']
    data[0][field] = value
    with pytest.raises(AssertionError):
        validate_screens(data)


def test_locale_oracle_rejects_missing_translation():
    data = json.loads((ROOT/'assets/display/app_text.json').read_text())['locales']
    data['jpn'].pop('urlParameters.case')
    with pytest.raises(AssertionError):
        validate_locales(data)


@pytest.mark.parametrize('name,size,rgba', [
    ('test_1_vertical_markers.png', (1080, 1920), False),
    ('test_3_transparent_shapes.png', (1024, 1024), True),
])
def test_png_fixture_geometry(name, size, rgba):
    data = (ROOT/'test/fixtures/photo_studio'/name).read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    assert struct.unpack('>II', data[16:24]) == size
    if rgba: assert data[25] == 6


def test_jpeg_fixture_geometry():
    data = (ROOT/'test/fixtures/photo_studio/test_2_horizontal_color_lines.jpg').read_bytes()
    assert data[:3] == b'\xff\xd8\xff'
    offset = 2
    while offset + 9 < len(data):
        assert data[offset] == 0xff
        marker = data[offset+1]
        length = int.from_bytes(data[offset+2:offset+4], 'big')
        assert length >= 2
        if marker in (0xc0, 0xc2):
            assert struct.unpack('>HH', data[offset+5:offset+9]) == (1080, 1920)
            return
        offset += 2 + length
    pytest.fail('JPEG has no supported SOF frame')


def test_shared_chrome_translations_preserve_title_placeholder():
    locales = json.loads((ROOT / 'assets/display/app_text.json').read_text(encoding='utf-8'))['locales']
    english = locales['eng']
    keys = {key for key in english if key.startswith(('header.', 'sessionClipboard.'))}
    assert len(keys) == 23
    for locale, values in locales.items():
        assert keys <= values.keys(), locale
        assert values['header.confirmBody'].count('{title}') == 1, locale
        for key in keys:
            assert values[key].strip(), f'{locale}:{key}'


def test_standalone_chrome_fallbacks_match_catalog_english():
    import re
    english = json.loads((ROOT / 'assets/display/app_text.json').read_text(encoding='utf-8'))['locales']['eng']
    for name, prefix in [('standard_page_header', 'header.'), ('session_text_clipboard', 'sessionClipboard.')]:
        source = (ROOT / f'lib/shared/widgets/{name}.dart').read_text(encoding='utf-8')
        table = source.split('const _standaloneText = <String, String>{', 1)[1].split('};', 1)[0]
        fallbacks = {json.loads(key): json.loads(value) for key, value in re.findall(r'("[^"\n]+"):\s*("[^"\n]+")', table)}
        assert fallbacks == {key: value for key, value in english.items() if key.startswith(prefix)}
