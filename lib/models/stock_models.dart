/// Sophia APP 数据模型 — 覆盖复盘/龙头选股/买卖决策全部数据结构
/// 统一类型安全，不再用 raw Map<String, dynamic>

// ============================================================
// 复盘 — 市场总览
// ============================================================

class MarketOverview {
  final Map<String, IndexData> indexes;
  final MarketStats stats;
  final SentimentData sentiment;
  final List<LimitUpStock> topLimitUp;
  final SignalSummary? signal;

  MarketOverview.from(Map<String, dynamic> data)
      : indexes = _parseIndexes(data['indexes']),
        stats = MarketStats.from(data['stats'] ?? {}),
        sentiment = SentimentData.from(data['sentiment'] ?? {}),
        topLimitUp = (data['top_limitup'] as List<dynamic>?)
                ?.map((e) => LimitUpStock.from(e))
                .toList() ??
            [],
        signal = data['signal'] != null
            ? SignalSummary.from(data['signal'])
            : null;

  static Map<String, IndexData> _parseIndexes(dynamic data) {
    final map = <String, IndexData>{};
    if (data is Map) {
      for (final key in ['sh', 'sz', 'cy']) {
        if (data[key] != null) {
          map[key] = IndexData.from(key, data[key]);
        }
      }
    }
    return map;
  }
}

class IndexData {
  final String name;
  final double price;
  final double changePct;
  final double change; // 涨跌额
  final double open;
  final double high;
  final double low;
  final double volume;
  final double amountWan;

  IndexData.from(String key, dynamic d)
      : name = ['上证指数', '深证成指', '创业板指'][
            ['sh', 'sz', 'cy'].indexOf(key) < 0 ? 0 : ['sh', 'sz', 'cy'].indexOf(key)],
        price = _toDouble(d['price']),
        changePct = _toDouble(d['change_pct']),
        change = _toDouble(d['change']),
        open = _toDouble(d['open']),
        high = _toDouble(d['high']),
        low = _toDouble(d['low']),
        volume = _toDouble(d['volume']),
        amountWan = _toDouble(d['amount_wan']);

  bool get isUp => changePct >= 0;
}

class MarketStats {
  final int total;
  final int up;
  final int down;
  final int flat;
  final int limitUp;
  final int limitDown;

  MarketStats.from(Map<String, dynamic> d)
      : total = _toInt(d['total']),
        up = _toInt(d['up']),
        down = _toInt(d['down']),
        flat = _toInt(d['flat']),
        limitUp = _toInt(d['limit_up']),
        limitDown = _toInt(d['limit_down']);

  MarketStats.empty()
      : total = 0, up = 0, down = 0, flat = 0, limitUp = 0, limitDown = 0;
}

class LimitUpStock {
  final String symbol;
  final String name;
  final double price;
  final double risePct;
  final int consecutive; // 连板数
  final String? reason; // 涨停原因

  LimitUpStock.from(dynamic d)
      : symbol = _asStr(d['symbol']),
        name = _asStr(d['name']),
        price = _toDouble(d['close'] ?? d['price']),
        risePct = _toDouble(d['rise_pct'] ?? d['pct_chg']),
        consecutive = _toInt(d['consecutive'] ?? d['board']),
        reason = d['reason'] as String?;
}

// ============================================================
// 情绪数据
// ============================================================

class SentimentData {
  final double score;
  final String phase;
  final double accel;
  final int signalCount;
  final String? positionLimit;
  final Map<String, dynamic>? marketData;

  SentimentData.from(Map<String, dynamic> d)
      : score = _toDouble(d['sentiment_score'] ?? d['score']),
        phase = d['phase'] as String? ?? '--',
        accel = _toDouble(d['sentiment_accel'] ?? d['accel']),
        signalCount = _toInt(d['signal_count'] ?? d['count']),
        positionLimit = d['position_limit'] as String?,
        marketData = d['market_data'] as Map<String, dynamic>?;

  SentimentData.empty()
      : score = 0, phase = '--', accel = 0, signalCount = 0,
        positionLimit = null, marketData = null;

  /// 9个指标方块数据
  List<IndicatorBlock> get indicatorBlocks {
    final md = marketData ?? {};
    return [
      IndicatorBlock('涨家数', _toInt(md['up_count']), isGood: _toInt(md['up_count']) > _toInt(md['down_count'])),
      IndicatorBlock('跌家数', _toInt(md['down_count']), isGood: false),
      IndicatorBlock('涨停', _toInt(md['limit_up_count'] ?? md['limit_up'])),
      IndicatorBlock('跌停', _toInt(md['limit_down_count'] ?? md['limit_down']), isGood: false),
      IndicatorBlock('涨跌比', _asStr(md['up_down_ratio'] ?? '--')),
      IndicatorBlock('炸板率', _asStr(md['zha_board_rate'] ?? '--'), isGood: false),
      IndicatorBlock('连板均涨幅', _asStr(md['lianban_avg_pct'] ?? '--')),
      IndicatorBlock('高标溢价', _asStr(md['gaobiao_premium'] ?? '--')),
      IndicatorBlock('跌停封单', _asStr(md['die_ting_fengdan'] ?? '--'), isGood: false),
    ];
  }
}

class IndicatorBlock {
  final String label;
  final String value;
  final bool isGood;

  IndicatorBlock(this.label, dynamic val, {this.isGood = true})
      : value = val is double ? val.toStringAsFixed(2) : '$val';
}

// ============================================================
// 情绪历史
// ============================================================

class SentimentHistoryPoint {
  final String date;
  final double score;
  final String phase;

  SentimentHistoryPoint.from(dynamic d)
      : date = _asStr(d['date'] ?? d['t']),
        score = _toDouble(d['score'] ?? d['v']),
        phase = d['phase'] as String? ?? '--';
}

// ============================================================
// 龙头选股 — 候选股
// ============================================================

class DragonCandidate {
  final int rank;
  final String symbol;
  final String name;
  final double score;
  final int consecutive;
  final String? industry;
  final double amountWan;
  final double price;
  final double changePct;
  final bool isLimitUp;
  final Map<String, dynamic>? details; // 10维度因子
  final Map<String, dynamic>? tradePlan; // 买卖计划
  final bool hasSignal;
  final String? direction; // 买入/卖出

  DragonCandidate.from(dynamic d, {this.rank = 0})
      : symbol = _asStr(d['symbol'] ?? d['code']),
        name = _asStr(d['name']),
        score = _toDouble(d['score']),
        consecutive = _toInt(d['consecutive'] ?? d['board']),
        industry = d['industry'] as String?,
        amountWan = _toDouble((d['realtime'] as Map<String, dynamic>?)?['amount_wan'] ?? d['amount']),
        price = _toDouble((d['realtime'] as Map<String, dynamic>?)?['price'] ?? d['price']),
        changePct = _toDouble((d['realtime'] as Map<String, dynamic>?)?['change_pct'] ?? d['change_pct']),
        isLimitUp = (d['realtime'] as Map<String, dynamic>?)?['is_limit_up'] == true || d['is_limit_up'] == true,
        details = d['details'] as Map<String, dynamic>?,
        tradePlan = d['trade_plan'] as Map<String, dynamic>?,
        hasSignal = d['has_signal'] == true || (d['details'] != null),
        direction = d['direction'] as String?;

  double get amountYi => amountWan / 10000;
  bool get isUp => changePct >= 0;

  /// 推荐评级
  String get recommendation {
    if (score < 2 || (direction == '卖出')) return '不推荐买';
    if (score >= 4 && consecutive >= 2) return '强烈推荐';
    return '谨慎观察';
  }

  ColorInt get recommendationColor {
    switch (recommendation) {
      case '强烈推荐': return const ColorInt(0xFF2ECC71);
      case '谨慎观察': return const ColorInt(0xFFF1C40F);
      default: return const ColorInt(0xFFE74C3C);
    }
  }
}

// ============================================================
// 信号摘要
// ============================================================

class SignalSummary {
  final String date;
  final String phase;
  final double sentimentScore;
  final double accel;
  final String? positionLimit;

  SignalSummary.from(Map<String, dynamic> d)
      : date = _asStr(d['date']),
        phase = d['phase'] as String? ?? '--',
        sentimentScore = _toDouble(d['sentiment_score']),
        accel = _toDouble(d['sentiment_accel']),
        positionLimit = d['position_limit'] as String?;
}

// ============================================================
// K线数据
// ============================================================

class KlinePoint {
  final String date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  KlinePoint.from(dynamic d)
      : date = _asStr(d['date'] ?? d['t']),
        open = _toDouble(d['open'] ?? d['o']),
        high = _toDouble(d['high'] ?? d['h']),
        low = _toDouble(d['low'] ?? d['l']),
        close = _toDouble(d['close'] ?? d['c']),
        volume = _toDouble(d['volume'] ?? d['v']);

  bool get isUp => close >= open;
}

class MaResult {
  final double? ma5;
  final double? ma10;
  final double? ma20;
  final double? ma60;
  final String arrangement; // 多头/空头/震荡

  MaResult.from(Map<String, dynamic> d)
      : ma5 = _toDoubleOrNull(d['ma5']),
        ma10 = _toDoubleOrNull(d['ma10']),
        ma20 = _toDoubleOrNull(d['ma20']),
        ma60 = _toDoubleOrNull(d['ma60']),
        arrangement = d['ma_arrangement'] as String? ?? '--';
}

class SupportResistance {
  final double? support1;
  final double? resistance1;
  final double? support2;
  final double? resistance2;

  SupportResistance.from(Map<String, dynamic> d)
      : support1 = _toDoubleOrNull(d['support1']),
        resistance1 = _toDoubleOrNull(d['resistance1']),
        support2 = _toDoubleOrNull(d['support2']),
        resistance2 = _toDoubleOrNull(d['resistance2']);
}

// ============================================================
// 买卖决策 — 五维评分
// ============================================================

class FiveDimScore {
  final double technical;    // 技术面 25%
  final double sentiment;    // 情绪面 20%
  final double concept;      // 题材面 20%
  final double capital;      // 资金面 20%
  final double fundamental;  // 基本面 15%
  final double total;

  FiveDimScore.from(Map<String, dynamic> d)
      : technical = _toDouble(d['technical']),
        sentiment = _toDouble(d['sentiment']),
        concept = _toDouble(d['concept']),
        capital = _toDouble(d['capital']),
        fundamental = _toDouble(d['fundamental']),
        total = _toDouble(d['total'] ?? d['overall']);

  FiveDimScore.empty()
      : technical = 0, sentiment = 0, concept = 0,
        capital = 0, fundamental = 0, total = 0;

  String get rating {
    if (total >= 7) return '强烈推荐';
    if (total >= 4) return '谨慎观察';
    return '不推荐买';
  }
}

// ============================================================
// 买入方案
// ============================================================

class BuyPlan {
  final String title;
  final String entry;
  final String stopLoss;
  final String takeProfit;
  final String holdingDays;
  final String reasoning;
  final bool recommended;

  BuyPlan.from(Map<String, dynamic> d)
      : title = _asStr(d['title']),
        entry = _asStr(d['entry'] ?? d['entry_price']),
        stopLoss = _asStr(d['stop_loss']),
        takeProfit = _asStr(d['take_profit']),
        holdingDays = _asStr(d['holding'] ?? d['holding_days']),
        reasoning = _asStr(d['reasoning']),
        recommended = d['recommended'] == true;

  static List<BuyPlan> fromList(dynamic list) {
    if (list is! List) return [];
    return list.map((e) => BuyPlan.from(e is Map ? Map<String, dynamic>.from(e) : {})).toList();
  }
}

// ============================================================
// 卖出策略
// ============================================================

class SellStrategy {
  final String condition;
  final String action;
  final String? psychological; // 行为金融学提醒

  SellStrategy.from(Map<String, dynamic> d)
      : condition = _asStr(d['condition']),
        action = _asStr(d['action']),
        psychological = d['psychological'] as String?;

  static List<SellStrategy> fromList(dynamic list) {
    if (list is! List) return [];
    return list.map((e) => SellStrategy.from(e is Map ? Map<String, dynamic>.from(e) : {})).toList();
  }
}

// ============================================================
// 生命周期定位
// ============================================================

class LifecyclePosition {
  final String phase;     // 建仓区/主升区/出货区/下跌区/均衡区
  final String detail;

  LifecyclePosition.from(Map<String, dynamic> d)
      : phase = _asStr(d['phase']),
        detail = _asStr(d['detail']);

  String get emoji {
    switch (phase) {
      case '建仓区': return '📥';
      case '主升区': return '📈';
      case '出货区': return '📤';
      case '下跌区': return '📉';
      default: return '⚖️';
    }
  }
}

// ============================================================
// 完整分析数据（个股查询返回）
// ============================================================

class StockAnalysis {
  final String symbol;
  final String name;
  final StockRealtime realtime;
  final MaResult? maPosition;
  final SupportResistance? supportResistance;
  final VolumeConcept? volumeConcept;
  final SentimentSignal? sentimentSignal;
  final FiveDimScore? fiveDimScore;
  final LifecyclePosition? lifecycle;
  final List<BuyPlan> buyPlans;
  final List<SellStrategy> sellStrategies;

  StockAnalysis.from(Map<String, dynamic> d)
      : symbol = _asStr(d['symbol']),
        name = _asStr(d['name']),
        realtime = StockRealtime.from(d['realtime'] ?? {}),
        maPosition = d['ma_position'] != null ? MaResult.from(d['ma_position']) : null,
        supportResistance = d['support_resistance'] != null ? SupportResistance.from(d['support_resistance']) : null,
        volumeConcept = d['volume_ratio'] != null || d['concept'] != null
            ? VolumeConcept.from(d['volume_ratio'] ?? {}, d['concept'] ?? {})
            : null,
        sentimentSignal = d['sentiment'] != null || d['signal_coverage'] != null
            ? SentimentSignal.from(d['sentiment'] ?? {}, d['signal_coverage'] ?? {})
            : null,
        fiveDimScore = d['five_dim_score'] != null ? FiveDimScore.from(d['five_dim_score']) : null,
        lifecycle = d['lifecycle'] != null ? LifecyclePosition.from(d['lifecycle']) : null,
        buyPlans = BuyPlan.fromList(d['buy_plans']),
        sellStrategies = SellStrategy.fromList(d['sell_strategies']);
}

class StockRealtime {
  final double price;
  final double changePct;
  final double prevClose;
  final double open;
  final double high;
  final double low;
  final double volume;
  final double amountWan;
  final double pe;
  final double volumeRatio;
  final double turnoverRateMini;

  StockRealtime.from(Map<String, dynamic> d)
      : price = _toDouble(d['price']),
        changePct = _toDouble(d['change_pct']),
        prevClose = _toDouble(d['prev_close'] ?? d['yclose']),
        open = _toDouble(d['open']),
        high = _toDouble(d['high']),
        low = _toDouble(d['low']),
        volume = _toDouble(d['volume']),
        amountWan = _toDouble(d['amount_wan']),
        pe = _toDouble(d['pe']),
        volumeRatio = _toDouble(d['volume_ratio']),
        turnoverRateMini = _toDouble(d['turnover_rate_mini']);

  bool get isUp => changePct >= 0;
}

class VolumeConcept {
  final double volumeRatio;
  final String assessment;
  final int conceptCount;
  final double heatScore;
  final List<String> concepts;

  VolumeConcept.from(Map<String, dynamic> volData, Map<String, dynamic> conData)
      : volumeRatio = _toDouble(volData['volume_ratio']),
        assessment = volData['assessment'] as String? ?? '--',
        conceptCount = _toInt(conData['concept_count']),
        heatScore = _toDouble(conData['heat_score']),
        concepts = (conData['concepts'] as List<dynamic>?)
            ?.map((e) => '$e').toList() ?? [];
}

class SentimentSignal {
  final double score;
  final String phase;
  final bool inSignal;
  final double accel;
  final int signalRank;
  final double signalScore;
  final Map<String, dynamic>? signalDetails;

  SentimentSignal._({
    this.score = 0,
    this.phase = '--',
    this.inSignal = false,
    this.accel = 0,
    this.signalRank = 0,
    this.signalScore = 0,
    this.signalDetails = null,
  });

  factory SentimentSignal.from(Map<String, dynamic> sentData, Map<String, dynamic> sigData) {
    return SentimentSignal._(
      score: _toDouble(sentData['score']),
      phase: sentData['phase'] as String? ?? '--',
      inSignal: sigData['in_signal'] == true,
      accel: _toDouble(sentData['accel']),
      signalRank: _toInt(sigData['signal_rank']),
      signalScore: _toDouble(sigData['signal_score']),
      signalDetails: sigData['signal_info'] is Map ? (sigData['signal_info'] as Map)['details'] as Map<String, dynamic>? : null,
    );
  }

  factory SentimentSignal.empty() => SentimentSignal._();
}

// ============================================================
// 工具函数
// ============================================================

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

double? _toDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.round();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

String _asStr(dynamic v) => v?.toString() ?? '--';

/// 用于推荐评级颜色的简单类（代替 dart:ui Color 在模型层的使用）
class ColorInt {
  final int value;
  const ColorInt(this.value);
}
