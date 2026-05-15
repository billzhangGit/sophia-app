import 'package:flutter/material.dart';
import 'app_theme.dart';

/// 圆形评分徽章，根据分值自动着色
/// >=7 红, >=4 黄, <4 绿
class ScoreBadge extends StatelessWidget {
  final double score;
  final double size;

  const ScoreBadge({
    super.key,
    required this.score,
    this.size = 32,
  });

  double get _fontSize {
    if (size <= 24) return 11;
    if (size <= 28) return 13;
    return 15;
  }

  @override
  Widget build(BuildContext context) {
    final Color color = _scoreColor(score);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        score.toStringAsFixed(1),
        style: TextStyle(
          color: color,
          fontSize: _fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static Color _scoreColor(double s) {
    if (s >= 7) return AppTheme.up;
    if (s >= 4) return AppTheme.warning;
    return AppTheme.down;
  }
}
