import 'dart:async';

import 'package:flutter/material.dart';

/// Material button that keeps calling [onPressed] while the pointer is held.
///
/// Single taps, keyboard activation, and accessibility use the Material
/// button's real [onPressed]. [Listener] only starts repeating after
/// [holdDelay]; if a hold already repeated, the trailing Material tap is
/// swallowed once so it does not double-fire.
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
  bool _didRepeat = false;

  bool get _enabled => widget.onPressed != null;

  void _clearTimers() {
    _timer?.cancel();
    _timer = null;
    _activePointer = null;
  }

  void _handleMaterialPressed() {
    if (!_enabled) return;
    if (_didRepeat) {
      // Hold already applied increments; ignore the release tap once.
      _didRepeat = false;
      return;
    }
    widget.onPressed!();
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!_enabled || _activePointer != null) return;
    _activePointer = event.pointer;
    _didRepeat = false;
    _timer = Timer(HoldRepeatingButton.holdDelay, () {
      if (!_enabled || _activePointer == null) return;
      _didRepeat = true;
      widget.onPressed!();
      _timer = Timer.periodic(HoldRepeatingButton.holdInterval, (_) {
        final action = widget.onPressed;
        if (action == null) {
          _clearTimers();
          return;
        }
        _didRepeat = true;
        action();
      });
    });
  }

  void _handlePointerEnd(PointerEvent event) {
    if (event.pointer != _activePointer) return;
    final hadRepeated = _didRepeat;
    _clearTimers();
    // After a hold, Material may still deliver one release tap (consumed by
    // `_handleMaterialPressed`) or cancel the tap when the pointer leaves.
    // Clear any unconsumed sticky flag after this frame so the next
    // keyboard / semantics activation is not suppressed.
    if (hadRepeated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _didRepeat = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant HoldRepeatingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) {
      _clearTimers();
      _didRepeat = false;
    }
  }

  @override
  void dispose() {
    _clearTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label;
    final button = label == null
        ? IconButton.filled(
            onPressed: _enabled ? _handleMaterialPressed : null,
            icon: widget.icon,
          )
        : FilledButton.icon(
            onPressed: _enabled ? _handleMaterialPressed : null,
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
