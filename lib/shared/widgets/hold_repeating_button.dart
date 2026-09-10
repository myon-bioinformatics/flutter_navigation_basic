import 'dart:async';

import 'package:flutter/material.dart';

/// Material button that keeps calling [onPressed] while the pointer is held.
///
/// Uses [Listener] + [Timer] (common Flutter pattern for stepper / volume-style
/// hold-to-repeat). A short press fires once; holding after
/// [holdDelay] repeats every [holdInterval].
class HoldRepeatingButton extends StatefulWidget {
  const HoldRepeatingButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final Widget? label;

  static const Duration holdDelay = Duration(milliseconds: 350);
  static const Duration holdInterval = Duration(milliseconds: 70);

  @override
  State<HoldRepeatingButton> createState() => _HoldRepeatingButtonState();
}

class _HoldRepeatingButtonState extends State<HoldRepeatingButton> {
  Timer? _timer;
  int? _activePointer;

  bool get _enabled => widget.onPressed != null;

  void _clear() {
    _timer?.cancel();
    _timer = null;
    _activePointer = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!_enabled || _activePointer != null) return;
    _activePointer = event.pointer;
    widget.onPressed!();
    _timer = Timer(HoldRepeatingButton.holdDelay, () {
      _timer = Timer.periodic(HoldRepeatingButton.holdInterval, (_) {
        final action = widget.onPressed;
        if (action == null) {
          _clear();
          return;
        }
        action();
      });
    });
  }

  void _handlePointerEnd(PointerEvent event) {
    if (event.pointer == _activePointer) _clear();
  }

  @override
  void didUpdateWidget(covariant HoldRepeatingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) _clear();
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label;
    // onPressed stays non-null while enabled so Material styling / a11y match
    // a normal button; the real work runs from [Listener] to support hold.
    final VoidCallback? materialAction = _enabled ? () {} : null;
    final button = label == null
        ? IconButton.filled(
            onPressed: materialAction,
            icon: widget.icon,
          )
        : FilledButton.icon(
            onPressed: materialAction,
            icon: widget.icon,
            label: label,
          );

    return Listener(
      onPointerDown: _enabled ? _handlePointerDown : null,
      onPointerUp: _handlePointerEnd,
      onPointerCancel: _handlePointerEnd,
      child: button,
    );
  }
}
