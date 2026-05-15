import 'package:flutter/material.dart';
import 'app_theme.dart';

/// 10维度因子详情 — 可展开面板 / 底部弹出
/// - 2列网格展示 10 个因子
/// - 颜色: >=0.7 红, 0.4~0.7 黄, <0.4 绿
/// - 底部显示修正因子
class FactorDetailSheet extends StatelessWidget {
  final Map<String, dynamic> details;

  const FactorDetailSheet({
    super.key,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    // 提取数值因子 & 修正因子
    final numericFactors = <MapEntry<String, double>>[];
    String? correctionInfo;

    for (final entry in details.entries) {
      final k = entry.key;
      final v = entry.value;
      if (k == 'correction' || k == 'correction_info' || k == 'note') {
        correctionInfo = v?.toString();
        continue;
      }
      if (v is num) {
        numericFactors.add(MapEntry(k, v.toDouble()));
      }
    }

    // 最多取前 10 个数值因子
    final factors = numericFactors.take(10).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 拖拽条
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '10维度因子',
            style: TextStyle(
              color: AppTheme.text,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // 因子网格
          if (factors.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  '暂无因子数据',
                  style: TextStyle(color: AppTheme.textDim),
                ),
              ),
            )
          else
            _buildFactorGrid(factors),
          // 修正因子
          if (correctionInfo != null && correctionInfo.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.cardAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.info.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      color: AppTheme.info, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      correctionInfo,
                      style: const TextStyle(
                        color: AppTheme.textDim,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFactorGrid(List<MapEntry<String, double>> factors) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: factors.length,
      itemBuilder: (_, index) {
        final f = factors[index];
        final Color color = _factorColor(f.value);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppTheme.cardAlt,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _factorLabel(f.key),
                style: const TextStyle(
                  color: AppTheme.textDim,
                  fontSize: 12,
                ),
              ),
              Text(
                f.value.toStringAsFixed(2),
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Color _factorColor(double value) {
    if (value >= 0.7) return AppTheme.up;
    if (value >= 0.4) return AppTheme.warning;
    return AppTheme.down;
  }

  static String _factorLabel(String key) {
    // 将驼峰/下划线转为中文友好标签
    const labelMap = {
      'score': '综合评分',
      'strength': '强度',
      'momentum': '动量',
      'volume_ratio': '量比',
      'concept_heat': '题材热度',
      'capital_flow': '资金流向',
      'fundamental': '基本面',
      'technical': '技术面',
      'sentiment': '情绪面',
      'market_cap': '市值',
      'turnover': '换手率',
      'liquidity': '流动性',
      'volatility': '波动率',
      'trend': '趋势',
      'risk': '风险',
    };
    return labelMap[key] ?? key;
  }
}
