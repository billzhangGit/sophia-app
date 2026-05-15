import 'package:flutter/material.dart';
import '../models/stock_models.dart';
import '../services/api_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/kline_chart.dart';
import '../widgets/sentiment_chart.dart';

/// 复盘页面 — 市场总览
/// 包含：大盘指数、情绪阶段、涨跌统计、K线图、情绪走势、涨停TOP6、信号摘要
class ReviewPage extends StatefulWidget {
  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final _api = ApiService();

  MarketOverview? _overview;
  List<SentimentHistoryPoint> _sentimentHistory = [];
  List<KlinePoint> _klineData = [];
  List<double>? _ma5;
  List<double>? _ma10;
  List<double>? _ma20;

  String _selectedIndex = 'sh';
  String _selectedIndexName = '上证';

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getMarketOverview(),
        _api.getMarketSentiment(),
      ]);

      final overviewRaw = results[0];
      final sentimentRaw = results[1];

      final historyRaw = sentimentRaw['history'] as List<dynamic>? ?? [];

      setState(() {
        _overview = MarketOverview.from(overviewRaw);
        _sentimentHistory =
            historyRaw.map((e) => SentimentHistoryPoint.from(e)).toList();
      });

      await _loadIndexKline();

      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<double>? _parseMaList(dynamic raw) {
    if (raw is! List) return null;
    final list = <double>[];
    for (final v in raw) {
      if (v is num) {
        list.add(v.toDouble());
      } else {
        list.add(double.nan);
      }
    }
    return list.isEmpty ? null : list;
  }

  String _symbolForIndex(String key) {
    switch (key) {
      case 'sh':
        return '000001';
      case 'sz':
        return '399001';
      case 'cy':
        return '399006';
      default:
        return '000001';
    }
  }

  Future<void> _loadIndexKline() async {
    try {
      final symbol = _symbolForIndex(_selectedIndex);
      final klineRaw =
          await _api.getIndexKline(days: 120, symbol: symbol);
      final klineList = klineRaw['kline'] as List<dynamic>? ?? [];

      if (mounted) {
        setState(() {
          _klineData =
              klineList.map((e) => KlinePoint.from(e)).toList();
          _ma5 = _parseMaList(klineRaw['ma5']);
          _ma10 = _parseMaList(klineRaw['ma10']);
          _ma20 = _parseMaList(klineRaw['ma20']);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('K线加载失败: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _overview == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text('加载失败', style: TextStyle(color: Colors.grey[400])),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _error!.length > 60
                      ? '${_error!.substring(0, 60)}...'
                      : _error!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ),
            TextButton(onPressed: _loadData, child: const Text('重试')),
          ],
        ),
      );
    }

    final overview = _overview!;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.pad),
        children: [
          // ==================== 大盘指数 ====================
          _buildIndexRow(overview.indexes),
          const SizedBox(height: AppTheme.pad),

          // ==================== 情绪阶段 ====================
          _buildPhaseCard(overview.sentiment),
          const SizedBox(height: AppTheme.pad),

          // ==================== 涨跌统计 ====================
          _buildStatsRow(overview.stats),
          const SizedBox(height: AppTheme.pad),

          // ==================== K 线图 ====================
          if (_klineData.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.show_chart,
                    size: 16, color: AppTheme.textDim),
                const SizedBox(width: 6),
                Text('${_selectedIndexName}K线 (120日)',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(AppTheme.radius),
              ),
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
              child: KlineChart(
                klineData: _klineData,
                ma5: _ma5,
                ma10: _ma10,
                ma20: _ma20,
                height: 240,
              ),
            ),
            const SizedBox(height: AppTheme.pad),
          ],

          // ==================== 情绪走势图 ====================
          Row(
            children: [
              const Icon(Icons.timeline,
                  size: 16, color: AppTheme.textDim),
              const SizedBox(width: 6),
              const Text('情绪指数走势 (30日)',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            padding: const EdgeInsets.fromLTRB(4, 8, 8, 4),
            child: _sentimentHistory.isNotEmpty
                ? SentimentChart(history: _sentimentHistory)
                : const SizedBox(
                    height: 160,
                    child: Center(
                      child: Text('情绪数据加载中...',
                          style: TextStyle(color: AppTheme.textDim)),
                    ),
                  ),
          ),
          const SizedBox(height: AppTheme.pad),

          // ==================== 涨停 TOP6 ====================
          if (overview.topLimitUp.isNotEmpty) ...[
            Row(
              children: [
                const Text('🔥 涨停TOP6',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Text('共${overview.stats.limitUp}只涨停',
                    style: const TextStyle(
                        color: AppTheme.textDim, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            _buildLimitUpList(overview.topLimitUp),
            const SizedBox(height: AppTheme.pad),
          ],

          // ==================== 信号摘要 ====================
          if (overview.signal != null) ...[
            _buildSignalSummary(overview.signal!),
            const SizedBox(height: AppTheme.pad),
          ],

          // 底部留白
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ============================================================
  // 大盘指数行
  // ============================================================
  Widget _buildIndexRow(Map<String, IndexData> indexes) {
    final sh = indexes['sh'];
    final sz = indexes['sz'];
    final cy = indexes['cy'];

    return Row(
      children: [
        Expanded(child: _indexCard('sh', '上证', sh, AppTheme.up)),
        const SizedBox(width: 8),
        Expanded(child: _indexCard('sz', '深证', sz, AppTheme.info)),
        const SizedBox(width: 8),
        Expanded(child: _indexCard('cy', '创业板', cy, AppTheme.down)),
      ],
    );
  }

  Widget _indexCard(String key, String name, IndexData? data, Color accent) {
    final isSelected = key == _selectedIndex;
    final price = data?.price ?? 0;
    final changePct = data?.changePct ?? 0;
    final isUp = changePct >= 0;
    final changeColor = isUp ? AppTheme.up : AppTheme.down;
    final changeSign = isUp ? '+' : '';

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = key;
          _selectedIndexName = name;
        });
        _loadIndexKline();
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.pad),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: isSelected
              ? Border.all(color: accent, width: 2)
              : Border(
                  top: BorderSide(
                      color: accent.withOpacity(0.6), width: 2),
                ),
        ),
        child: Column(
          children: [
            Text(name,
                style: const TextStyle(
                    color: AppTheme.textDim, fontSize: 12)),
            const SizedBox(height: 4),
            Text(price.toStringAsFixed(2),
                style: TextStyle(
                    fontSize: price >= 10000 ? 15 : 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(
              '$changeSign${changePct.toStringAsFixed(2)}%',
              style: TextStyle(
                color: changeColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 情绪阶段卡片
  // ============================================================
  Widget _buildPhaseCard(SentimentData sentiment) {
    final phase = sentiment.phase;
    final score = sentiment.score;
    final accel = sentiment.accel;
    final phaseColor = AppTheme.phaseColor(phase);
    final phaseEmoji = AppTheme.phaseEmoji(phase);

    return Container(
      padding: const EdgeInsets.all(AppTheme.pad),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: phaseColor.withOpacity(0.5), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('$phaseEmoji  $phase',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: phaseColor)),
              const Spacer(),
              // 信号计数
              if (sentiment.signalCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${sentiment.signalCount}个信号',
                    style: const TextStyle(
                        color: AppTheme.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _phaseValueChip('情绪评分', score.toStringAsFixed(1),
                  AppTheme.scoreColor(score)),
              const SizedBox(width: 12),
              _phaseValueChip(
                '加速度',
                '${accel >= 0 ? '+' : ''}${accel.toStringAsFixed(2)}',
                accel >= 0 ? AppTheme.up : AppTheme.down,
              ),
              if (sentiment.positionLimit != null) ...[
                const SizedBox(width: 12),
                _phaseValueChip('仓位建议',
                    sentiment.positionLimit!, AppTheme.warning),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // 情绪周期尺子
          _buildPhaseRuler(phase),
        ],
      ),
    );
  }

  Widget _phaseValueChip(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textDim, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
      ],
    );
  }

  // ============================================================
  // 情绪周期尺子 — 6阶段渐变条 + 三角箭头指示当前阶段
  // ============================================================
  Widget _buildPhaseRuler(String currentPhase) {
    const phases = ['冰点期', '复苏期', '均衡期', '高潮期', '沸腾期', '退潮期'];
    final phaseColors = phases.map((p) => AppTheme.phaseColor(p)).toList();
    final currentIdx = phases.indexOf(currentPhase);
    final clampedIdx = currentIdx < 0 ? 0 : currentIdx;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('情绪周期',
            style: TextStyle(color: AppTheme.textDim, fontSize: 11)),
        const SizedBox(height: 6),
        // 渐变条 + 箭头指示
        LayoutBuilder(
          builder: (ctx, constraints) {
            final totalWidth = constraints.maxWidth;
            final segWidth = totalWidth / phases.length;
            return SizedBox(
              width: totalWidth,
              height: 36,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 渐变条
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 4,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        gradient: LinearGradient(
                          colors: phaseColors,
                          stops: const [
                            0.0, 0.2, 0.4, 0.6, 0.8, 1.0,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 三角箭头指示器
                  if (clampedIdx >= 0)
                    Positioned(
                      left: segWidth * clampedIdx +
                          segWidth / 2 -
                          8,
                      top: -4,
                      child: Transform.rotate(
                        angle: 1.5708, // 90度 = π/2, 箭头朝下
                        child: Icon(
                          Icons.play_arrow,
                          size: 20,
                          color: phaseColors[clampedIdx],
                        ),
                      ),
                    ),
                  // 阶段标签
                  ...List.generate(phases.length, (i) {
                    final isCurrent = i == clampedIdx;
                    return Positioned(
                      left: segWidth * i + segWidth / 2 - 20,
                      top: 22,
                      child: SizedBox(
                        width: 40,
                        child: Text(
                          phases[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isCurrent
                                ? phaseColors[i]
                                : AppTheme.textMuted,
                            fontSize: isCurrent ? 10 : 8,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // 涨跌统计行
  // ============================================================
  Widget _buildStatsRow(MarketStats stats) {
    return Row(
      children: [
        _statChip('上涨', stats.up, AppTheme.up),
        const SizedBox(width: 6),
        _statChip('下跌', stats.down, AppTheme.down),
        const SizedBox(width: 6),
        _statChip('涨停', stats.limitUp, AppTheme.limitUp),
        const SizedBox(width: 6),
        _statChip('跌停', stats.limitDown, AppTheme.limitDown),
      ],
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
              color: color.withOpacity(0.25), width: 0.5),
        ),
        child: Column(
          children: [
            Text('$count',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textDim, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 涨停 TOP6 增强列表
  // ============================================================
  Widget _buildLimitUpList(List<LimitUpStock> list) {
    final items = list.take(6).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        children: [
          // 表头
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.pad, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardAlt,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radius),
                topRight: Radius.circular(AppTheme.radius),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(width: 28, child: Text('#' ,
                    style: TextStyle(
                        color: AppTheme.textDim, fontSize: 11))),
                Expanded(
                    flex: 3,
                    child: Text('名称',
                        style: TextStyle(
                            color: AppTheme.textDim,
                            fontSize: 11))),
                Expanded(
                    flex: 2,
                    child: Text('现价',
                        style: TextStyle(
                            color: AppTheme.textDim,
                            fontSize: 11))),
                Expanded(
                    flex: 2,
                    child: Text('涨幅',
                        style: TextStyle(
                            color: AppTheme.textDim,
                            fontSize: 11))),
                Expanded(
                    flex: 2,
                    child: Text('连板',
                        style: TextStyle(
                            color: AppTheme.textDim,
                            fontSize: 11))),
              ],
            ),
          ),
          // 数据行
          ...List.generate(items.length, (i) {
            final stock = items[i];
            final isEven = i % 2 == 0;
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.pad, vertical: 10),
              decoration: BoxDecoration(
                color: isEven ? Colors.transparent : AppTheme.cardAlt,
                border: i < items.length - 1
                    ? const Border(
                        bottom: BorderSide(
                            color: AppTheme.textMuted, width: 0.15))
                    : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                          color: AppTheme.textDim, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stock.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        if (stock.reason != null &&
                            stock.reason!.isNotEmpty)
                          Text(
                            stock.reason!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppTheme.textDim,
                                fontSize: 10),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(stock.price.toStringAsFixed(2),
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.text)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '+${stock.risePct.toStringAsFixed(2)}%',
                      style: const TextStyle(
                        color: AppTheme.up,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: stock.consecutive > 1
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.limitUp.withOpacity(0.2),
                              borderRadius:
                                  BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${stock.consecutive}连板',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.limitUp,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.up.withOpacity(0.15),
                              borderRadius:
                                  BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '首板',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.up,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ============================================================
  // 信号摘要
  // ============================================================
  Widget _buildSignalSummary(SignalSummary signal) {
    final phaseColor = AppTheme.phaseColor(signal.phase);

    return Container(
      padding: const EdgeInsets.all(AppTheme.pad),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
            color: AppTheme.warning.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.summarize,
                  size: 16, color: AppTheme.warning),
              const SizedBox(width: 6),
              const Text('信号摘要',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              Text(signal.date,
                  style: const TextStyle(
                      color: AppTheme.textDim, fontSize: 12)),
            ],
          ),
          const Divider(
              height: 16, color: AppTheme.textMuted),
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  '情绪阶段',
                  signal.phase,
                  phaseColor,
                ),
              ),
              Expanded(
                child: _summaryItem(
                  '情绪评分',
                  signal.sentimentScore.toStringAsFixed(1),
                  AppTheme.scoreColor(signal.sentimentScore),
                ),
              ),
              Expanded(
                child: _summaryItem(
                  '加速度',
                  '${signal.accel >= 0 ? '+' : ''}${signal.accel.toStringAsFixed(2)}',
                  signal.accel >= 0 ? AppTheme.up : AppTheme.down,
                ),
              ),
              if (signal.positionLimit != null)
                Expanded(
                  child: _summaryItem(
                    '仓位建议',
                    signal.positionLimit!,
                    AppTheme.warning,
                  ),
                ),
            ],
          ),
          if (signal.phase.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: phaseColor.withOpacity(0.08),
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                _phaseAdvice(signal.phase),
                style: const TextStyle(
                    color: AppTheme.textDim, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textDim, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              )),
        ],
      ),
    );
  }

  String _phaseAdvice(String phase) {
    switch (phase) {
      case '冰点期':
        return '冰点期：市场情绪极度悲观，可左侧试错建仓，控制仓位在3成以下。';
      case '复苏期':
        return '复苏期：情绪回暖，可逐步加仓至5-6成，关注率先反弹的强势板块。';
      case '均衡期':
        return '均衡期：多空平衡，适合高抛低吸，仓位控制在4-5成。';
      case '高潮期':
        return '高潮期：情绪亢奋，持股为主但不宜追高，可维持7-8成仓位。';
      case '沸腾期':
        return '沸腾期：情绪极端过热，警惕见顶回落，建议减仓至3-4成。';
      case '退潮期':
        return '退潮期：情绪回落，防御为主，仓位控制在2-3成以下。';
      default:
        return '当前市场情绪震荡，注意控制风险，灵活应对。';
    }
  }
}
