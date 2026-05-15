import 'package:flutter/material.dart';
import '../models/stock_models.dart';
import 'app_theme.dart';

/// 单个买入方案卡片
/// - 左侧颜色条：激进=红, 中庸=黄, 保守=蓝
/// - 标题 + 推荐标记
/// - 入场价、止损、止盈、持仓天数
/// - 分析逻辑文字
class BuyPlanCard extends StatelessWidget {
  final BuyPlan plan;

  const BuyPlanCard({
    super.key,
    required this.plan,
  });

  Color get _leftBorderColor {
    switch (plan.title) {
      case '激进':
        return AppTheme.up; // 红
      case '中庸':
        return AppTheme.warning; // 黄
      case '保守':
        return AppTheme.info; // 蓝
      default:
        return AppTheme.textDim;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardAlt,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 左侧色条
            Container(
              width: 4,
              color: _leftBorderColor,
            ),
            // 内容
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题行
                    Row(
                      children: [
                        Text(
                          plan.title,
                          style: const TextStyle(
                            color: AppTheme.text,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (plan.recommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.down.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              '推荐',
                              style: TextStyle(
                                color: AppTheme.down,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    // 价格行
                    Row(
                      children: [
                        _priceLabel('入场', plan.entry),
                        const SizedBox(width: 16),
                        _priceLabel('止损', plan.stopLoss, color: AppTheme.up),
                        const SizedBox(width: 16),
                        _priceLabel('止盈', plan.takeProfit, color: AppTheme.down),
                        const Spacer(),
                        _priceLabel('持仓', '${plan.holdingDays}天'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // 推理
                    Text(
                      plan.reasoning,
                      style: const TextStyle(
                        color: AppTheme.textDim,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceLabel(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color ?? AppTheme.text,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
