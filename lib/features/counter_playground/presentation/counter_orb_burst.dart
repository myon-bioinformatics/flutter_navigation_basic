import 'package:flutter/material.dart';

import '../domain/counter_battle_effect.dart';

/// Short float-up burst of orbs + a damage/heal number (PAD-lite, no assets).
class CounterOrbBurst extends StatefulWidget {
  const CounterOrbBurst({
    super.key,
    required this.effect,
    required this.damageLabel,
    required this.healLabel,
    required this.idleLabel,
    this.playToken = 0,
  });

  final CounterBattleEffect effect;
  final String damageLabel;
  final String healLabel;
  final String idleLabel;

  /// Bump this when a counter action should replay the burst for the same value.
  final int playToken;

  @override
  State<CounterOrbBurst> createState() => _CounterOrbBurstState();
}

class _CounterOrbBurstState extends State<CounterOrbBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _rise = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<double> _fade = Tween<double>(begin: 0.25, end: 1).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1, curve: Curves.easeIn),
    ),
  );

  @override
  void initState() {
    super.initState();
    _playIfNeeded();
  }

  @override
  void didUpdateWidget(covariant CounterOrbBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playToken != widget.playToken) {
      _playIfNeeded();
    }
  }

  void _playIfNeeded() {
    if (widget.effect.isIdle) {
      _controller.stop();
      _controller.value = 0;
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effect = widget.effect;
    final theme = Theme.of(context);
    final accent = effect.isIdle
        ? theme.colorScheme.onSurfaceVariant
        : effect.isHeal
            ? const Color(0xFF2E7D32)
            : const Color(0xFFC62828);
    final label = effect.isIdle
        ? widget.idleLabel
        : effect.isHeal
            ? widget.healLabel
            : widget.damageLabel;

    return Column(
      children: [
        SizedBox(
          height: 56,
          child: effect.isIdle
              ? ExcludeSemantics(
                  child: Center(
                    child: Text(
                      '👾',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                )
              : AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fade.value,
                      child: Transform.translate(
                        offset: Offset(0, -18 * _rise.value),
                        child: child,
                      ),
                    );
                  },
                  child: ExcludeSemantics(
                    child: Center(
                      child: Text(
                        effect.orbs.join(' '),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 28, height: 1.1),
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 4),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: theme.textTheme.titleMedium!.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
          child: Text(label),
        ),
      ],
    );
  }
}
