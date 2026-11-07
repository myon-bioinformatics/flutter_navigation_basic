'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const model = require('./state.js');
const read = name => fs.readFileSync(path.join(__dirname, name), 'utf8');

test('initial state and presentation are unselected and immutable', () => {
  const state = model.initialState();
  assert.deepEqual(state, {favorite: false});
  assert.equal(Object.isFrozen(state), true);
  assert.deepEqual(model.favoritePresentation(state), {label: 'Favorite this page', pressed: 'false'});
});

test('favorite toggles both ways without mutating old state', () => {
  const initial = model.initialState();
  const selected = model.toggleFavorite(initial);
  assert.deepEqual(selected, {favorite: true});
  assert.deepEqual(initial, {favorite: false});
  assert.notEqual(initial, selected);
  assert.equal(Object.isFrozen(selected), true);
  assert.deepEqual(model.favoritePresentation(selected), {label: 'Remove favorite', pressed: 'true'});
  assert.deepEqual(model.toggleFavorite(selected), initial);
});

test('repeated toggles are deterministic, and a new session starts unselected', () => {
  let state = model.initialState();
  for (let index = 1; index <= 101; index++) {
    state = model.toggleFavorite(state);
    assert.equal(state.favorite, index % 2 === 1);
  }
  assert.equal(model.initialState().favorite, false);
});

test('invalid state is rejected rather than coerced', () => {
  for (const state of [undefined, null, {}, {favorite: 'false'}, {favorite: 0}]) {
    assert.throws(() => model.toggleFavorite(state), TypeError);
    assert.throws(() => model.favoritePresentation(state), TypeError);
  }
});

function appHarness() {
  const attributes = new Map();
  const listeners = new Map();
  const button = {disabled: true, setAttribute: (name, value) => attributes.set(name, value), addEventListener: (name, fn) => listeners.set(name, fn)};
  const context = {document: {querySelector: selector => {
    assert.equal(selector, '[data-testid="shared-header-favorite"]');
    return button;
  }}, window: {ShowcaseFavoriteState: model}};
  vm.runInNewContext(read('app.js'), context, {filename: 'app.js'});
  return {button, attributes, click: () => listeners.get('click')()};
}

test('app wiring synchronizes accessible name, pressed state, and tooltip', () => {
  const app = appHarness();
  assert.equal(app.button.disabled, false);
  assert.equal(app.attributes.get('aria-label'), 'Favorite this page');
  assert.equal(app.attributes.get('aria-pressed'), 'false');
  app.click();
  assert.equal(app.attributes.get('aria-label'), 'Remove favorite');
  assert.equal(app.attributes.get('aria-pressed'), 'true');
  assert.equal(app.attributes.get('title'), 'Remove favorite');
  app.click();
  assert.equal(app.attributes.get('aria-pressed'), 'false');
});

test('reinitializing the app resets favorite, with no persistent storage', () => {
  const first = appHarness(); first.click();
  const reloaded = appHarness();
  assert.equal(reloaded.attributes.get('aria-pressed'), 'false');
  assert.doesNotMatch(read('app.js') + read('state.js'), /localStorage|sessionStorage|indexedDB|document\.cookie|innerHTML|eval\(/);
});

test('classic browser build exports the same state API without CommonJS', () => {
  const context = {};
  vm.runInNewContext(read('state.js'), context, {filename: 'state.js'});
  assert.equal(context.ShowcaseFavoriteState.initialState().favorite, false);
  assert.equal(context.ShowcaseFavoriteState.toggleFavorite({favorite: false}).favorite, true);
});

test('native adapter retains the BTK v1 boundary and accessible-name postcondition', () => {
  const adapter = JSON.parse(read('native-ui-showcase.adapter.json'));
  const html = read('index.html');
  assert.equal(adapter.schema, 'btk-platform-adapter/1');
  assert.equal(adapter.flutter_semantics, false);
  assert.deepEqual(adapter.provenance.field, ['reference_revision']);
  assert.equal(adapter.click.attribute, 'aria-label');
  assert.equal(adapter.click.before, 'Favorite this page');
  assert.equal(adapter.click.after, 'Remove favorite');
  for (const selector of adapter.elements) {
    const [, id] = selector.match(/^\[data-testid="([^"]+)"\]$/);
    assert.equal([...html.matchAll(new RegExp('data-testid="' + id + '"', 'g'))].length, 1);
  }
  assert.match(html, /<button[^>]*data-testid="shared-header-favorite"[^>]*aria-pressed="false"[^>]*disabled>/);
});

test('fixture reuses local CSS and marks all controls unavailable before initialization', () => {
  const html = read('index.html');
  for (const name of ['tokens', 'base', 'components']) {
    assert.ok(html.includes('vendor/web-ui/' + name + '.css'));
    assert.ok(fs.existsSync(path.join(__dirname, 'vendor/web-ui/', name + '.css')));
  }
  for (const button of html.matchAll(/<button\b[^>]*>/g)) {
    assert.match(button[0], /\bdisabled\b/);
    if (!button[0].includes('shared-header-favorite')) assert.match(button[0], /aria-describedby="out-of-scope"/);
  }
  assert.match(html, /Local HTML fixture/);
  assert.match(html, /<main[^>]*tabindex="0"/);
  assert.match(read('style.css'), /:focus-visible/);
  assert.ok(fs.existsSync(path.join(__dirname, 'vendor/web-ui/LICENSE')));
});

test('vendored CSS retains exact pinned upstream content and license hashes', () => {
  const crypto = require('node:crypto');
  const provenance = JSON.parse(read('provenance.json'));
  assert.equal(provenance.web_ui_revision, '6c51fd53a11b24b2f8d0205a2a9c597fb5f2b558');
  for (const entry of provenance.vendored_web_ui) {
    const data = fs.readFileSync(path.join(__dirname, entry.path));
    assert.equal(crypto.createHash('sha256').update(data).digest('hex'), entry.sha256);
    assert.equal(crypto.createHash('sha1').update(Buffer.from('blob ' + data.length + '\0')).update(data).digest('hex'), entry.git_blob_sha);
  }
});
