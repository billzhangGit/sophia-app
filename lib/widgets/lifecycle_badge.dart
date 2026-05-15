import 'package:flutter/material.dart';
import 'app_theme.dart';

/// 生命周期定位小徽章 — 显示 Emoji + 阶段名称
///
/// 传入 phase 字符串，自动匹配 Emoji 和颜色
class LifecycleBadge extends StatelessWidget {
  final String phase;
  final String? detail;

  const LifecycleBadge({
    super.key,
    required this.phase,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final String emoji = _phaseEmoji(phase);
    final Color color = AppTheme.lifecycleColor(phase);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            phase,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (detail != null && detail!.isNotEmpty && detail != '--') ...[
            const SizedBox(width: 6),
            Text(
              detail!,
              style: const TextStyle(
                color: AppTheme.textDim,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _phaseEmoji(String phase) {
    switch (phase) {
      case '建仓区':
        return '📥';
      case '主升区':
        return '📈';
      case '出货区':
        return '📤';
      case '下跌区':
        return '📉';
      default:
        return '⚖️';
    }
  }
}
