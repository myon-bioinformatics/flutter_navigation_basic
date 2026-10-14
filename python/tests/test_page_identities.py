import copy
import pytest
from generate_page_identities import ALIASES, TARGET, generate, identities
from metadata_contracts import validate_page_identities


def document():
    emojis = identities()
    routes = list(emojis) + list(ALIASES)
    return {'emojis': emojis, 'aliases': ALIASES, 'publicRoutes': routes,
            'titles': {r: 'Page ' + emojis[ALIASES.get(r, r)] for r in routes}}


def test_registry_is_current_and_all_pages_are_unique():
    assert TARGET.read_text() == generate()
    validate_page_identities(document())


@pytest.mark.parametrize('mutation', ['duplicate', 'variantDuplicate', 'missing',
                                     'unknownRoute', 'wrongTitle', 'unknownAlias'])
def test_rejects_identity_regressions(mutation):
    data = copy.deepcopy(document())
    if mutation == 'duplicate': data['emojis']['/hub'] = data['emojis']['/screen8']
    elif mutation == 'variantDuplicate': data['emojis']['/hub'] = data['emojis']['/screen8'].replace('\ufe0f', '')
    elif mutation == 'missing': data['emojis'].pop('/screen198')
    elif mutation == 'unknownRoute': data['publicRoutes'].append('/new-page')
    elif mutation == 'wrongTitle': data['titles']['/hub'] = 'Page 🧭'
    else: data['aliases']['/examples/mock-api'] = '/missing'
    with pytest.raises((AssertionError, KeyError)):
        validate_page_identities(data)
