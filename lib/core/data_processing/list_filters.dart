/// Shared list-filter helpers used by data-processing catalogue patterns.
///
/// Keep runtime-only operations here rather than duplicating them in each
/// generated pattern service.
List<T> filterEquals<T>(Iterable<T> values, T equals) =>
    List<T>.unmodifiable(values.where((value) => value == equals));
