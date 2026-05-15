import 'package:flutter/material.dart';
import 'app_theme.dart';

/// 推荐评级徽章 — 带颜色边框和文字
/// - 强烈推荐: 绿色
/// - 谨慎观察: 黄色
/// - 不推荐买: 红色半透明
class RatingBadge extends StatelessWidget {
  final String rating;

  const RatingBadge({
    super.key,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final double opacity;

    switch (rating) {
      case '强烈推荐':
        color = AppTheme.down;
        opacity = 1.0;
        break;
      case '谨慎观察':
        color = AppTheme.warning;
        opacity = 1.0;
        break;
      default: // 不推荐买
        color = AppTheme.up;
        opacity = 0.5;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(opacity)),
        borderRadius: BorderRadius.circular(4),
        color: color.withOpacity(opacity * 0.1),
      ),
      child: Text(
        rating,
        style: TextStyle(
          color: color.withOpacity(opacity),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
