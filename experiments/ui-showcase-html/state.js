/* Ordinary consumer state. No framework, persistence, or shared web-ui behavior. */
(function (root, factory) {
  'use strict';
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.ShowcaseFavoriteState = factory();
}(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';
  function initialState() { return Object.freeze({ favorite: false }); }
  function toggleFavorite(state) {
    if (!state || typeof state.favorite !== 'boolean') throw new TypeError('favorite must be boolean');
    return Object.freeze({ favorite: !state.favorite });
  }
  function favoritePresentation(state) {
    if (!state || typeof state.favorite !== 'boolean') throw new TypeError('favorite must be boolean');
    return Object.freeze({
      label: state.favorite ? 'Remove favorite' : 'Favorite this page',
      pressed: String(state.favorite)
    });
  }
  return Object.freeze({ initialState: initialState, toggleFavorite: toggleFavorite, favoritePresentation: favoritePresentation });
}));
