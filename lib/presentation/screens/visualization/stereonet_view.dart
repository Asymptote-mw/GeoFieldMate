import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../data/models/field_record.dart';
import '../../../core/constants/colors.dart';

/// Widget to display stereonet projection of dip and strike data
class StereonetView extends StatefulWidget {
  final List<FieldRecord> records;

  const StereonetView({super.key, required this.records});

  @override
  State<StereonetView> createState() => _StereonetViewState();
}

class _StereonetViewState extends State<StereonetView> {
  bool _showPoles = true;
  bool _showPlanes = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Controls
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Display Options',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Show Poles'),
                  subtitle: const Text('Display pole projections'),
                  value: _showPoles,
                  onChanged: (value) => setState(() => _showPoles = value),
                ),
                SwitchListTile(
                  title: const Text('Show Planes'),
                  subtitle: const Text('Display great circles'),
                  value: _showPlanes,
                  onChanged: (value) => setState(() => _showPlanes = value),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Measurements: ${widget.records.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Stereonet display
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: CustomPaint(
                  painter: StereonetPainter(
                    records: widget.records,
                    showPoles: _showPoles,
                    showPlanes: _showPlanes,
                  ),
                  child: Container(),
                ),
              ),
            ),
          ),
        ),

        // Legend
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Legend',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _buildLegendItem(AppColors.igneous, 'Igneous'),
                _buildLegendItem(AppColors.sedimentary, 'Sedimentary'),
                _buildLegendItem(AppColors.metamorphic, 'Metamorphic'),
                const SizedBox(height: 8),
                const Text(
                  'Lower hemisphere equal-area projection (Schmidt net)',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

/// Custom painter for stereonet
class StereonetPainter extends CustomPainter {
  final List<FieldRecord> records;
  final bool showPoles;
  final bool showPlanes;

  StereonetPainter({
    required this.records,
    required this.showPoles,
    required this.showPlanes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw outer circle
    final outlinePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, outlinePaint);

    // Draw grid lines
    _drawGrid(canvas, center, radius);

    // Draw cardinal directions
    _drawCardinalDirections(canvas, center, radius);

    // Plot data points
    for (final record in records) {
      if (record.dip != null && record.strike != null) {
        final color = _getColorForRockType(record.rockType);

        if (showPoles) {
          _plotPole(canvas, center, radius, record.dip!, record.strike!, color);
        }

        if (showPlanes) {
          _plotPlane(
              canvas, center, radius, record.dip!, record.strike!, color);
        }
      }
    }
  }

  void _drawGrid(Canvas canvas, Offset center, double radius) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw concentric circles (every 10 degrees dip)
    for (int i = 1; i < 9; i++) {
      final r = radius * (i / 9.0);
      canvas.drawCircle(center, r, gridPaint);
    }

    // Draw radial lines (every 30 degrees strike)
    for (int angle = 0; angle < 360; angle += 30) {
      final radians = angle * math.pi / 180;
      final x = center.dx + radius * math.cos(radians);
      final y = center.dy + radius * math.sin(radians);
      canvas.drawLine(center, Offset(x, y), gridPaint);
    }
  }

  void _drawCardinalDirections(Canvas canvas, Offset center, double radius) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final directions = {
      0: 'N',
      90: 'E',
      180: 'S',
      270: 'W',
    };

    directions.forEach((angle, label) {
      final radians = (angle - 90) * math.pi / 180; // Adjust for North at top
      final x = center.dx + (radius + 20) * math.cos(radians);
      final y = center.dy + (radius + 20) * math.sin(radians);

      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    });
  }

  void _plotPole(Canvas canvas, Offset center, double radius, int dip,
      int strike, Color color) {
    // Convert dip and strike to stereonet coordinates
    // Using lower hemisphere equal-area projection
    final dipRad = dip * math.pi / 180;
    final strikeRad = strike * math.pi / 180;

    // Calculate pole projection
    final r = radius * math.sqrt(2) * math.sin((90 - dip) * math.pi / 360);
    final x = center.dx + r * math.sin(strikeRad);
    final y =
        center.dy - r * math.cos(strikeRad); // Negative for correct orientation

    // Draw pole point
    final polePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, y), 4, polePaint);

    // Draw outline
    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(Offset(x, y), 4, outlinePaint);
  }

  void _plotPlane(Canvas canvas, Offset center, double radius, int dip,
      int strike, Color color) {
    // Draw great circle for plane
    // This is a simplified representation
    final planePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final strikeRad = strike * math.pi / 180;

    // Draw an arc representing the plane
    // Simplified: draw a curved line through the stereonet
    final path = Path();
    bool first = true;

    for (double angle = -90; angle <= 90; angle += 5) {
      final angleRad = angle * math.pi / 180;
      final dipRad = dip * math.pi / 180;

      // Calculate point on great circle
      final r =
          radius * math.sin(math.acos(math.cos(angleRad) * math.cos(dipRad)));
      final theta =
          strikeRad + math.atan2(math.sin(angleRad), math.tan(dipRad));

      final x = center.dx + r * math.sin(theta);
      final y = center.dy - r * math.cos(theta);

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, planePaint);
  }

  Color _getColorForRockType(String rockType) {
    switch (rockType.toLowerCase()) {
      case 'igneous':
        return AppColors.igneous;
      case 'sedimentary':
        return AppColors.sedimentary;
      case 'metamorphic':
        return AppColors.metamorphic;
      default:
        return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(StereonetPainter oldDelegate) {
    return oldDelegate.records != records ||
        oldDelegate.showPoles != showPoles ||
        oldDelegate.showPlanes != showPlanes;
  }
}
