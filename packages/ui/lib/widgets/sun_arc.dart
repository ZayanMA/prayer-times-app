import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:prayer_times_core/core.dart';

import '../theme/tokens.dart';

/// Celestial arc visualization — a parabola spanning Fajr→Isha with each
/// prayer marked as a dot and a glowing sun dot tracking [now].
class SunArc extends StatelessWidget {
  const SunArc({
    super.key,
    required this.prayers,
    required this.now,
    this.height = 120.0,
    this.use24h = true,
  });

  /// All prayer entries including Sunrise (it becomes a positional marker only).
  final List<PrayerTimeEntry> prayers;
  final DateTime now;
  final double height;
  final bool use24h;

  @override
  Widget build(BuildContext context) {
    // Need at least Fajr + one more prayer to draw a meaningful arc.
    final active = prayers.where((p) => p.name != 'Sunrise').toList();
    if (active.length < 2) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _SunArcPainter(
          prayers: active,
          now: now,
          use24h: use24h,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _SunArcPainter extends CustomPainter {
  _SunArcPainter({
    required this.prayers,
    required this.now,
    required this.use24h,
  });

  final List<PrayerTimeEntry> prayers;
  final DateTime now;
  final bool use24h;

  static const _gold = AppColors.accent;
  static const _labelSpacing = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (prayers.isEmpty) return;

    final first = prayers.first.begins;
    final last = prayers.last.begins;
    final spanMs = last.difference(first).inMilliseconds;
    if (spanMs <= 0) return;

    final w = size.width;
    final h = size.height;
    // Reserve top for name labels, bottom for time labels.
    const topPad = 20.0;
    const bottomPad = 18.0;
    final arcBot = h - bottomPad;
    final arcTop = topPad;

    // Normalize a DateTime → 0..1 within [first, last].
    double xOf(DateTime dt) =>
        (dt.difference(first).inMilliseconds / spanMs).clamp(0.0, 1.0);

    // Parabola: highest at midpoint.  y = arcBot - 4·x·(1−x)·(arcBot − arcTop)
    double yOf(double x) => arcBot - 4 * x * (1 - x) * (arcBot - arcTop);

    // ── 1. Horizon dashed line ──────────────────────────────────────────────
    _dashed(canvas, Offset(0, arcBot), Offset(w, arcBot),
        color: Colors.white.withAlpha(35), dash: 4, gap: 5);

    // ── 2. Arc path ─────────────────────────────────────────────────────────
    final arcPath = Path();
    for (int i = 0; i <= 80; i++) {
      final x = i / 80;
      final p = Offset(x * w, yOf(x));
      if (i == 0) {
        arcPath.moveTo(p.dx, p.dy);
      } else {
        arcPath.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      arcPath,
      Paint()
        ..color = Colors.white.withAlpha(90)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // ── 3. "Now" sun glow ───────────────────────────────────────────────────
    final nowX = xOf(now);
    final nowIsVisible = nowX >= 0 && nowX <= 1;
    if (nowIsVisible) {
      final np = Offset(nowX * w, yOf(nowX));
      // Outer halo
      canvas.drawCircle(
        np, 18,
        Paint()
          ..color = Colors.white.withAlpha(18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      // Inner glow
      canvas.drawCircle(
        np, 9,
        Paint()
          ..color = Colors.white.withAlpha(40)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      // Drop line
      _dashed(canvas, Offset(np.dx, np.dy + 7), Offset(np.dx, arcBot),
          color: Colors.white.withAlpha(55), dash: 2, gap: 3);
      // Core white dot (drawn last so it's on top)
      canvas.drawCircle(np, 5, Paint()..color = Colors.white);
    }

    // ── 4. Prayer dots & labels ─────────────────────────────────────────────
    final PrayerTimeEntry? nextEntry = _findNext();

    for (final p in prayers) {
      final x = xOf(p.begins);
      final pt = Offset(x * w, yOf(x));
      final isNext = p == nextEntry;
      final isPassed = p.begins.isBefore(now);

      final dotColor = isNext
          ? _gold
          : isPassed
              ? Colors.white.withAlpha(65)
              : Colors.white.withAlpha(170);
      final dotR = isNext ? 4.5 : 2.5;

      // Ring highlight on next prayer
      if (isNext) {
        canvas.drawCircle(
            pt,
            dotR + 5,
            Paint()
              ..color = _gold.withAlpha(70)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
      }
      canvas.drawCircle(pt, dotR, Paint()..color = dotColor);

      // Name label (above dot, three-letter abbreviation)
      final abbr = p.name.length >= 3 ? p.name.substring(0, 3).toUpperCase() : p.name.toUpperCase();
      _label(
        canvas, abbr,
        pt.dx, pt.dy - _labelSpacing,
        color: isNext
            ? _gold
            : isPassed
                ? Colors.white.withAlpha(55)
                : Colors.white.withAlpha(150),
        fontSize: 8.0,
      );

      // Time label (below horizon)
      _label(
        canvas, _fmt(p.begins),
        pt.dx, arcBot + 5,
        color: isNext
            ? _gold
            : Colors.white.withAlpha(isPassed ? 55 : 100),
        fontSize: 8.0,
      );
    }
  }

  PrayerTimeEntry? _findNext() {
    for (final p in prayers) {
      if (p.begins.isAfter(now)) return p;
    }
    return null;
  }

  String _fmt(DateTime dt) {
    if (use24h) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour < 12 ? 'a' : 'p';
    return '$h:${dt.minute.toString().padLeft(2, '0')}$ampm';
  }

  void _label(Canvas canvas, String text, double cx, double y,
      {required Color color, double fontSize = 9}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          letterSpacing: 1.1,
          height: 1,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, y - tp.height / 2));
  }

  void _dashed(Canvas canvas, Offset a, Offset b,
      {required Color color, double dash = 4, double gap = 4}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final dir = b - a;
    final total = dir.distance;
    if (total == 0) return;
    final unit = dir / total;
    final step = dash + gap;
    final n = (total / step).floor();
    for (int i = 0; i <= n; i++) {
      final s = a + unit * (i * step);
      final e = a + unit * math.min(i * step + dash, total);
      canvas.drawLine(s, e, paint);
    }
  }

  @override
  bool shouldRepaint(_SunArcPainter old) => old.now != now || old.prayers != prayers;
}
