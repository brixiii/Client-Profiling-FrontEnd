import 'dart:math';
import 'package:flutter/material.dart';

/// A washing-machine-shaped loading animation widget.
///
/// Usage:
///   WashingLoader()            // default 120 × 150 body
///   WashingLoader(scale: 1.5)  // 50 % larger
class WashingLoader extends StatefulWidget {
  /// Scale factor applied uniformly to every measurement.
  /// 1.0 = original CSS size (120 × 150 px body + 5 px feet).
  final double scale;

  const WashingLoader({Key? key, this.scale = 1.0}) : super(key: key);

  @override
  State<WashingLoader> createState() => _WashingLoaderState();
}

class _WashingLoaderState extends State<WashingLoader>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────
  late final AnimationController _shakeController;
  late final AnimationController _spinController;

  // ── Animations (values in degrees) ──────────────────────────────────────
  late final Animation<double> _shakeAngle;
  late final Animation<double> _spinAngle;

  @override
  void initState() {
    super.initState();

    // Both animations loop on a 3-second cycle, matching the CSS duration.
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Shake: still for the first 50 %, then rapid ±0.5° oscillation.
    // Mirrors the CSS @keyframes shake timings exactly.
    _shakeAngle = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0,  end: 0.0),  weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.0,  end: 0.5),  weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.5,  end: -0.5), weight: 10),
      TweenSequenceItem(tween: Tween(begin: -0.5, end: 0.5),  weight: 5),
      TweenSequenceItem(tween: Tween(begin: 0.5,  end: -0.5), weight: 4),
      TweenSequenceItem(tween: Tween(begin: -0.5, end: 0.5),  weight: 4),
      TweenSequenceItem(tween: Tween(begin: 0.5,  end: -0.5), weight: 4),
      TweenSequenceItem(tween: Tween(begin: -0.5, end: 0.5),  weight: 4),
      TweenSequenceItem(tween: Tween(begin: 0.5,  end: 0.0),  weight: 4),
    ]).animate(_shakeController);

    // Spin: one slow revolution then accelerates to 5 full turns.
    // Mirrors the CSS @keyframes spin: 0 → 360 → 750 → 1800 degrees.
    _spinAngle = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0,   end: 360.0),  weight: 50),
      TweenSequenceItem(tween: Tween(begin: 360.0, end: 750.0),  weight: 25),
      TweenSequenceItem(tween: Tween(begin: 750.0, end: 1800.0), weight: 25),
    ]).animate(_spinController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;

    return AnimatedBuilder(
      // Rebuild whenever either animation ticks.
      animation: Listenable.merge([_shakeAngle, _spinAngle]),
      builder: (context, _) {
        return Transform.rotate(
          angle: _shakeAngle.value * pi / 180,
          // CSS transform-origin: 60px 180px → offset from widget centre.
          // Widget centre Y = (150 + 5) / 2 = 77.5 → offset = 180 − 77.5 = 102.5
          origin: Offset(0, 102.5 * s),
          child: _buildMachine(s),
        );
      },
    );
  }

  // ── Machine body ─────────────────────────────────────────────────────────

  Widget _buildMachine(double s) {
    return SizedBox(
      width: 120 * s,
      height: 155 * s, // 150 (body) + 5 (feet)
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ① White rounded-rectangle body
          Positioned(
            left: 0, top: 0,
            child: Container(
              width: 120 * s,
              height: 150 * s,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7.2 * s), // CSS 6%
              ),
            ),
          ),

          // ② Horizontal divider stripe at y = 20 (splits controls from drum)
          Positioned(
            left: 0, top: 20 * s,
            child: Container(
              width: 120 * s,
              height: 4 * s,
              color: const Color(0xFFDDDDDD),
            ),
          ),

          // ③ Thin vertical strip at x = 45 (separates dial area)
          Positioned(
            left: 45 * s, top: 0,
            child: Container(
              width: (1 * s).clamp(1.0, double.infinity),
              height: 23 * s,
              color: const Color(0xFFDDDDDD),
            ),
          ),

          // ④ Control-panel indicator bar  (x = 8, y = 6, 30 × 8)
          Positioned(
            left: 8 * s, top: 6 * s,
            child: Container(
              width: 30 * s,
              height: 8 * s,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2 * s),
              ),
            ),
          ),

          // ⑤ Three small dial-button circles (top-right panel)
          _smallButton(left: 55 * s, top: 3 * s, size: 15 * s),
          _smallButton(left: 75 * s, top: 3 * s, size: 15 * s),
          _smallButton(left: 95 * s, top: 3 * s, size: 15 * s),

          // ⑥ Spinning front-door drum
          //    CSS: width/height = 95, bottom = 20, left/right = 0 (centred)
          //    → top = 150 − 20 − 95 = 35,  left = (120 − 95) / 2 = 12.5
          Positioned(
            left: 12.5 * s, top: 35 * s,
            child: Transform.rotate(
              angle: _spinAngle.value * pi / 180,
              child: SizedBox(
                width: 95 * s,
                height: 95 * s,
                child: CustomPaint(painter: _DoorPainter()),
              ),
            ),
          ),

          // ⑦ Left foot  (x = 5, y = 150)
          Positioned(
            left: 5 * s, top: 150 * s,
            child: _foot(s),
          ),

          // ⑧ Right foot  (x = 5 + 102 = 107, y = 150)
          // CSS: box-shadow: 102px 0 #aaa on the ::before element
          Positioned(
            left: 107 * s, top: 150 * s,
            child: _foot(s),
          ),
        ],
      ),
    );
  }

  // ── Helper builders ──────────────────────────────────────────────────────

  /// Tiny circular dial indicator painted via [_SmallButtonPainter].
  Widget _smallButton({
    required double left,
    required double top,
    required double size,
  }) {
    return Positioned(
      left: left, top: top,
      child: SizedBox(
        width: size, height: size,
        child: const CustomPaint(painter: _SmallButtonPainter()),
      ),
    );
  }

  /// Machine foot: small rounded bottom rectangle.
  Widget _foot(double s) {
    return Container(
      width: 7 * s,
      height: 5 * s,
      decoration: BoxDecoration(
        color: const Color(0xFFAAAAAA),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(4 * s),
          bottomRight: Radius.circular(4 * s),
        ),
      ),
    );
  }
}

// ── Small button painter ──────────────────────────────────────────────────
//
// Recreates: radial-gradient(ellipse at center, #aaa 25%, #eee 26%, #eee 50%, #0000 55%)
// Inner dot (#aaa) surrounded by a light-gray ring (#eee), rest transparent.

class _SmallButtonPainter extends CustomPainter {
  const _SmallButtonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Outer ring: light gray up to 50 % of canvas radius
    canvas.drawCircle(
      center, r * 0.50,
      Paint()..color = const Color(0xFFEEEEEE),
    );
    // Inner dot: dark gray at 25 % of canvas radius
    canvas.drawCircle(
      center, r * 0.25,
      Paint()..color = const Color(0xFFAAAAAA),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Door painter ──────────────────────────────────────────────────────────
//
// Recreates the CSS ::after element:
//   • 10 px #DDD border ring
//   • Light-blue base fill (#bbdefb)
//   • Hard-stop diagonal gradient (135°): #64b5f6 | #607d8b
//   • Repeating vertical semi-transparent stripes (30 px period)
//   • 4 px inset ring (#999)
//   • Radial dark vignette (simulates CSS inset box-shadow)
//
// The CustomPaint widget itself is wrapped in a Transform.rotate in the
// parent widget, so this painter never needs to repaint.

class _DoorPainter extends CustomPainter {
  const _DoorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2;

    // Proportional measurements (original CSS: 95 px element, 10 px border, 4 px inset)
    final borderW  = outerR * (10.0 / 47.5);
    final innerR   = outerR - borderW;
    final insetW   = outerR * (4.0  / 47.5);

    // ── 1. Outer border ring ─────────────────────────────────────────────
    canvas.drawCircle(
      center, outerR,
      Paint()..color = const Color(0xFFDDDDDD),
    );

    // ── 2. Clip following draws to the inner circle ──────────────────────
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: innerR)),
    );

    // ── 3. Base fill: light blue ─────────────────────────────────────────
    canvas.drawCircle(
      center, innerR,
      Paint()..color = const Color(0xFFBBDEFB),
    );

    // ── 4. Diagonal hard-stop gradient (135°) ───────────────────────────
    //    top-left half  = #64b5f6 (light blue)
    //    bottom-right half = #607d8b (blue-gray)
    final innerRect = Rect.fromLTWH(
      center.dx - innerR, center.dy - innerR,
      innerR * 2, innerR * 2,
    );
    canvas.drawRect(
      innerRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF64B5F6), Color(0xFF607D8B)],
          stops: [0.5, 0.5],
        ).createShader(innerRect),
    );

    // ── 5. Repeating vertical semi-transparent stripes ───────────────────
    //    CSS: background-size 30 px; 0–49 % of each tile = dark, 50–100 % = clear
    final period = size.width * (30.0 / 95.0);
    final stripeW = period / 2;
    final stripePaint = Paint()..color = const Color(0x44000000);
    for (double x = 0; x < size.width; x += period) {
      canvas.drawRect(Rect.fromLTWH(x, 0, stripeW, size.height), stripePaint);
    }

    canvas.restore(); // ── end clip ──

    // ── 6. Inner inset ring: 4 px stroke of #999 ────────────────────────
    canvas.drawCircle(
      center,
      innerR - insetW / 2,
      Paint()
        ..color = const Color(0xFF999999)
        ..style = PaintingStyle.stroke
        ..strokeWidth = insetW,
    );

    // ── 7. Radial dark vignette (CSS: 0 0 6px 6px #0004 inset) ──────────
    canvas.drawCircle(
      center, innerR,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0x00000000), Color(0x44000000)],
          stops: const [0.60, 1.00],
        ).createShader(Rect.fromCircle(center: center, radius: innerR)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
