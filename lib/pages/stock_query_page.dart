import 'package:flutter/material.dart';
import '../models/stock_models.dart';
import '../services/api_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/stock_header.dart';
import '../widgets/kline_chart.dart';
import '../widgets/five_dim_grid.dart';
import '../widgets/buy_plan_card.dart';
import '../widgets/sell_strategy_card.dart';
import '../widgets/lifecycle_badge.dart';

/// 个股查询页面 — 搜索 + K线 + 五维评分 + 买卖方案 + 生命周期
///
/// 功能：
/// 1. 输入股票代码/名称搜索
/// 2. 搜索结果列表
/// 3. 选中后加载完整分析：
///    - StockHeader 头部行情
///    - KlineChart 蜡烛图 + 均线
///    - FiveDimGrid 五维度评分
///    - LifecycleBadge 生命周期定位
///    - 3 个 BuyPlanCard （激进/中庸/保守）
///    - SellStrategyCard 卖出策略列表
///    - 详细分析区（MA排列 / 支撑压力 / 量价概念 / 情绪信号）
class StockQueryPage extends StatefulWidget {
  const StockQueryPage({super.key});

  @override
  State<StockQueryPage> createState() => _StockQueryPageState();
}

class _StockQueryPageState extends State<StockQueryPage> {
  final _api = ApiService();
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  // 搜索状态
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;
  bool _searched = false; // 是否执行过搜索
  String? _error;

  // 分析状态
  StockAnalysis? _analysis;
  List<KlinePoint> _klineData = [];
  bool _loadingAnalysis = false;
  String? _selectedSymbol;
  String? _selectedName;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // 网络请求
  // ---------------------------------------------------------------

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _searching = true;
      _analysis = null;
      _klineData = [];
      _selectedSymbol = null;
      _selectedName = null;
      _error = null;
    });
    try {
      final result = await _api.searchStock(query.trim());
      final rawList = result['results'] as List<dynamic>? ?? [];
      setState(() {
        _searchResults =
            rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _searching = false;
        _searched = true;
      });
      // 只搜到1只，直接加载分析
      if (_searchResults.length == 1) {
        _loadAnalysis(
          _searchResults.first['symbol'] as String,
          _searchResults.first['name'] as String? ?? '',
        );
      }
    } catch (e) {
      setState(() {
        _searching = false;
        _error = _fmtError(e);
      });
    }
  }

  Future<void> _loadAnalysis(String symbol, [String name = '']) async {
    setState(() {
      _loadingAnalysis = true;
      _selectedSymbol = symbol;
      _selectedName = name;
      _searchResults = [];
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getStockAnalysis(symbol),
        _api.getStockKline(symbol, days: 60),
      ]);
      final analysisRaw = results[0];
      final klineRaw = results[1];

      final analysis = StockAnalysis.from(analysisRaw);
      final klineList = (klineRaw['kline'] as List<dynamic>?)
              ?.map((e) => KlinePoint.from(e))
              .toList() ??
          [];

      setState(() {
        _analysis = analysis;
        _klineData = klineList;
        _loadingAnalysis = false;
      });
    } catch (e) {
      setState(() {
        _loadingAnalysis = false;
        _error = _fmtError(e);
      });
    }
  }

  String _fmtError(dynamic e) {
    final s = e.toString();
    // 去掉 "Exception: " 前缀
    return s.startsWith('Exception: ') ? s.substring(11) : s;
  }

  // ---------------------------------------------------------------
  // 构建
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 搜索栏
        _buildSearchBar(),
        // 内容区域
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: '输入股票代码或名称搜索…',
          hintStyle: TextStyle(color: Colors.grey[600]),
          filled: true,
          fillColor: AppTheme.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            borderSide: BorderSide.none,
          ),
          suffixIcon: IconButton(
            icon: _searching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.up,
                    ),
                  )
                : const Icon(Icons.search, color: AppTheme.textDim),
            onPressed: () => _search(_searchCtrl.text),
          ),
        ),
        style: const TextStyle(color: AppTheme.text),
        onSubmitted: _search,
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 40, color: AppTheme.warning),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textDim)),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => _search(_searchCtrl.text),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadingAnalysis) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.up),
      );
    }

    // 有分析结果 → 完整决策页
    if (_analysis != null) {
      return _buildAnalysisView();
    }

    // 有搜索结果列表
    if (_searchResults.isNotEmpty) {
      return _buildSearchResults();
    }

    // 空状态
    if (_searched && _searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[700]),
            const SizedBox(height: 12),
            Text('未找到该股票，请检查代码或名称',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _searched = false;
                  _searchResults = [];
                  _searchCtrl.clear();
                });
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重新搜索'),
            ),
          ],
        ),
      );
    }

    // 空状态
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 48, color: Colors.grey[700]),
          const SizedBox(height: 12),
          Text('搜索股票代码或名称查看完整分析',
              style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // 搜索结果列表
  // ---------------------------------------------------------------

  Widget _buildSearchResults() {
    return RefreshIndicator(
      onRefresh: () => _search(_searchCtrl.text),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: _searchResults.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (ctx, i) {
          final item = _searchResults[i];
          final symbol = item['symbol'] as String? ?? '';
          final name = item['name'] as String? ?? '';
          final industry = item['industry'] as String? ?? '';
          return Material(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              onTap: () => _loadAnalysis(symbol, name),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    // 代码 + 名称
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  color: AppTheme.text,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          const SizedBox(height: 2),
                          Text('$symbol  $industry',
                              style: const TextStyle(
                                  color: AppTheme.textDim, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppTheme.textMuted, size: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------
  // 完整分析决策视图
  // ---------------------------------------------------------------

  Widget _buildAnalysisView() {
    final a = _analysis!;
    final rt = a.realtime;

    // 提取 MA 数据供 KlineChart 使用
    final klineLen = _klineData.length;
    List<double>? ma5;
    List<double>? ma10;
    List<double>? ma20;
    if (a.maPosition != null) {
      final ma = a.maPosition!;
      if (ma.ma5 != null) ma5 = List.filled(klineLen, ma.ma5!);
      if (ma.ma10 != null) ma10 = List.filled(klineLen, ma.ma10!);
      if (ma.ma20 != null) ma20 = List.filled(klineLen, ma.ma20!);
    }

    return RefreshIndicator(
      onRefresh: () => _loadAnalysis(
          _selectedSymbol ?? a.symbol, _selectedName ?? a.name),
      child: ListView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
        children: [
          // ----- ① 头部行情 -----
          Container(
            padding: const EdgeInsets.all(AppTheme.pad),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            child: StockHeader(
              symbol: _selectedSymbol ?? a.symbol,
              name: _selectedName ?? a.name,
              price: rt.price,
              changePct: rt.changePct,
            ),
          ),
          const SizedBox(height: AppTheme.pad),

          // ----- ② K线图 -----
          if (_klineData.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.padSmall),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(AppTheme.radius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 4),
                    child: Text('K线走势（60日）',
                        style: TextStyle(
                            color: AppTheme.textDim,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ),
                  KlineChart(
                    klineData: _klineData,
                    ma5: ma5,
                    ma10: ma10,
                    ma20: ma20,
                    height: 240,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.pad),
          ],

          // ----- ③-① 综合评级横幅（Alex） -----
          if (a.fiveDimScore != null) ...[
            _buildRatingBanner(a),
            const SizedBox(height: AppTheme.pad),
          ],

          // ----- ③ 五维评分 -----
          if (a.fiveDimScore != null) ...[
            FiveDimGrid(score: a.fiveDimScore!),
            const SizedBox(height: AppTheme.pad),
          ],

          // ----- ③-② 打分明细表格 -----
          if (a.fiveDimScore != null) ...[
            _buildScoreDetailTable(a),
            const SizedBox(height: AppTheme.pad),
          ],

          // ----- ④ 生命周期定位（持仓位置模式） -----
          if (a.lifecycle != null) ...[
            _buildLifecycleSection(a.lifecycle!),
            const SizedBox(height: AppTheme.pad),
          ],

          // ----- ⑤ 买入方案（3个） -----
          if (a.buyPlans.isNotEmpty) ...[
            _buildSectionTitle('买入方案'),
            const SizedBox(height: 6),
            ...a.buyPlans.map((plan) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BuyPlanCard(plan: plan),
                )),
          ],

          // ----- ⑥ 卖出策略 -----
          if (a.sellStrategies.isNotEmpty) ...[
            const SizedBox(height: 4),
            SellStrategyCard(strategies: a.sellStrategies),
          ],

          // ----- ⑥-② 信号因子评分（来源：信号文件） -----
          if (a.sentimentSignal?.signalDetails != null && a.sentimentSignal!.inSignal) ...[
            _buildSignalFactorTable(a.sentimentSignal!.signalDetails!,
                a.sentimentSignal!.signalRank, a.sentimentSignal!.signalScore),
            const SizedBox(height: AppTheme.pad),
          ],

          // ----- ⑦ 详细分析区 -----
          const SizedBox(height: AppTheme.pad),
          _buildSectionTitle('详细分析'),
          const SizedBox(height: 6),

          // MA 排列
          if (a.maPosition != null)
            _buildDetailCard('均线排列', [
              _detailRow('MA5', _fmtVal(a.maPosition!.ma5)),
              _detailRow('MA10', _fmtVal(a.maPosition!.ma10)),
              _detailRow('MA20', _fmtVal(a.maPosition!.ma20)),
              _detailRow('MA60', _fmtVal(a.maPosition!.ma60)),
              _detailRow('形态', a.maPosition!.arrangement),
            ]),
          const SizedBox(height: 6),

          // 支撑压力
          if (a.supportResistance != null)
            _buildDetailCard('支撑压力位', [
              _detailRow(
                  '支撑1', _fmtVal(a.supportResistance!.support1)),
              _detailRow(
                  '压力1', _fmtVal(a.supportResistance!.resistance1)),
              _detailRow(
                  '支撑2', _fmtVal(a.supportResistance!.support2)),
              _detailRow(
                  '压力2', _fmtVal(a.supportResistance!.resistance2)),
            ]),
          const SizedBox(height: 6),

          // 实时行情明细
          _buildDetailCard('实时行情', [
            _detailRow('开盘', rt.open.toStringAsFixed(2)),
            _detailRow('最高', rt.high.toStringAsFixed(2)),
            _detailRow('最低', rt.low.toStringAsFixed(2)),
            _detailRow('昨收', rt.prevClose.toStringAsFixed(2)),
            _detailRow('成交量', _fmtVolume(rt.volume)),
            _detailRow('成交额', '${rt.amountWan.toStringAsFixed(0)}万'),
            _detailRow('量比', rt.volumeRatio.toStringAsFixed(2)),
            _detailRow('换手率', '${rt.turnoverRateMini.toStringAsFixed(2)}%'),
            _detailRow('市盈率', rt.pe.toStringAsFixed(2)),
          ]),
          const SizedBox(height: 6),

          // 量价概念
          if (a.volumeConcept != null) ...[
            _buildDetailCard('量价概念', [
              _detailRow('量比',
                  a.volumeConcept!.volumeRatio.toStringAsFixed(2)),
              _detailRow('评估', a.volumeConcept!.assessment),
              _detailRow('概念数',
                  '${a.volumeConcept!.conceptCount}个'),
              _detailRow('热度分',
                  a.volumeConcept!.heatScore.toStringAsFixed(1)),
              if (a.volumeConcept!.concepts.isNotEmpty)
                _detailRow('概念',
                    a.volumeConcept!.concepts.join('、')),
            ]),
            const SizedBox(height: 6),
          ],

          // 情绪信号
          if (a.sentimentSignal != null) ...[
            _buildDetailCard('情绪信号', [
              _detailRow('情绪分',
                  a.sentimentSignal!.score.toStringAsFixed(1)),
              _detailRow('情绪阶段', a.sentimentSignal!.phase),
              _detailRow(
                  '信号覆盖',
                  a.sentimentSignal!.inSignal
                      ? '✅ 有信号'
                      : '❌ 未覆盖'),
            ]),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // 打分明细表格（五维评分细分项）
  // ---------------------------------------------------------------

  Widget _buildScoreDetailTable(StockAnalysis a) {
    final fs = a.fiveDimScore!;
    final rt = a.realtime;
    final ma = a.maPosition;
    final vc = a.volumeConcept;
    final ss = a.sentimentSignal;

    return Container(
      padding: const EdgeInsets.all(AppTheme.pad),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '打分明细（含因子解读）',
            style: TextStyle(
              color: AppTheme.text,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // ===== 技术面 25% =====
          _dimHeader('技术面', fs.technical, 'MA排列+量比+换手率'),
          _factorRow('MA排列', ma?.arrangement ?? '--', _maExplain(ma?.arrangement)),
          _factorRow('量比', rt.volumeRatio.toStringAsFixed(2), _volumeExplain(rt.volumeRatio)),
          _factorRow('换手率', '${rt.turnoverRateMini.toStringAsFixed(2)}%', _turnoverExplain(rt.turnoverRateMini)),
          const SizedBox(height: 8),

          // ===== 情绪面 20% =====
          _dimHeader('情绪面', fs.sentiment, '情绪分+阶段+信号覆盖'),
          _factorRow('情绪分', (ss?.score ?? 0).toStringAsFixed(1), _sentiScoreExplain(ss?.score ?? 0)),
          _factorRow('情绪阶段', ss?.phase ?? '--', _phaseExplain(ss?.phase)),
          _factorRow('信号覆盖', ss?.inSignal == true ? '✅ 有信号' : '❌ 未覆盖',
              ss?.inSignal == true ? '处于选股信号覆盖范围，有买入逻辑支撑' : '不在当前选股范围内，需自行判断'),
          const SizedBox(height: 8),

          // ===== 题材面 20% =====
          _dimHeader('题材面', fs.concept, '概念数+热度'),
          _factorRow('概念数', vc != null ? '${vc.conceptCount}个' : '--', _conceptCountExplain(vc?.conceptCount)),
          _factorRow('热度分', vc != null ? vc.heatScore.toStringAsFixed(1) : '--', _heatExplain(vc?.heatScore)),
          if (vc != null && vc.concepts.isNotEmpty)
            _factorRow('概念', vc.concepts.take(3).join('、') + (vc.concepts.length > 3 ? '...' : ''), ''),
          const SizedBox(height: 8),

          // ===== 资金面 20% =====
          _dimHeader('资金面', fs.capital, '成交额+涨跌幅'),
          _factorRow('成交额', '${rt.amountWan.toStringAsFixed(0)}万', _amountExplain(rt.amountWan)),
          _factorRow('涨跌幅', '${rt.changePct.toStringAsFixed(2)}%', _pctExplain(rt.changePct)),
          const SizedBox(height: 8),

          // ===== 基本面 15% =====
          _dimHeader('基本面', fs.fundamental, '市盈率'),
          _factorRow('市盈率', rt.pe.toStringAsFixed(2), _peExplain(rt.pe)),
        ],
      ),
    );
  }

  // 维度头部 — 带评分徽章
  Widget _dimHeader(String label, double score, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.scoreColor(score).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$label ${score.toStringAsFixed(1)}',
              style: TextStyle(
                color: AppTheme.scoreColor(score),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(sub,
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  // 因子行 — 因子名 | 值 | 解释
  Widget _factorRow(String label, String value, String explain) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(label,
                    style: const TextStyle(
                        color: AppTheme.textDim,
                        fontSize: 12,
                        fontWeight: FontWeight.w400)),
              ),
              Text(value,
                  style: const TextStyle(
                      color: AppTheme.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          if (explain.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 56, top: 1),
              child: Text(explain,
                  style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // 因子解释函数
  // ============================================================

  String _maExplain(String? arr) {
    switch (arr) {
      case '多头排列':
        return '5/10/20日均线多头排列，股价趋势向上，技术面强势';
      case '空头排列':
        return '均线空头排列，股价趋势向下，技术面承压';
      case '震荡':
        return '均线粘合震荡，方向不明，需等待趋势确认';
      default:
        return '--';
    }
  }

  String _volumeExplain(double ratio) {
    if (ratio > 2) return '量比>2，放量明显，资金活跃参与度高';
    if (ratio > 1) return '量比正常，成交活跃度适中';
    if (ratio > 0.5) return '缩量运行，市场关注度偏低';
    return '极度缩量，交投冷清，流动性不足';
  }

  String _turnoverExplain(double rate) {
    if (rate > 10) return '换手极高，筹码交换充分，但也可能是出货信号';
    if (rate > 5) return '换手活跃，市场参与度高，资金关注';
    if (rate > 1) return '换手适中，正常波动范围';
    return '换手偏低，资金关注度不够';
  }

  String _sentiScoreExplain(double score) {
    if (score >= 7) return '市场情绪高涨，追涨意愿强，适合持股';
    if (score >= 4) return '情绪中性，多空平衡，适合高抛低吸';
    return '情绪低迷，市场谨慎，注意控制仓位';
  }

  String _phaseExplain(String? phase) {
    switch (phase) {
      case '冰点期':
        return '市场情绪冰点，是左侧布局的机会，控制仓位试错';
      case '复苏期':
        return '情绪回暖，资金开始试探性进场，可逐步加仓';
      case '均衡期':
        return '多空平衡，适合高抛低吸，仓位维持中性';
      case '高潮期':
        return '情绪亢奋，持股为主但不宜追高，注意风险';
      case '沸腾期':
        return '情绪极端过热，警惕见顶回落，建议减仓';
      case '退潮期':
        return '情绪回落，防御为主，仓位控制在低位';
      default:
        return '--';
    }
  }

  String _conceptCountExplain(int? count) {
    if (count == null) return '--';
    if (count >= 5) return '涉及概念多，多概念叠加增加爆发潜力';
    if (count >= 2) return '有明确板块属性，题材联动性较好';
    return '题材属性偏弱，独立行情概率大';
  }

  String _heatExplain(double? heat) {
    if (heat == null) return '--';
    if (heat >= 7) return '概念热度高，市场认可度好，资金扎堆';
    if (heat >= 4) return '中等热度，关注度一般，持续性待验证';
    return '热点不强，跟风意愿低，谨慎参与';
  }

  String _amountExplain(double wan) {
    if (wan > 50000) return '大额成交（>5亿），资金博弈激烈';
    if (wan > 10000) return '成交活跃（>1亿），主力关注度正常';
    if (wan > 3000) return '成交适中（>3000万），参与度一般';
    return '成交清淡，大资金关注度偏低';
  }

  String _pctExplain(double pct) {
    if (pct > 5) return '大涨，主力做多意愿强烈，趋势强劲';
    if (pct > 2) return '稳步上涨，多头占优，走势健康';
    if (pct > -2) return '窄幅震荡，方向未明，需等待';
    if (pct > -5) return '下跌调整，空头占优，注意风险';
    return '大跌，抛压明显，需警惕进一步下行';
  }

  String _peExplain(double pe) {
    if (pe < 0) return '企业亏损，基本面风险较高，需关注盈利拐点';
    if (pe < 15) return '估值偏低，有安全边际，适合价值持有';
    if (pe < 30) return '估值合理，处于正常范围';
    if (pe < 60) return '估值偏高，需成长性支撑，注意回调风险';
    return '估值极高，透支未来预期，风险较大';
  }

  // ---------------------------------------------------------------
  // 生命周期部分（持仓位置模式）
  // ---------------------------------------------------------------

  Widget _buildLifecycleSection(LifecyclePosition lc) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.pad),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Row(
        children: [
          // 左侧：生命周期徽章
          LifecycleBadge(phase: lc.phase, detail: lc.detail),
          const Spacer(),
          // 右侧：持仓位置指示
          _buildPositionIndicator(lc.phase),
        ],
      ),
    );
  }

  /// 持仓位置模式指示器 — 显示当前在哪个阶段
  Widget _buildPositionIndicator(String phase) {
    const phases = ['建仓区', '主升区', '出货区', '下跌区'];
    final currentIdx = phases.indexOf(phase);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(phases.length, (i) {
        final isCurrent = i == currentIdx;
        final isPast = currentIdx >= 0 && i < currentIdx;
        Color color;
        if (isCurrent) {
          color = AppTheme.lifecycleColor(phase);
        } else if (isPast) {
          color = AppTheme.lifecycleColor(phases[i]).withValues(alpha: 0.3);
        } else {
          color = AppTheme.textMuted.withValues(alpha: 0.2);
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: isCurrent ? 14 : 10,
          height: isCurrent ? 14 : 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------
  // 综合评级横幅
  // ---------------------------------------------------------------

  Widget _buildRatingBanner(StockAnalysis a) {
    final fs = a.fiveDimScore!;
    final rating = fs.rating; // 从 FiveDimScore 获取
    Color ratingColor;
    if (rating == '强烈推荐') {
      ratingColor = AppTheme.up;
    } else if (rating == '谨慎观察') {
      ratingColor = AppTheme.warning;
    } else {
      ratingColor = AppTheme.down;
    }

    final lc = a.lifecycle;

    return Container(
      padding: const EdgeInsets.all(AppTheme.pad),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: ratingColor.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('综合评分',
                  style: TextStyle(color: AppTheme.textDim, fontSize: 13)),
              const Spacer(),
              Text('决策评级',
                  style: TextStyle(color: AppTheme.textDim, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(fs.total.toStringAsFixed(1),
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ratingColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(rating,
                    style: TextStyle(
                        color: ratingColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (lc != null) ...[
            const SizedBox(height: 8),
            const Divider(color: AppTheme.textMuted, height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('生命周期',
                    style: TextStyle(color: AppTheme.textDim, fontSize: 12)),
                const SizedBox(width: 8),
                Text(lc.phase,
                    style: TextStyle(
                        color: AppTheme.lifecycleColor(lc.phase),
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                if (lc.detail != null && lc.detail.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text('(${lc.detail})',
                      style: TextStyle(
                          color: AppTheme.textMuted, fontSize: 12)),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // 信号因子评分表格
  // ---------------------------------------------------------------

  Widget _buildSignalFactorTable(Map<String, dynamic> details, int rank, double score) {
    // 提取数值因子，过滤掉非评分字段
    final factorEntries = <MapEntry<String, double>>[];
    const excludeKeys = {'consecutive', 'market_max_height', 'industry', 'amount', 'close', 'volume_ratio_raw', 'gap_raw', 'correction', 'correction_info', 'note'};

    for (final entry in details.entries) {
      if (excludeKeys.contains(entry.key)) continue;
      if (entry.value is num) {
        factorEntries.add(MapEntry(entry.key, (entry.value as num).toDouble()));
      }
    }

    // 因子中文映射
    String _factorLabel(String key) {
      const labelMap = {
        'height_score': '连板高度',
        'gap_score': '缺口强度',
        'sector_score': '板块共振',
        'heat_score': '概念热度',
        'sentiment_boost': '情绪加持',
        'recognition_score': '辨识度',
        'volume_score': '量能',
        'ladder_score': '梯队',
        'break_type_score': '突破类型',
        'nwave_score': 'N字波',
        'cgo_score': '筹码集中',
        'concept_diff_adj': '概念差异',
        'market_multiplier': '市场乘数',
      };
      return labelMap[key] ?? key;
    }

    Color _factorColor(double v) {
      if (v >= 0.7) return AppTheme.up;
      if (v >= 0.4) return AppTheme.warning;
      return AppTheme.down;
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.pad),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, size: 16, color: AppTheme.textDim),
              const SizedBox(width: 6),
              const Text('信号因子评分',
                  style: TextStyle(
                      color: AppTheme.text,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              if (rank > 0) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('#$rank 信号分 $score',
                      style: TextStyle(
                          color: AppTheme.info,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // 3列网格展示因子
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: factorEntries.length,
            itemBuilder: (_, i) {
              final f = factorEntries[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppTheme.cardAlt,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        _factorLabel(f.key),
                        style: const TextStyle(
                          color: AppTheme.textDim,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      f.value.toStringAsFixed(2),
                      style: TextStyle(
                        color: _factorColor(f.value),
                        fontSize: 12,
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

  // ---------------------------------------------------------------
  // 通用组件
  // ---------------------------------------------------------------

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          color: AppTheme.up,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.text,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.pad),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.up,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textDim,
                  fontSize: 13,
                  fontWeight: FontWeight.w400)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // 格式化辅助
  // ---------------------------------------------------------------

  String _fmtVal(double? v) {
    if (v == null) return '--';
    return v.toStringAsFixed(2);
  }

  String _fmtVolume(double v) {
    if (v >= 1e8) return '${(v / 1e8).toStringAsFixed(2)}亿';
    if (v >= 1e4) return '${(v / 1e4).toStringAsFixed(1)}万';
    return v.toStringAsFixed(0);
  }
}
