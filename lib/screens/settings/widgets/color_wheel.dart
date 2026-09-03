import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A draggable circular hue/saturation color wheel. Brightness (HSV
/// "value") is controlled separately via the shade slider next to it,
/// per spec: "a shade/brightness slider alongside the wheel".
class ColorWheel extends StatefulWidget {
  final double hue;
  final double saturation;
  final double value;
  final double size;
  final ValueChanged<HSVColor> onChanged;

  const ColorWheel({
    Key? key,
    required this.hue,
    required this.saturation,
    required this.value,
    required this.onChanged,
    this.size = 240,
  }) : super(key: key);

  @override
  State<ColorWheel> createState() => _ColorWheelState();
}

class _ColorWheelState extends State<ColorWheel> {
  void _handlePan(Offset localPosition) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final radius = widget.size / 2;
    final delta = localPosition - center;
    final distance = delta.distance.clamp(0.0, radius);

    double angle = math.atan2(delta.dy, delta.dx); // -pi..pi
    double hueDeg = (angle * 180 / math.pi + 360) % 360;
    double sat = (distance / radius).clamp(0.0, 1.0);

    widget.onChanged(HSVColor.fromAHSV(1.0, hueDeg, sat, widget.value));
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.size / 2;
    final angleRad = widget.hue * math.pi / 180;
    final pointerDistance = widget.saturation * radius;
    final pointerOffset = Offset(
      radius + pointerDistance * math.cos(angleRad),
      radius + pointerDistance * math.sin(angleRad),
    );

    return GestureDetector(
      onPanStart: (d) => _handlePan(d.localPosition),
      onPanUpdate: (d) => _handlePan(d.localPosition),
      onTapDown: (d) => _handlePan(d.localPosition),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Hue ring
            Container(
              width: widget.size,
              height: widget.size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Color(0xFFFF0000),
                    Color(0xFFFFFF00),
                    Color(0xFF00FF00),
                    Color(0xFF00FFFF),
                    Color(0xFF0000FF),
                    Color(0xFFFF00FF),
                    Color(0xFFFF0000),
                  ],
                ),
              ),
            ),
            // Saturation overlay: white at center -> transparent at edge
            Container(
              width: widget.size,
              height: widget.size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.white, Color(0x00FFFFFF)],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
            // Brightness overlay: darken the whole wheel as value drops
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity((1 - widget.value).clamp(0.0, 1.0)),
              ),
            ),
            // Pointer
            Positioned(
              left: pointerOffset.dx - 10,
              top: pointerOffset.dy - 10,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: HSVColor.fromAHSV(1.0, widget.hue, widget.saturation, widget.value).toColor(),
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
