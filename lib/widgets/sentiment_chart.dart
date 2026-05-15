import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/stock_models.dart';
import 'app_theme.dart';

/// 30天情绪指数走势图（折线图）
/// - 填充渐变 (暗红→红)
/// - X 轴短日期
/// - Y 轴 0~10
/// - 高度 160
class SentimentChart extends StatelessWidget {
  final List<SentimentHistoryPoint> history;

  const SentimentChart({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: Text('暂无情绪数据', style: TextStyle(color: AppTheme.textDim)),
        ),
      );
    }

    // 逆序（最旧 → 最新）
    final sorted = List<SentimentHistoryPoint>.from(history)
      ..sort((a, b) => a.date.compareTo(b.date));

    final spots = <FlSpot>[];
    int idx = 0;
    for (final h in sorted) {
      spots.add(FlSpot(idx.toDouble(), math.min(math.max(h.score, 0), 10)));
      idx++;
    }

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: 0,
          maxY: 10,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppTheme.textMuted.withOpacity(0.15),
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 2,
                getTitlesWidget: (value, _) {
                  if (value == 0 || value == 10) return const SizedBox.shrink();
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: AppTheme.textDim,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: math.max(1, (spots.length / 6).ceilToDouble()),
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= sorted.length) {
                    return const SizedBox.shrink();
                  }
                  final date = sorted[i].date;
                  String label;
                  try {
                    final dt = DateFormat('yyyy-MM-dd').parse(date);
                    label = DateFormat('MM/dd').format(dt);
                  } catch (_) {
                    label = date.length >= 5 ? date.substring(5) : date;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppTheme.textDim,
                        fontSize: 9,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: AppTheme.up,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.up.withOpacity(0.35),
                    AppTheme.up.withOpacity(0.02),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final i = spot.spotIndex;
                  String date = '';
                  if (i >= 0 && i < sorted.length) {
                    date = sorted[i].date;
                  }
                  return LineTooltipItem(
                    '$date\n评分: ${spot.y.toStringAsFixed(1)}',
                    const TextStyle(
                      color: AppTheme.text,
                      fontSize: 11,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
