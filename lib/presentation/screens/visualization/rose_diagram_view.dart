import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../data/models/field_record.dart';
import '../../../core/constants/colors.dart';

/// Widget to display rose diagram of strike orientations
class RoseDiagramView extends StatefulWidget {
  final List<FieldRecord> records;

  const RoseDiagramView({super.key, required this.records});

  @override
  State<RoseDiagramView> createState() => _RoseDiagramViewState();
}

class _RoseDiagramViewState extends State<RoseDiagramView> {
  int _binSize = 10; // Degrees per bin
  bool _showByRockType = false;

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
                Row(
                  children: [
                    const Text('Bin Size: '),
                    const SizedBox(width: 16),
                    DropdownButton<int>(
                      value: _binSize,
                      items: [5, 10, 15, 20, 30].map((size) {
                        return DropdownMenuItem(
                          value: size,
                          child: Text('$size°'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _binSize = value);
                        }
                      },
                    ),
                  ],
                ),
                SwitchListTile(
                  title: const Text('Color by Rock Type'),
                  subtitle: const Text('Show different rock types in colors'),
                  value: _showByRockType,
                  onChanged: (value) => setState(() => _showByRockType = value),
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

        // Rose diagram display
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: CustomPaint(
                  painter: RoseDiagramPainter(
                    records: widget.records,
                    binSize: _binSize,
                    showByRockType: _showByRockType,
                  ),
                  child: Container(),
                ),
              ),
            ),
          ),
        ),

        // Statistics
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _buildStatistics(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    if (widget.records.isEmpty) {
      return const Text('No data available');
    }

    // Calculate mean strike
    double sumX = 0, sumY = 0;
    for (final record in widget.records) {
      if (record.strike != null) {
        final radians = record.strike! * math.pi / 180;
        sumX += math.cos(radians);
        sumY += math.sin(radians);
      }
    }

    final meanRadians = math.atan2(sumY, sumX);
    final meanStrike = ((meanRadians * 180 / math.pi) + 360) % 360;

    // Calculate vector magnitude (concentration)
    final vectorLength =
        math.sqrt(sumX * sumX + sumY * sumY) / widget.records.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatRow(
            'Mean Strike Direction', '${meanStrike.toStringAsFixed(1)}°'),
        _buildStatRow('Vector Magnitude', vectorLength.toStringAsFixed(3)),
        _buildStatRow('Bin Size', '$_binSize°'),
        _buildStatRow('Number of Bins', '${360 ~/ _binSize}'),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

/// Custom painter for rose diagram
class RoseDiagramPainter extends CustomPainter {
  final List<FieldRecord> records;
  final int binSize;
  final bool showByRockType;

  RoseDiagramPainter({
    required this.records,
    required this.binSize,
    required this.showByRockType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Calculate bin counts
    final numBins = 360 ~/ binSize;
    final Map<int, Map<String, int>> bins = {};

    for (int i = 0; i < numBins; i++) {
      bins[i] = {'igneous': 0, 'sedimentary': 0, 'metamorphic': 0, 'other': 0};
    }

    // Fill bins
    int maxCount = 0;
    for (final record in records) {
      if (record.strike != null) {
        final binIndex = (record.strike! ~/ binSize) % numBins;
        final rockType = record.rockType.toLowerCase();

        if (bins[binIndex]!.containsKey(rockType)) {
          bins[binIndex]![rockType] = bins[binIndex]![rockType]! + 1;
        } else {
          bins[binIndex]!['other'] = bins[binIndex]!['other']! + 1;
        }

        final binTotal = bins[binIndex]!.values.reduce((a, b) => a + b);
        if (binTotal > maxCount) maxCount = binTotal;
      }
    }

    if (maxCount == 0) return;

    // Draw grid circles
    _drawGrid(canvas, center, maxRadius, maxCount);

    // Draw cardinal directions
    _drawCardinalDirections(canvas, center, maxRadius);

    // Draw petals
    for (int i = 0; i < numBins; i++) {
      final binCounts = bins[i]!;
      final totalCount = binCounts.values.reduce((a, b) => a + b);

      if (totalCount > 0) {
        final startAngle =
            (i * binSize - 90) * math.pi / 180; // -90 to start from North
        final sweepAngle = binSize * math.pi / 180;
        final petalRadius = maxRadius * (totalCount / maxCount);

        if (showByRockType) {
          _drawStackedPetal(canvas, center, startAngle, sweepAngle, petalRadius,
              binCounts, totalCount);
        } else {
          _drawSinglePetal(canvas, center, startAngle, sweepAngle, petalRadius);
        }
      }
    }

    // Draw center circle
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3, centerPaint);

    final centerOutline = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 3, centerOutline);
  }

  void _drawGrid(Canvas canvas, Offset center, double radius, int maxCount) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw concentric circles
    for (int i = 1; i <= 4; i++) {
      final r = radius * (i / 4.0);
      canvas.drawCircle(center, r, gridPaint);
    }

    // Draw radial lines (every 30 degrees)
    for (int angle = 0; angle < 360; angle += 30) {
      final radians = (angle - 90) * math.pi / 180;
      final x = center.dx + radius * math.cos(radians);
      final y = center.dy + radius * math.sin(radians);
      canvas.drawLine(center, Offset(x, y), gridPaint);
    }

    // Draw scale labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 1; i <= 4; i++) {
      final count = (maxCount * i / 4).round();
      final r = radius * (i / 4.0);

      textPainter.text = TextSpan(
        text: count.toString(),
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(center.dx + 5, center.dy - r - textPainter.height / 2),
      );
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
      final radians = (angle - 90) * math.pi / 180;
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

  void _drawSinglePetal(Canvas canvas, Offset center, double startAngle,
      double sweepAngle, double radius) {
    final petalPaint = Paint()
      ..color = AppColors.primaryGreen.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final petalOutline = Paint()
      ..color = AppColors.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
    );
    path.close();

    canvas.drawPath(path, petalPaint);
    canvas.drawPath(path, petalOutline);
  }

  void _drawStackedPetal(Canvas canvas, Offset center, double startAngle,
      double sweepAngle, double radius, Map<String, int> counts, int total) {
    final rockTypes = ['igneous', 'sedimentary', 'metamorphic', 'other'];
    double currentRadius = 0;

    for (final rockType in rockTypes) {
      final count = counts[rockType] ?? 0;
      if (count > 0) {
        final proportion = count / total;
        final segmentRadius = currentRadius + (radius * proportion);

        final color = _getColorForRockType(rockType);

        final petalPaint = Paint()
          ..color = color.withOpacity(0.7)
          ..style = PaintingStyle.fill;

        final petalOutline = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

        final path = Path();
        path.moveTo(center.dx, center.dy);
        path.arcTo(
          Rect.fromCircle(center: center, radius: segmentRadius),
          startAngle,
          sweepAngle,
          false,
        );
        path.close();

        canvas.drawPath(path, petalPaint);
        canvas.drawPath(path, petalOutline);

        currentRadius = segmentRadius;
      }
    }
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
  bool shouldRepaint(RoseDiagramPainter oldDelegate) {
    return oldDelegate.records != records ||
        oldDelegate.binSize != binSize ||
        oldDelegate.showByRockType != showByRockType;
  }
}
