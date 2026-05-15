/// 龙头选股页面 — 信号头部 + 9指标方块 + 候选股列表 + 因子详情 + 买卖建议 + 策略回测
library dragon_page;

import 'package:flutter/material.dart';
import '../models/stock_models.dart';
import '../services/api_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/score_badge.dart';
import '../widgets/rating_badge.dart';
import '../widgets/factor_detail_sheet.dart';
import '../widgets/strategy_perf_card.dart';
import '../widgets/sell_strategy_card.dart';

class DragonPage extends StatefulWidget {
  const DragonPage({super.key});

  @override
  State<DragonPage> createState() => _DragonPageState();
}

class _DragonPageState extends State<DragonPage> {
  final _api = ApiService();
  Map<String, dynamic>? _rawData;
  List<DragonCandidate> _candidates = [];
  SentimentData _sentiment = SentimentData.empty();
  bool _loading = true;
  String? _error;

  // 策略下拉
  List<String> _strategies = [];
  String? _selectedStrategy;

  @override
  void initState() {
    super.initState();
    _loadStrategies();
  }

  Future<void> _loadStrategies() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getDragonStrategies();
      final list = (data['strategies'] as List<dynamic>?)
              ?.map((e) => (e as Map<String, dynamic>)['name'] as String)
              .toList() ??
          [];
      setState(() {
        _strategies = list;
        if (list.isNotEmpty) {
          _selectedStrategy = list.first;
        }
        _loading = false;
        _error = null;
      });
      // 加载默认策略数据
      if (_selectedStrategy != null) {
        _loadData(_selectedStrategy!);
      } else {
        _loadData(null);
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadData(String? strategy) async {
    setState(() => _loading = true);
    try {
      final data = strategy != null
          ? await _api.getDragonSelectionByStrategy(strategy)
          : await _api.getDragonSelection();
      setState(() {
        _rawData = data;
        _sentiment = SentimentData.from(data['sentiment'] as Map<String, dynamic>? ?? {});
        final list = data['candidates'] as List<dynamic>? ?? [];
        _candidates = list.asMap().entries.map((e) =>
          DragonCandidate.from(e.value, rank: e.key + 1)
        ).toList();
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

  Future<void> _refresh() async {
    if (_selectedStrategy != null) {
      await _loadData(_selectedStrategy!);
    } else {
      await _loadStrategies();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text('加载失败', style: TextStyle(color: Colors.grey[400])),
            Text(_error!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            TextButton(onPressed: _refresh, child: const Text('重试')),
          ],
        ),
      );
    }

    final hasSignal = _rawData?['has_signal'] == true;
    if (!hasSignal && _candidates.isEmpty) {
      return const Center(child: Text('暂无信号数据'));
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildSignalHeader(),
          const SizedBox(height: 12),
          // 策略下拉选择器
          _buildStrategySelector(),
          const SizedBox(height: 12),
          _buildIndicatorBlocks(),
          const SizedBox(height: 12),
          // 策略回测表现
          _buildStrategyPerf(),
          const SizedBox(height: 12),
          // 候选股列表
          Text('候选股 (${_candidates.length})',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.text)),
          const SizedBox(height: 6),
          ..._candidates.map((c) => _buildCandidateCard(c)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ================================================================
  // 信号头部
  // ================================================================
  Widget _buildSignalHeader() {
    final phase = _sentiment.phase;
    final score = _sentiment.score;
    final accel = _sentiment.accel;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('情绪阶段',
                  style: TextStyle(color: AppTheme.textDim, fontSize: 12)),
              const Spacer(),
              Text('$score 分',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.scoreColor(score))),
            ],
          ),
          const SizedBox(height: AppTheme.padSmall),
          Row(
            children: [
              Text('$phaseEmoji $phase',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: phaseColor)),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    accel >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: accel >= 0 ? AppTheme.up : AppTheme.down,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '加速度 ${accel >= 0 ? '+' : ''}${accel.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: accel >= 0 ? AppTheme.up : AppTheme.down,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_sentiment.positionLimit != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('仓位建议: ${_sentiment.positionLimit}',
                  style: TextStyle(
                      color: AppTheme.warning, fontSize: 12)),
            ),
          ],
          if (_sentiment.signalCount > 0) ...[
            const SizedBox(height: 6),
            Text('信号 ${_sentiment.signalCount} 个',
                style: TextStyle(color: AppTheme.textDim, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  // ================================================================
  // 策略下拉选择器
  // ================================================================
  Widget _buildStrategySelector() {
    if (_strategies.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pad, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: AppTheme.textDim),
          const SizedBox(width: 8),
          const Text('策略',
              style: TextStyle(color: AppTheme.textDim, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStrategy,
                isExpanded: true,
                dropdownColor: AppTheme.cardAlt,
                style: const TextStyle(
                    color: AppTheme.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
                icon: const Icon(Icons.expand_more,
                    color: AppTheme.textDim, size: 18),
                items: _strategies
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null && val != _selectedStrategy) {
                    setState(() => _selectedStrategy = val);
                    _loadData(val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // 9 指标方块
  // ================================================================
  Widget _buildIndicatorBlocks() {
    final blocks = _sentiment.indicatorBlocks;
    return Container(
      padding: const EdgeInsets.all(AppTheme.pad),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('市场指标',
              style: TextStyle(
                  color: AppTheme.text,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: AppTheme.padSmall),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: blocks.length,
            itemBuilder: (_, i) => _buildBlockTile(blocks[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockTile(IndicatorBlock block) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: block.isGood
            ? AppTheme.down.withOpacity(0.08)
            : AppTheme.up.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: block.isGood
              ? AppTheme.down.withOpacity(0.2)
              : AppTheme.up.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            block.label,
            style: TextStyle(
              color: AppTheme.textDim,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            block.value,
            style: TextStyle(
              color: block.isGood ? AppTheme.down : AppTheme.up,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // 策略回测表现
  // ================================================================
  Widget _buildStrategyPerf() {
    final perf = _rawData?['strategy_perf'] as Map<String, dynamic>?;
    if (perf == null) return const SizedBox.shrink();

    return StrategyPerfCard(
      sharpe: (perf['sharpe'] as num?)?.toDouble(),
      winRate: (perf['win_rate'] as num?)?.toDouble(),
      annualReturn: (perf['annual_return'] as num?)?.toDouble(),
      maxDrawdown: (perf['max_drawdown'] as num?)?.toDouble(),
      vsBenchmark: (perf['vs_benchmark'] as num?)?.toDouble(),
    );
  }

  // ================================================================
  // 候选股卡片
  // ================================================================
  Widget _buildCandidateCard(DragonCandidate c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: () => _showCandidateDetail(c),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Row 1: 名称 + 评级 + 连板 ----
                _buildTopRow(c),
                const SizedBox(height: 8),
                // ---- Row 2: 价格 + 涨跌幅 + 成交额 ----
                _buildPriceRow(c),
                const SizedBox(height: 8),
                // ---- Row 3: 行业 + 排名标签 ----
                _buildMetaRow(c),
                // ---- Row 4: 买卖建议（如存在） ----
                if (c.tradePlan != null) ...[
                  const SizedBox(height: 8),
                  _buildTradeAdvice(c),
                ],
                // ---- Row 5: 因子评分表格 ----
                if (c.details != null) ...[
                  const SizedBox(height: 8),
                  _buildCandidateFactorGrid(c.details!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow(DragonCandidate c) {
    return Row(
      children: [
        // 排名
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _rankColor(c.rank).withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${c.rank}',
            style: TextStyle(
              color: _rankColor(c.rank),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 名称 + 代码
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.text)),
            Text(c.symbol,
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 11)),
          ],
        ),
        const Spacer(),
        // 评分徽章
        ScoreBadge(score: c.score, size: 30),
        const SizedBox(width: 8),
        // 推荐评级徽章
        if (c.score >= 2 || c.direction != '卖出')
          RatingBadge(rating: c.recommendation),
        // 连板标签
        if (c.consecutive > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.up.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('${c.consecutive}连板',
                style: const TextStyle(
                    color: AppTheme.up,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ],
        // 涨停标记
        if (c.isLimitUp) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.up,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('涨停',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceRow(DragonCandidate c) {
    return Row(
      children: [
        Text(c.price.toStringAsFixed(2),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.text)),
        const SizedBox(width: 8),
        Text(
          '${c.isUp ? '+' : ''}${c.changePct.toStringAsFixed(2)}%',
          style: TextStyle(
            color: c.isUp ? AppTheme.up : AppTheme.down,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Text('${c.amountYi.toStringAsFixed(2)}亿',
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 12)),
      ],
    );
  }

  Widget _buildMetaRow(DragonCandidate c) {
    return Row(
      children: [
        // 行业标签
        if (c.industry != null && c.industry!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.info.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppTheme.info.withOpacity(0.25),
              ),
            ),
            child: Text(c.industry!,
                style: TextStyle(
                    color: AppTheme.info,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ),
        const Spacer(),
        // 方向提示
        if (c.hasSignal && c.direction != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (c.direction == '买入'
                      ? AppTheme.up
                      : AppTheme.down)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  c.direction == '买入'
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: 12,
                  color: c.direction == '买入'
                      ? AppTheme.up
                      : AppTheme.down,
                ),
                const SizedBox(width: 3),
                Text(
                  c.direction == '买入' ? '买入信号' : '卖出信号',
                  style: TextStyle(
                    color: c.direction == '买入'
                        ? AppTheme.up
                        : AppTheme.down,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ================================================================
  // 交易建议行（从 tradePlan 绘制）
  // ================================================================
  Widget _buildTradeAdvice(DragonCandidate c) {
    final plan = c.tradePlan!;
    final entry = plan['entry'] ?? plan['entry_price'] ?? '--';
    final stopLoss = plan['stop_loss'] ?? '--';
    final takeProfit = plan['take_profit'] ?? '--';

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.cardAlt,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('交易策略',
              style: TextStyle(
                  color: AppTheme.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Row(
            children: [
              _adviceChip('入场', '$entry', AppTheme.text),
              const SizedBox(width: 12),
              _adviceChip('止损', '$stopLoss', AppTheme.up),
              const SizedBox(width: 12),
              _adviceChip('止盈', '$takeProfit', AppTheme.down),
            ],
          ),
        ],
      ),
    );
  }

  Widget _adviceChip(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ================================================================
  // 候选股卡片内的因子评分表格
  // ================================================================
  Widget _buildCandidateFactorGrid(Map<String, dynamic> details) {
    // 仅提取数值评分因子，排除非评分字段
    const skipKeys = <String>{
      'industry', 'amount', 'close', 'volume_ratio_raw', 'gap_raw',
      'consecutive', 'market_max_height', 'correction', 'correction_info', 'note',
    };
    final numericFactors = <MapEntry<String, double>>[];
    for (final entry in details.entries) {
      final k = entry.key;
      if (skipKeys.contains(k)) continue;
      if (entry.value is num) {
        numericFactors.add(MapEntry(k, (entry.value as num).toDouble()));
      }
    }
    if (numericFactors.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.cardAlt,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('因子评分',
              style: TextStyle(
                  color: AppTheme.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.8,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: numericFactors.length,
            itemBuilder: (_, index) {
              final f = numericFactors[index];
              final color = _candidateFactorColor(f.value);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: AppTheme.bg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _candidateFactorLabel(f.key),
                      style: const TextStyle(
                        color: AppTheme.textDim,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      f.value.toStringAsFixed(2),
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _candidateFactorColor(double v) {
    if (v >= 0.7) return AppTheme.up;
    if (v >= 0.4) return AppTheme.warning;
    return AppTheme.down;
  }

  String _candidateFactorLabel(String key) {
    const labelMap = {
      'height_score': '高度',
      'gap_score': '缺口',
      'sector_score': '板块',
      'heat_score': '热度',
      'sentiment_boost': '情绪加持',
      'recognition_score': '辨识度',
      'volume_score': '量能',
      'ladder_score': '梯次',
      'break_type_score': '突破类型',
      'nwave_score': 'N字波',
      'cgo_score': '筹码集中',
      'concept_diff_adj': '概念差异',
      'market_multiplier': '市场乘数',
    };
    return labelMap[key] ?? key;
  }

  // ================================================================
  // 候选股详情底部弹出（因子详情 + 买卖建议 + 回测）
  // ================================================================
  void _showCandidateDetail(DragonCandidate c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CandidateDetailSheet(candidate: c),
    );
  }

  Color _rankColor(int rank) {
    if (rank <= 3) return AppTheme.up;
    if (rank <= 6) return AppTheme.warning;
    return AppTheme.textDim;
  }
}

// ================================================================
// 候选股详情底部 Sheet
// ================================================================
class _CandidateDetailSheet extends StatelessWidget {
  final DragonCandidate candidate;

  const _CandidateDetailSheet({required this.candidate});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
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

          // ---- 头部行 ----
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(candidate.name,
                      style: const TextStyle(
                          color: AppTheme.text,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Text(candidate.symbol,
                      style: const TextStyle(
                          color: AppTheme.textDim, fontSize: 13)),
                ],
              ),
              const Spacer(),
              ScoreBadge(score: candidate.score, size: 40),
              const SizedBox(width: 8),
              RatingBadge(rating: candidate.recommendation),
            ],
          ),
          const SizedBox(height: 12),

          // ---- 基本信息 ----
          _buildInfoTile('行业',
              candidate.industry ?? '--', color: AppTheme.info),
          _buildInfoTile('连板数', '${candidate.consecutive} 连板'),
          _buildInfoTile('成交额', '${candidate.amountYi.toStringAsFixed(2)} 亿'),
          _buildInfoTile(
            '方向',
            candidate.direction ?? '--',
            color: candidate.direction == '买入'
                ? AppTheme.up
                : candidate.direction == '卖出'
                    ? AppTheme.down
                    : null,
          ),
          const SizedBox(height: 12),

          // ---- 10维度因子详情 ----
          if (candidate.details != null) ...[
            const Text('10维度因子分析',
                style: TextStyle(
                    color: AppTheme.text,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FactorDetailSheet(details: candidate.details!),
            const SizedBox(height: 12),
          ],

          // ---- 买入方案 ----
          if (candidate.tradePlan != null) ...[
            const Text('买入方案',
                style: TextStyle(
                    color: AppTheme.text,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildSimpleBuyPlan(candidate.tradePlan!),
            const SizedBox(height: 12),
          ],

          // ---- 卖出策略（从原始数据尝试提取） ----
          if (candidate.tradePlan?['sell_strategies'] != null) ...[
            const Text('卖出策略',
                style: TextStyle(
                    color: AppTheme.text,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SellStrategyCard(
              strategies: SellStrategy.fromList(
                  candidate.tradePlan!['sell_strategies']),
            ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 12)),
          ),
          Text(value,
              style: TextStyle(
                color: color ?? AppTheme.text,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }

  Widget _buildSimpleBuyPlan(Map<String, dynamic> plan) {
    final entry = plan['entry'] ?? plan['entry_price'] ?? '--';
    final stopLoss = plan['stop_loss'] ?? '--';
    final takeProfit = plan['take_profit'] ?? '--';
    final holding = plan['holding'] ?? plan['holding_days'] ?? '--';
    final reasoning = plan['reasoning'] as String?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardAlt,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border(
          left: BorderSide(
            color: AppTheme.up.withOpacity(0.5),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _miniLabel('入场', '$entry'),
              const SizedBox(width: 16),
              _miniLabel('止损', '$stopLoss', color: AppTheme.up),
              const SizedBox(width: 16),
              _miniLabel('止盈', '$takeProfit', color: AppTheme.down),
              const Spacer(),
              _miniLabel('持仓', '$holding'),
            ],
          ),
          if (reasoning != null && reasoning.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(reasoning,
                style: const TextStyle(
                    color: AppTheme.textDim,
                    fontSize: 12,
                    height: 1.4)),
          ],
        ],
      ),
    );
  }

  Widget _miniLabel(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
              color: color ?? AppTheme.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }
}
