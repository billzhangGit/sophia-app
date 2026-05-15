import 'package:flutter/material.dart';
import '../models/stock_models.dart';
import 'app_theme.dart';

/// 卖出策略列表卡片
/// - 每条：条件(左) | 操作(右)
/// - 红色行为金融学提醒（如有）
class SellStrategyCard extends StatelessWidget {
  final List<SellStrategy> strategies;

  const SellStrategyCard({
    super.key,
    required this.strategies,
  });

  @override
  Widget build(BuildContext context) {
    if (strategies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Text(
              '卖出策略',
              style: TextStyle(
                color: AppTheme.text,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...strategies.map((s) => _buildStrategyItem(s)),
        ],
      ),
    );
  }

  Widget _buildStrategyItem(SellStrategy s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.textMuted.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 条件 — 左侧
              Expanded(
                flex: 3,
                child: Text(
                  s.condition,
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontSize: 13,
                  ),
                ),
              ),
              // 操作 — 右侧
              Expanded(
                flex: 2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.up.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    s.action,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.up,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // 行为金融学提醒
          if (s.psychological != null && s.psychological!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠ ',
                  style: TextStyle(color: AppTheme.up, fontSize: 12),
                ),
                Expanded(
                  child: Text(
                    s.psychological!,
                    style: const TextStyle(
                      color: AppTheme.up,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
