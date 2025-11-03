import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PriceChartWidget extends StatelessWidget {
  final List<FlSpot> priceData;
  final bool showDetailedTooltip;

  const PriceChartWidget({
    super.key,
    required this.priceData,
    this.showDetailedTooltip = false,
  });

  double get minY => priceData.isEmpty
      ? 0
      : priceData.map((e) => e.y).reduce((a, b) => a < b ? a : b);

  double get maxY => priceData.isEmpty
      ? 0
      : priceData.map((e) => e.y).reduce((a, b) => a > b ? a : b);

  @override
  Widget build(BuildContext context) {
    if (priceData.isEmpty) {
      return const SizedBox.shrink();
    }

    return AspectRatio(
      aspectRatio: 1.70,
      child: Padding(
        padding: const EdgeInsets.only(
          right: 18,
          left: 12,
          top: 24,
          bottom: 12,
        ),
        child: LineChart(
          LineChartData(
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: const Color(0xFF2C2C54).withOpacity(0.8),
                tooltipRoundedRadius: 8,
                tooltipPadding: const EdgeInsets.all(12),
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                  return touchedBarSpots.map((barSpot) {
                    return LineTooltipItem(
                      '\$${barSpot.y.toStringAsFixed(8)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: '\n${_formatTime(barSpot.x.toInt())}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  }).toList();
                },
              ),
              touchSpotThreshold: 20,
              handleBuiltInTouches: true,
              getTouchLineStart: (data, index) => 0,
              getTouchLineEnd: (data, index) => double.infinity,
              getTouchedSpotIndicator:
                  (LineChartBarData barData, List<int> spotIndexes) {
                    return spotIndexes.map((spotIndex) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: const Color(0xFF4A63E7).withOpacity(0.2),
                          strokeWidth: 2,
                          dashArray: [3, 3],
                        ),
                        FlDotData(
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 6,
                              color: const Color(0xFF4A63E7),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                      );
                    }).toList();
                  },
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: (maxY - minY) / 6,
              verticalInterval: priceData.length / 6,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: const Color(0xFF37375F).withOpacity(0.15),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: const Color(0xFF37375F).withOpacity(0.15),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: priceData.length / 6,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= priceData.length ||
                        value.toInt() < 0) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _formatTime(value.toInt()),
                        style: TextStyle(
                          color: const Color(0xFF8E8EA9).withOpacity(0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: (maxY - minY) / 6,
                  reservedSize: 46,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toStringAsFixed(8),
                      style: TextStyle(
                        color: const Color(0xFF8E8EA9).withOpacity(0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: priceData.length.toDouble() - 1,
            minY: minY * 0.9999,
            maxY: maxY * 1.0001,
            lineBarsData: [
              LineChartBarData(
                spots: priceData,
                isCurved: true,
                curveSmoothness: 0.35,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A1A1A), Color(0xFF4B5563)],
                ),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF4A63E7).withOpacity(0.2),
                      const Color(0xFF4A63E7).withOpacity(0.05),
                      const Color(0xFF4A63E7).withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        ),
      ),
    );
  }

  String _formatTime(int index) {
    if (priceData.isEmpty || index >= priceData.length) return '';
    final now = DateTime.now();
    final hour = now.hour - (priceData.length - 1 - index) ~/ 60;
    final minute = now.minute - (priceData.length - 1 - index) % 60;
    final time = DateTime(now.year, now.month, now.day, hour, minute);
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
