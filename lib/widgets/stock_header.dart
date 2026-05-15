import 'package:flutter/material.dart';
import 'app_theme.dart';

/// 股票名称/代码 + 价格 + 涨跌幅
class StockHeader extends StatelessWidget {
  final String symbol;
  final String name;
  final double price;
  final double changePct;

  const StockHeader({
    super.key,
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePct,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUp = changePct >= 0;
    final Color priceColor = isUp ? AppTheme.up : AppTheme.down;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 名称 + 代码
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: AppTheme.text,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              symbol,
              style: const TextStyle(
                color: AppTheme.textDim,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const Spacer(),
        // 价格 + 涨跌幅
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              price.toStringAsFixed(2),
              style: TextStyle(
                color: priceColor,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: priceColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: priceColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
