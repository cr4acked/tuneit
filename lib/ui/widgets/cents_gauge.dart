import 'package:flutter/material.dart';

import '../../core/constants.dart';

/// Horizontal -50..+50 cents scale with an animated needle and a highlighted
/// in-tune zone. Color is never the only cue: the parent shows direction
/// text and arrows alongside.
class CentsGauge extends StatelessWidget {
  const CentsGauge({
    super.key,
    required this.cents,
    required this.inTuneCents,
    required this.color,
  });

  /// Current offset in cents, or null when there is no signal.
  final double? cents;

  final double inTuneCents;

  final Color color;

  @override
  Widget build(BuildContext context) {
    final clamped =
        (cents ?? 0).clamp(-kGaugeRangeCents, kGaugeRangeCents).toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween(end: clamped),
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      builder: (context, animated, _) {
        return CustomPaint(
          size: const Size(double.infinity, 96),
          painter: _GaugePainter(
            cents: cents == null ? null : animated,
            inTuneCents: inTuneCents,
            needleColor: color,
            scheme: Theme.of(context).colorScheme,
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.cents,
    required this.inTuneCents,
    required this.needleColor,
    required this.scheme,
  });

  final double? cents;
  final double inTuneCents;
  final Color needleColor;
  final ColorScheme scheme;

  double _x(Size size, double c) {
    const pad = 12.0;
    final usable = size.width - pad * 2;
    return pad + (c + kGaugeRangeCents) / (2 * kGaugeRangeCents) * usable;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final baselineY = size.height * 0.62;

    // In-tune zone band.
    final zonePaint = Paint()
      ..color = const Color(0xFF2E9E5B).withValues(alpha: 0.18);
    canvas.drawRRect(
      RRect.fromLTRBR(
        _x(size, -inTuneCents),
        baselineY - 26,
        _x(size, inTuneCents),
        baselineY + 26,
        const Radius.circular(6),
      ),
      zonePaint,
    );

    // Ticks every 10 cents, taller at 0 / +-25 / +-50.
    final tickPaint = Paint()
      ..color = scheme.onSurfaceVariant.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;
    for (var c = -50; c <= 50; c += 10) {
      final major = c == 0 || c.abs() == 50 || c.abs() == 30;
      final h = major ? 18.0 : 10.0;
      final x = _x(size, c.toDouble());
      canvas.drawLine(
        Offset(x, baselineY - h),
        Offset(x, baselineY + h),
        tickPaint,
      );
    }

    // Center marker.
    final centerPaint = Paint()
      ..color = scheme.onSurface
      ..strokeWidth = 2.5;
    final cx = _x(size, 0);
    canvas.drawLine(
      Offset(cx, baselineY - 24),
      Offset(cx, baselineY + 24),
      centerPaint,
    );

    // Needle.
    if (cents != null) {
      final x =
          _x(size, cents!.clamp(-kGaugeRangeCents, kGaugeRangeCents).toDouble());
      final needlePaint = Paint()
        ..color = needleColor
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x, baselineY - 34),
        Offset(x, baselineY + 34),
        needlePaint,
      );
      final tip = Path()
        ..moveTo(x - 7, baselineY - 44)
        ..lineTo(x + 7, baselineY - 44)
        ..lineTo(x, baselineY - 32)
        ..close();
      canvas.drawPath(tip, Paint()..color = needleColor);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) {
    return oldDelegate.cents != cents ||
        oldDelegate.inTuneCents != inTuneCents ||
        oldDelegate.needleColor != needleColor ||
        oldDelegate.scheme != scheme;
  }
}
