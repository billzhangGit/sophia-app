/// Sophia APP 主题常量 — 暗色主题统一配色
/// 对应网页看板样式：--bg:#0e1117 --card:#1a1d23 --text:#fafafa

import 'package:flutter/material.dart';

class AppTheme {
  // 背景色
  static const Color bg = Color(0xFF0E1117);
  static const Color card = Color(0xFF1A1D23);
  static const Color cardAlt = Color(0xFF242830);

  // 文字色
  static const Color text = Color(0xFFFAFAFA);
  static const Color textDim = Color(0xFF95A5A6);
  static const Color textMuted = Color(0xFF666666);

  // 涨跌色（A股：红涨绿跌）
  static const Color up = Color(0xFFE74C3C);
  static const Color down = Color(0xFF2ECC71);
  static const Color limitUp = Color(0xFFFF6B6B);
  static const Color limitDown = Color(0xFF00B894);

  // 警示色
  static const Color warning = Color(0xFFF1C40F);
  static const Color info = Color(0xFF3498DB);
  static const Color purple = Color(0xFF9B59B6);

  // 情绪阶段色
  static const Color phaseIce = Color(0xFF2ECC71);
  static const Color phaseRecover = Color(0xFF3498DB);
  static const Color phaseBalance = Color(0xFFF1C40F);
  static const Color phaseBoom = Color(0xFFE74C3C);
  static const Color phaseBoiling = Color(0xFF9B59B6);
  static const Color phaseEbb = Color(0xFF95A5A6);

  static Color phaseColor(String phase) {
    switch (phase) {
      case '冰点期': return phaseIce;
      case '复苏期': return phaseRecover;
      case '均衡期': return phaseBalance;
      case '高潮期': return phaseBoom;
      case '沸腾期': return phaseBoiling;
      case '退潮期': return phaseEbb;
      default: return textDim;
    }
  }

  static String phaseEmoji(String phase) {
    switch (phase) {
      case '冰点期': return '🧊';
      case '复苏期': return '🌱';
      case '均衡期': return '⚖️';
      case '高潮期': return '🔥';
      case '沸腾期': return '💥';
      case '退潮期': return '🌧️';
      default: return '❓';
    }
  }

  // 评分色
  static Color scoreColor(double score) {
    if (score >= 7) return up;
    if (score >= 4) return warning;
    return down;
  }

  // 推荐评级色
  static Color recColor(String rec) {
    switch (rec) {
      case '强烈推荐': return down;
      case '谨慎观察': return warning;
      default: return up;
    }
  }

  // 生命周期色
  static Color lifecycleColor(String phase) {
    switch (phase) {
      case '建仓区': return info;
      case '主升区': return up;
      case '出货区': return purple;
      case '下跌区': return down;
      default: return textDim;
    }
  }

  // ThemeData
  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    cardColor: card,
    colorScheme: const ColorScheme.dark(
      primary: up,
      secondary: up,
      surface: card,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: text),
      titleMedium: TextStyle(color: text, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 18),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: card,
      foregroundColor: text,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: textMuted),
    ),
    dividerColor: textMuted.withOpacity(0.2),
  );

  // 便捷间距常量
  static const double padSmall = 8.0;
  static const double pad = 12.0;
  static const double padLarge = 16.0;

  // 圆角
  static const double radiusSmall = 6.0;
  static const double radius = 8.0;
  static const double radiusLarge = 12.0;
}
