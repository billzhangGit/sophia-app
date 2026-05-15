import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/stock_models.dart';
import 'app_theme.dart';

/// K线蜡烛图，使用 CustomPaint 绘制
/// - OHLC 蜡烛（红涨绿跌）
/// - 可选 MA5/MA10/MA20 均线
/// - 底部 20% 高度成交量柱
/// - X 轴时间标签（跳点显示）
/// - Y 轴价格标签
class KlineChart extends StatelessWidget {
  final List<KlinePoint> klineData;
  final List<double>? ma5;
  final List<double>? ma10;
  final List<double>? ma20;
  final double height;

  const KlineChart({
    super.key,
    required this.klineData,
    this.ma5,
    this.ma10,
    this.ma20,
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    if (klineData.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('暂无K线数据', style: TextStyle(color: AppTheme.textDim)),
        ),
      );
    }
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _KlinePainter(
          klineData: klineData,
          ma5: ma5,
          ma10: ma10,
          ma20: ma20,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _KlinePainter extends CustomPainter {
  final List<KlinePoint> klineData;
  final List<double>? ma5;
  final List<double>? ma10;
  final List<double>? ma20;

  _KlinePainter({
    required this.klineData,
    this.ma5,
    this.ma10,
    this.ma20,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (klineData.isEmpty) return;

    // ---- 计算边界 ----
    final double leftMargin = 50;
    final double rightMargin = 10;
    final double topMargin = 8;
    final double bottomMargin = 40;
    final double volumeRatio = 0.2; // 成交量区域占总绘图区的 20%

    final double plotWidth = size.width - leftMargin - rightMargin;
    final double plotHeight = size.height - topMargin - bottomMargin;
    final double priceAreaHeight = plotHeight * (1 - volumeRatio);
    final double volumeAreaTop = topMargin + priceAreaHeight;
    final double volumeAreaHeight = plotHeight * volumeRatio;

    // ---- 价格范围 ----
    double minPrice = double.infinity;
    double maxPrice = double.negativeInfinity;
    double maxVolume = 0;
    for (final k in klineData) {
      if (k.low < minPrice) minPrice = k.low;
      if (k.high > maxPrice) maxPrice = k.high;
      if (k.volume > maxVolume) maxVolume = k.volume;
    }
    if (minPrice == double.infinity) return;
    final double priceRange = maxPrice - minPrice;
    final double pricePadding = priceRange * 0.05;
    minPrice -= pricePadding;
    maxPrice += pricePadding;
    final double adjustedRange = maxPrice - minPrice;

    // ---- 工具函数 ----
    double priceToY(double p) {
      return topMargin +
          priceAreaHeight * (1 - (p - minPrice) / adjustedRange);
    }

    double volumeToY(double v) {
      return volumeAreaTop +
          volumeAreaHeight * (1 - v / (maxVolume > 0 ? maxVolume : 1));
    }

    double indexToX(int i) {
      return leftMargin + (i / math.max(klineData.length - 1, 1)) * plotWidth;
    }

    // ---- 网格 ----
    final gridPaint = Paint()
      ..color = AppTheme.textMuted.withOpacity(0.1)
      ..strokeWidth = 0.5;
    final int gridLines = 5;
    for (int i = 0; i <= gridLines; i++) {
      final double y =
          topMargin + (priceAreaHeight / gridLines) * i;
      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(size.width - rightMargin, y),
        gridPaint,
      );
    }

    // ---- 成交量柱 ----
    for (int i = 0; i < klineData.length; i++) {
      final k = klineData[i];
      final double x = indexToX(i);
      final double candleWidth = plotWidth / klineData.length * 0.6;
      final double halfCandle = candleWidth / 2;

      final Paint volPaint = Paint()
        ..color = (k.isUp ? AppTheme.up : AppTheme.down).withOpacity(0.3);
      final double volY = volumeToY(k.volume);
      canvas.drawRect(
        Rect.fromLTRB(x - halfCandle, volY, x + halfCandle, volumeAreaTop + volumeAreaHeight),
        volPaint,
      );
    }

    // ---- 蜡烛 ----
    for (int i = 0; i < klineData.length; i++) {
      final k = klineData[i];
      final double x = indexToX(i);
      final double candleWidth = plotWidth / klineData.length * 0.6;
      final double halfCandle = candleWidth / 2;

      final Paint candlePaint = Paint()
        ..color = k.isUp ? AppTheme.up : AppTheme.down
        ..strokeWidth = 1.5;

      // 影线 (high-low)
      canvas.drawLine(
        Offset(x, priceToY(k.high)),
        Offset(x, priceToY(k.low)),
        candlePaint,
      );

      // 实体 (open-close)
      final double openY = priceToY(k.open);
      final double closeY = priceToY(k.close);
      final double bodyTop = math.min(openY, closeY);
      final double bodyBottom = math.max(openY, closeY);
      final double bodyHeight = math.max(bodyBottom - bodyTop, 1.0);

      final Paint bodyPaint = Paint()..color = candlePaint.color;
      canvas.drawRect(
        Rect.fromLTRB(x - halfCandle, bodyTop, x + halfCandle, bodyTop + bodyHeight),
        bodyPaint,
      );
    }

    // ---- 均线 ----
    void drawMaLine(List<double>? values, Color color) {
      if (values == null || values.isEmpty) return;
      final paint = Paint()
        ..color = color
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      final path = Path();
      bool started = false;
      for (int i = 0; i < values.length && i < klineData.length; i++) {
        final v = values[i];
        if (v.isNaN || v.isInfinite) continue;
        final double x = indexToX(i);
        final double y = priceToY(v);
        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
      }
      if (started) canvas.drawPath(path, paint);
    }

    drawMaLine(ma5, AppTheme.warning); // 黄色
    drawMaLine(ma10, AppTheme.info); // 蓝色
    drawMaLine(ma20, AppTheme.purple); // 紫色

    // ---- Y轴价格标签 ----
    final textStyle = TextStyle(
      color: AppTheme.textDim,
      fontSize: 10,
    );
    for (int i = 0; i <= gridLines; i++) {
      final double y = topMargin + (priceAreaHeight / gridLines) * i;
      final double price = maxPrice - (adjustedRange / gridLines) * i;
      final tp = TextPainter(
        text: TextSpan(
          text: price.toStringAsFixed(2),
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout(maxWidth: leftMargin - 4);
      tp.paint(canvas, Offset(leftMargin - tp.width - 2, y - tp.height / 2));
    }

    // ---- X轴时间标签 ----
    final int skip = math.max(1, klineData.length ~/ 6);
    for (int i = 0; i < klineData.length; i += skip) {
      final String date = klineData[i].date;
      final String label = date.length >= 10 ? date.substring(5, 10) : date;
      final double x = indexToX(i);
      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      );
      tp.layout(maxWidth: 50);
      tp.paint(
        canvas,
        Offset(x - tp.width / 2, size.height - bottomMargin + 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _KlinePainter oldDelegate) {
    return oldDelegate.klineData != klineData ||
        oldDelegate.ma5 != ma5 ||
        oldDelegate.ma10 != ma10 ||
        oldDelegate.ma20 != ma20;
  }
}
