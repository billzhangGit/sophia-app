import 'package:flutter/material.dart';
import 'app_theme.dart';

/// 回测表现指标卡片
/// - Sharpe、胜率、年化收益、最大回撤、vs 基准
/// - 每个指标在小卡片中展示，带颜色编码
class StrategyPerfCard extends StatelessWidget {
  final double? sharpe;
  final double? winRate;
  final double? annualReturn;
  final double? maxDrawdown;
  final double? vsBenchmark;

  const StrategyPerfCard({
    super.key,
    this.sharpe,
    this.winRate,
    this.annualReturn,
    this.maxDrawdown,
    this.vsBenchmark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '回测表现',
            style: TextStyle(
              color: AppTheme.text,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetric('Sharpe', sharpe, _sharpeColor)),
              const SizedBox(width: 8),
              Expanded(
                  child:
                      _buildMetric('胜率', winRate, _winRateColor, suffix: '%')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildMetric('年化收益', annualReturn, _returnColor,
                      suffix: '%')),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildMetric('最大回撤', maxDrawdown, _drawdownColor,
                      suffix: '%')),
            ],
          ),
          if (vsBenchmark != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetric('vs 基准', vsBenchmark, _vsBenchColor,
                      suffix: '%'),
                ),
                const SizedBox(width: 8),
                Expanded(child: Container()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetric(
    String label,
    double? value,
    Color Function(double v) colorFn, {
    String suffix = '',
  }) {
    final displayVal = value?.toStringAsFixed(2) ?? '--';
    final Color color =
        value != null ? colorFn(value) : AppTheme.textDim;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardAlt,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$displayVal$suffix',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ---- 颜色逻辑 ----

  Color _sharpeColor(double v) {
    if (v >= 1.5) return AppTheme.down;
    if (v >= 0.5) return AppTheme.warning;
    return AppTheme.up;
  }

  Color _winRateColor(double v) {
    if (v >= 60) return AppTheme.down;
    if (v >= 40) return AppTheme.warning;
    return AppTheme.up;
  }

  Color _returnColor(double v) {
    if (v >= 15) return AppTheme.down;
    if (v >= 0) return AppTheme.warning;
    return AppTheme.up;
  }

  Color _drawdownColor(double v) {
    // 回撤越小越好（负值越小越差）
    if (v >= -5) return AppTheme.down;
    if (v >= -15) return AppTheme.warning;
    return AppTheme.up;
  }

  Color _vsBenchColor(double v) {
    if (v >= 5) return AppTheme.down;
    if (v >= 0) return AppTheme.warning;
    return AppTheme.up;
  }
}
