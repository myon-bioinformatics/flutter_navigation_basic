import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/navigation/app_navigation.dart';
import '../../../shared/display/display_scope.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/custom_button.dart';
import '../domain/irony_generator_controller.dart';

class IronyGeneratorPage extends StatefulWidget {
  const IronyGeneratorPage({super.key, required this.controller});

  final IronyGeneratorController controller;

  @override
  State<IronyGeneratorPage> createState() => _IronyGeneratorPageState();
}

class _IronyGeneratorPageState extends State<IronyGeneratorPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey _cardKey = GlobalKey();
  Offset _offset = Offset.zero;
  bool _isDragging = false;

  late final AnimationController _spawnController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..forward();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onIronyChanged);
  }

  @override
  void didUpdateWidget(covariant IronyGeneratorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onIronyChanged);
      widget.controller.addListener(_onIronyChanged);
    }
  }

  void _onIronyChanged() {
    if (mounted) setState(() {});
  }

  void _moveCard(DragUpdateDetails details) {
    setState(() => _offset += details.delta);
  }

  void _finishDrag(Size arenaSize) {
    final renderObject = _cardKey.currentContext?.findRenderObject();
    final cardSize = renderObject is RenderBox ? renderObject.size : Size.zero;
    final cardBounds = Rect.fromCenter(
      center: arenaSize.center(_offset),
      width: cardSize.width,
      height: cardSize.height,
    );
    final isOutside = !cardBounds.overlaps(Offset.zero & arenaSize);

    if (isOutside) {
      setState(() {
        _offset = Offset.zero;
        _isDragging = false;
      });
      widget.controller.generateNext();
      _spawnController.forward(from: 0);
    } else {
      setState(() => _isDragging = false);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onIronyChanged);
    widget.controller.dispose();
    _spawnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      appBar: CustomAppBar(title: display.text('nav.ironyGenerator')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final arenaSize = constraints.biggest;
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _spawnController,
                    builder: (context, child) => CustomPaint(
                      painter: reduceMotion
                          ? null
                          : _EvolutionBurstPainter(
                              progress: _spawnController.value,
                              primary: theme.colorScheme.primary,
                              secondary: theme.colorScheme.tertiary,
                            ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Transform.translate(
                  offset: _offset,
                  child: KeyedSubtree(
                    key: const ValueKey('irony-message-card'),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 140),
                      scale: _isDragging ? 1.035 : 1,
                      child: Card(
                        key: _cardKey,
                        elevation: _isDragging ? 12 : 4,
                        clipBehavior: Clip.antiAlias,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onPanStart: (_) =>
                                      setState(() => _isDragging = true),
                                  onPanUpdate: _moveCard,
                                  onPanEnd: (_) => _finishDrag(arenaSize),
                                  onPanCancel: () =>
                                      setState(() => _isDragging = false),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 8,
                                    ),
                                    child: Icon(Icons.drag_indicator),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Semantics(
                                  liveRegion: true,
                                  child: AnimatedSwitcher(
                                    duration: reduceMotion
                                        ? Duration.zero
                                        : const Duration(milliseconds: 420),
                                    transitionBuilder: (child, animation) =>
                                        FadeTransition(
                                      opacity: animation,
                                      child: ScaleTransition(
                                        scale: Tween<double>(
                                          begin: 0.82,
                                          end: 1,
                                        ).animate(
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutBack,
                                          ),
                                        ),
                                        child: child,
                                      ),
                                    ),
                                    child: SelectableText(
                                      widget.controller.irony,
                                      key: ValueKey(widget.controller.irony),
                                      style: theme.textTheme.headlineMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 20,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    CustomButton(
                      label: display.text('home.title'),
                      onPressed: AppNavigation.toHome,
                    ),
                    CustomButton(
                      label: display.text('nav.counterPlayground'),
                      onPressed: AppNavigation.toCounterPlayground,
                    ),
                    CustomButton(
                      label: display.text('nav.compositionGenerator'),
                      onPressed: AppNavigation.toCompositionGenerator,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EvolutionBurstPainter extends CustomPainter {
  const _EvolutionBurstPainter({
    required this.progress,
    required this.primary,
    required this.secondary,
  });

  final double progress;
  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final eased = Curves.easeOutCubic.transform(progress);
    final fade = (1 - progress).clamp(0.0, 1.0);
    final center = size.center(Offset.zero);
    final shortestSide = math.min(size.width, size.height);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 - (2 * progress)
      ..color = primary.withValues(alpha: 0.55 * fade);
    canvas.drawCircle(center, shortestSide * (0.06 + 0.42 * eased), ringPaint);

    for (var index = 0; index < 16; index += 1) {
      final angle = (math.pi * 2 * index / 16) + progress * 0.7;
      final innerRadius = shortestSide * (0.05 + 0.10 * eased);
      final outerRadius = shortestSide * (0.14 + 0.38 * eased);
      final direction = Offset(math.cos(angle), math.sin(angle));
      final rayPaint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = index.isEven ? 3 : 1.5
        ..color = (index.isEven ? primary : secondary)
            .withValues(alpha: 0.42 * fade);
      canvas.drawLine(
        center + direction * innerRadius,
        center + direction * outerRadius,
        rayPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EvolutionBurstPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary;
}
