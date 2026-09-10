/// Lightweight Puzzle & Dragons–style readout for the counter value.
///
/// Positive counts deal damage; negative counts heal by their absolute value.
class CounterBattleEffect {
  const CounterBattleEffect({
    required this.counter,
    required this.amount,
    required this.isHeal,
    required this.orbs,
  });

  static const List<String> attackOrbs = <String>[
    '🔥',
    '💧',
    '🌳',
    '💡',
    '🔮',
  ];
  static const List<String> healOrbs = <String>['❤️', '💚', '✨'];

  /// Maximum orbs shown in the strip (keeps the UI light).
  static const int maxOrbs = 6;

  final int counter;
  final int amount;
  final bool isHeal;
  final List<String> orbs;

  bool get isIdle => amount == 0;

  factory CounterBattleEffect.fromCounter(int counter) {
    if (counter == 0) {
      return const CounterBattleEffect(
        counter: 0,
        amount: 0,
        isHeal: false,
        orbs: <String>[],
      );
    }
    final isHeal = counter < 0;
    final amount = counter.abs();
    final palette = isHeal ? healOrbs : attackOrbs;
    final orbCount = amount.clamp(1, maxOrbs);
    final orbs = List<String>.generate(
      orbCount,
      (index) => palette[index % palette.length],
    );
    return CounterBattleEffect(
      counter: counter,
      amount: amount,
      isHeal: isHeal,
      orbs: orbs,
    );
  }
}
