// File: lib/screens/settings/widgets/color_wheel_picker.dart
// Unchanged — CustomPainter-based wheel already matches the prototype's
// conic-gradient wheel concept, but with a real functioning
// hue/saturation picker (prototype's version just moves a static dot).

import 'dart:math' as math;
import 'package:flutter/material.dart';

class ColorWheelPicker extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onChanged;
  final double size;

  const ColorWheelPicker({
    super.key,
    required this.color,
    required this.onChanged,
    this.size = 240,
  });

  void _handleTouch(Offset localPosition) {
    final center = Offset(size / 2, size / 2);
    final radius = size / 2;
    final delta = localPosition - center;
    final distance = delta.distance;
    final angle = math.atan2(delta.dy, delta.dx);

    final hue = (angle * 180 / math.pi + 360) % 360;
    final saturation = (distance / radius).clamp(0.0, 1.0);

    final currentHsv = HSVColor.fromColor(color);
    final newColor =
        HSVColor.fromAHSV(1.0, hue, saturation, currentHsv.value).toColor();
    onChanged(newColor);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (details) => _handleTouch(details.localPosition),
      onPanUpdate: (details) => _handleTouch(details.localPosition),
      onTapDown: (details) => _handleTouch(details.localPosition),
      child: CustomPaint(
        size: Size(size, size),
        painter: _ColorWheelPainter(color: color),
      ),
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  final Color color;
  _ColorWheelPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final huePaint = Paint()
      ..shader = SweepGradient(
        colors: List.generate(
          361,
          (i) => HSVColor.fromAHSV(1.0, i.toDouble(), 1.0, 1.0).toColor(),
        ),
      ).createShader(rect);
    canvas.drawCircle(center, radius, huePaint);

    final saturationPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.white, Color(0x00FFFFFF)],
      ).createShader(rect);
    canvas.drawCircle(center, radius, saturationPaint);

    final borderPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 1, borderPaint);

    final hsv = HSVColor.fromColor(color);
    final angleRad = hsv.hue * math.pi / 180;
    final dist = hsv.saturation * radius;
    final pointerOffset =
        center + Offset(math.cos(angleRad) * dist, math.sin(angleRad) * dist);

    canvas.drawCircle(
      pointerOffset,
      12,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(pointerOffset, 8, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ColorWheelPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class ShadeSlider extends StatelessWidget {
  final Color baseColor;
  final double shade;
  final ValueChanged<double> onChanged;

  const ShadeSlider({
    super.key,
    required this.baseColor,
    required this.shade,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hsv = HSVColor.fromColor(baseColor);
    final dark = hsv.withValue(0.15).toColor();
    final light = hsv.withValue(1.0).toColor();

    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(colors: [dark, light]),
              border: Border.all(color: Colors.white24, width: 1),
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 12,
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              thumbColor: Colors.white,
              overlayColor: Colors.white24,
            ),
            child: Slider(
              value: shade.clamp(0.0, 1.0),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
