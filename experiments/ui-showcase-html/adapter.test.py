"""Dependency-free regression through the actual BTK adapter implementation.

The request is fake: this tests metadata traversal, not live HTTP or browser QA.
"""
from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path
from types import SimpleNamespace
import unittest

ROOT = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location(
    'btk_platform_adapter', Path(os.environ.get('BTK_PLATFORM_ADAPTER', ROOT.parents[1] / '.reference-kit/scripts/platform_adapter.py')))
platform_adapter = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(platform_adapter)


class AdapterProvenanceTest(unittest.TestCase):
    def test_actual_reader_returns_reference_revision_from_same_directory(self):
        config = platform_adapter.load_adapter(ROOT / 'native-ui-showcase.adapter.json')
        metadata_bytes = (ROOT / 'provenance.json').read_bytes()
        metadata = json.loads(metadata_bytes)
        calls = []

        def get(url, *, timeout):
            calls.append((url, timeout))
            return SimpleNamespace(status=200, ok=True, body=lambda: metadata_bytes)

        page = SimpleNamespace(request=SimpleNamespace(get=get))
        result = platform_adapter.read_provenance(page, config, config['url'])
        self.assertEqual(config['provenance']['field'], ['reference_revision'])
        self.assertEqual(result['value'], '9b38f3e935e9e171cbacc3af63f539ddce9db86b')
        self.assertIsNone(result['error'])
        self.assertEqual(result['status'], 200)
        self.assertEqual(result['url'], 'http://127.0.0.1:8765/provenance.json')
        self.assertEqual(calls, [('http://127.0.0.1:8765/provenance.json', 15000)])
        self.assertEqual(metadata['web_ui_revision'], '6c51fd53a11b24b2f8d0205a2a9c597fb5f2b558')
        self.assertEqual(metadata['browser_test_kit_revision'], 'f37c438a5285a03b39adda052ad14598a2ca8966')

    def test_independent_fields_are_not_a_nested_path(self):
        """The old multi-field value must reproduce field_missing, not a SHA."""
        config = platform_adapter.load_adapter(ROOT / 'native-ui-showcase.adapter.json')
        config['provenance']['field'] = ['fixture', 'reference_revision']
        page = SimpleNamespace(request=SimpleNamespace(get=lambda *args, **kwargs:
            SimpleNamespace(status=200, ok=True, body=lambda: (ROOT / 'provenance.json').read_bytes())))
        result = platform_adapter.read_provenance(page, config, config['url'])
        self.assertIsNone(result['value'])
        self.assertEqual(result['error'], 'field_missing')


if __name__ == '__main__':
    unittest.main(verbosity=2)
