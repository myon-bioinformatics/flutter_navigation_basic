import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/counter_playground/domain/counter_battle_effect.dart';

void main() {
  group('CounterBattleEffect', () {
    test('idle at zero', () {
      final effect = CounterBattleEffect.fromCounter(0);
      expect(effect.isIdle, isTrue);
      expect(effect.amount, 0);
      expect(effect.orbs, isEmpty);
    });

    test('positive counter deals damage with attack orbs', () {
      final effect = CounterBattleEffect.fromCounter(3);
      expect(effect.isHeal, isFalse);
      expect(effect.amount, 3);
      expect(effect.orbs, ['🔥', '💧', '🌳']);
    });

    test('negative counter heals by absolute value with heart orbs', () {
      final effect = CounterBattleEffect.fromCounter(-2);
      expect(effect.isHeal, isTrue);
      expect(effect.amount, 2);
      expect(effect.orbs, ['❤️', '💚']);
    });

    test('caps orb strip length', () {
      final effect = CounterBattleEffect.fromCounter(20);
      expect(effect.amount, 20);
      expect(effect.orbs, hasLength(CounterBattleEffect.maxOrbs));
    });
  });
}
