import 'package:flutter/material.dart';
import '../models/stock_models.dart';
import 'app_theme.dart';

/// 五维度评分网格
/// 技术面 25% | 情绪面 20% | 题材面 20% | 资金面 20% | 基本面 15%
/// 每项显示：标签、评分(1-10)、权重条
/// 底部总分 + 评级
/// - >=7 绿色, 5-6 黄色, <5 红色
class FiveDimGrid extends StatelessWidget {
  final FiveDimScore score;

  const FiveDimGrid({
    super.key,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _DimItem('技术面', score.technical, 0.25),
      _DimItem('情绪面', score.sentiment, 0.20),
      _DimItem('题材面', score.concept, 0.20),
      _DimItem('资金面', score.capital, 0.20),
      _DimItem('基本面', score.fundamental, 0.15),
    ];

    final Color totalColor = _fiveDimColor(score.total);

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
            '五维评分',
            style: TextStyle(
              color: AppTheme.text,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // 维度行
          for (final item in items) ...[
            _buildDimRow(item),
            const SizedBox(height: 10),
          ],
          const Divider(color: AppTheme.textMuted, height: 20),
          // 总分
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '总分',
                style: TextStyle(
                  color: AppTheme.text,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Text(
                    score.total.toStringAsFixed(1),
                    style: TextStyle(
                      color: totalColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: totalColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      score.rating,
                      style: TextStyle(
                        color: totalColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDimRow(_DimItem item) {
    final Color color = _fiveDimColor(item.score);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              item.label,
              style: const TextStyle(
                color: AppTheme.textDim,
                fontSize: 13,
              ),
            ),
            Row(
              children: [
                Text(
                  item.score.toStringAsFixed(1),
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${(item.weight * 100).toInt()}%)',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: item.score / 10,
            backgroundColor: AppTheme.cardAlt,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  static Color _fiveDimColor(double s) {
    if (s >= 7) return AppTheme.down; // green
    if (s >= 5) return AppTheme.warning; // yellow
    return AppTheme.up; // red
  }
}

class _DimItem {
  final String label;
  final double score;
  final double weight;
  const _DimItem(this.label, this.score, this.weight);
}
