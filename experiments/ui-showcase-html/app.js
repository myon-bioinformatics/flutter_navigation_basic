(function () {
  'use strict';
  var favorite = document.querySelector('[data-testid="shared-header-favorite"]');
  var model = window.ShowcaseFavoriteState;
  if (!favorite || !model) return;
  var state = model.initialState();
  function render() {
    var presentation = model.favoritePresentation(state);
    favorite.setAttribute('aria-label', presentation.label);
    favorite.setAttribute('aria-pressed', presentation.pressed);
    favorite.setAttribute('title', presentation.label);
  }
  favorite.addEventListener('click', function () { state = model.toggleFavorite(state); render(); });
  render();
  favorite.disabled = false;
}());
