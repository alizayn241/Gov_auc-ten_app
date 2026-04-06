import 'package:flutter/material.dart';

import '../../../../core/theme/entry_flow_tokens.dart';

class EntryBackground extends StatelessWidget {
  final Widget child;
  final bool light;

  const EntryBackground({
    super.key,
    required this.child,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = light
        ? const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                EntryFlowTokens.lightSurface,
              ],
            ),
          )
        : const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                EntryFlowTokens.backgroundTop,
                EntryFlowTokens.backgroundBottom,
                EntryFlowTokens.surface,
              ],
            ),
          );

    return Container(
      decoration: decoration,
      child: Stack(
        children: [
          _GlowOrb(
            alignment: Alignment.topLeft,
            color: light ? EntryFlowTokens.accent.withOpacity(0.1) : EntryFlowTokens.accentWarm.withOpacity(0.15),
            size: 220,
            offset: const Offset(-60, -30),
          ),
          _GlowOrb(
            alignment: Alignment.topRight,
            color: light ? EntryFlowTokens.backgroundBottom.withOpacity(0.08) : Colors.white.withOpacity(0.07),
            size: 180,
            offset: const Offset(30, 50),
          ),
          _GlowOrb(
            alignment: Alignment.bottomCenter,
            color: light ? EntryFlowTokens.accent.withOpacity(0.08) : EntryFlowTokens.accent.withOpacity(0.14),
            size: 280,
            offset: const Offset(0, 110),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _PanelPainter(light: light),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double size;
  final Offset offset;

  const _GlowOrb({
    required this.alignment,
    required this.color,
    required this.size,
    required this.offset,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: offset,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _PanelPainter extends CustomPainter {
  final bool light;

  const _PanelPainter({required this.light});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = light ? const Color(0x0F102241) : const Color(0x10FFFFFF);

    final first = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * .16, size.height * .12, size.width * .62, size.height * .22),
      const Radius.circular(26),
    );
    final second = RRect.fromRectAndRadius(
      Rect.fromLTWH(-size.width * .12, size.height * .52, size.width * .68, size.height * .2),
      const Radius.circular(26),
    );

    canvas.save();
    canvas.translate(size.width * .02, 0);
    canvas.rotate(-0.16);
    canvas.drawRRect(first, paint);
    canvas.restore();

    canvas.save();
    canvas.translate(size.width * .12, size.height * .04);
    canvas.rotate(0.08);
    canvas.drawRRect(second, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PanelPainter oldDelegate) {
    return oldDelegate.light != light;
  }
}
