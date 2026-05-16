import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/app_theme.dart';

/// 格式化金额（保留两位小数，加逗号）
String _formatPrice(dynamic val) {
  final v = (val is num) ? val.toDouble() : double.tryParse('$val') ?? 0.0;
  final neg = v < 0;
  final abs = v.abs();
  final parts = abs.toStringAsFixed(2).split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  return '${neg ? '-' : ''}${buf.toString()}.${parts[1]}';
}

/// 持仓页
class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final _api = ApiService();
  List<Map<String, dynamic>> _positions = [];
  Map<String, dynamic>? _overview;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.getPortfolioOverview(),
        _api.getPortfolio(),
      ], eagerError: false);
      if (!mounted) return;
      setState(() {
        _overview = results[0] as Map<String, dynamic>?;
        _positions =
            (results[1] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('加载持仓数据失败')),
      );
    }
  }

  Future<void> _refresh() => _loadData();

  /// 打开添加持仓弹窗
  void _showAddDialog() {
    _showEditDialog(null);
  }

  /// 打开编辑/删除弹窗
  void _showEditDialog(Map<String, dynamic>? position) {
    final isEditing = position != null;
    final symbolCtrl = TextEditingController(
        text: position?['symbol'] as String? ?? '');
    final sharesCtrl = TextEditingController(
        text: position?['shares']?.toString() ?? '');
    final costCtrl = TextEditingController(
        text: position?['cost_price']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.card,
            title: Text(
              isEditing ? '编辑持仓' : '添加持仓',
              style: const TextStyle(color: AppTheme.text),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: symbolCtrl,
                    enabled: !isEditing,
                    style: const TextStyle(color: AppTheme.text),
                    decoration: const InputDecoration(
                      labelText: '股票代码',
                      labelStyle: TextStyle(color: AppTheme.textDim),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '请输入股票代码' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: sharesCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: AppTheme.text),
                    decoration: const InputDecoration(
                      labelText: '持股数',
                      labelStyle: TextStyle(color: AppTheme.textDim),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return '请输入股数';
                      final n = double.tryParse(v.trim());
                      if (n == null || n <= 0) return '请输入有效股数';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: costCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: AppTheme.text),
                    decoration: const InputDecoration(
                      labelText: '成本价',
                      labelStyle: TextStyle(color: AppTheme.textDim),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return '请输入成本价';
                      final n = double.tryParse(v.trim());
                      if (n == null || n <= 0) return '请输入有效价格';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              if (isEditing)
                TextButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setDialogState(() => saving = true);
                          try {
                            await _api.deletePosition(position['id'] as int);
                            if (!ctx.mounted) return;
                            Navigator.of(ctx).pop();
                            _refresh();
                          } catch (_) {
                            if (!ctx.mounted) return;
                            setDialogState(() => saving = false);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('删除失败')),
                            );
                          }
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.up,
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('删除'),
                ),
              TextButton(
                onPressed: saving ? null : () => Navigator.of(ctx).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textDim,
                ),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => saving = true);
                        try {
                          final symbol = symbolCtrl.text.trim();
                          final shares =
                              double.parse(sharesCtrl.text.trim());
                          final cost = double.parse(costCtrl.text.trim());
                          if (isEditing) {
                            await _api.updatePosition(
                                position['id'] as int, shares, cost);
                          } else {
                            await _api.addPosition(symbol, shares, cost);
                          }
                          if (!ctx.mounted) return;
                          Navigator.of(ctx).pop();
                          _refresh();
                        } catch (_) {
                          if (!ctx.mounted) return;
                          setDialogState(() => saving = false);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                  isEditing ? '更新失败' : '添加失败'),
                            ),
                          );
                        }
                      },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.down,
                ),
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('确认'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.up),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppTheme.up,
      backgroundColor: AppTheme.card,
      child: Column(
        children: [
          // 总览卡片
          _buildOverviewCard(),
          // 持仓列表
          Expanded(child: _buildPositionList()),
          // 底部添加按钮
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    final totalValue = (_overview?['total_value'] as num?)?.toDouble() ?? 0;
    final totalPnl = (_overview?['total_pnl'] as num?)?.toDouble() ?? 0;
    final totalPnlPercent =
        (_overview?['total_pnl_percent'] as num?)?.toDouble() ?? 0;
    final isProfit = totalPnl >= 0;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.card.withOpacity(0.9),
            AppTheme.cardAlt,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isProfit
              ? AppTheme.down.withOpacity(0.3)
              : AppTheme.up.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '持仓总览',
            style: TextStyle(
              color: AppTheme.textDim,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '总市值',
                      style: TextStyle(
                          color: AppTheme.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¥${_formatPrice(totalValue)}',
                      style: const TextStyle(
                        color: AppTheme.text,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '总盈亏',
                    style:
                        TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isProfit ? '+' : ''}¥${_formatPrice(totalPnl)}',
                    style: TextStyle(
                      color: isProfit ? AppTheme.down : AppTheme.up,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${totalPnlPercent >= 0 ? '+' : ''}${_formatPrice(totalPnlPercent)}%',
                    style: TextStyle(
                      color: isProfit ? AppTheme.down : AppTheme.up,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPositionList() {
    if (_positions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                color: AppTheme.textDim.withOpacity(0.3), size: 64),
            const SizedBox(height: 16),
            const Text(
              '暂无持仓',
              style: TextStyle(color: AppTheme.textDim, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '点击下方按钮添加持仓记录',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _positions.length,
      itemBuilder: (context, index) {
        final pos = _positions[index];
        return _buildPositionCard(pos);
      },
    );
  }

  Widget _buildPositionCard(Map<String, dynamic> pos) {
    final symbol = pos['symbol'] as String? ?? '';
    final name = pos['name'] as String? ?? symbol;
    final shares = (pos['shares'] as num?)?.toDouble() ?? 0;
    final costPrice = (pos['cost_price'] as num?)?.toDouble() ?? 0;
    final currentPrice = (pos['current_price'] as num?)?.toDouble() ?? costPrice;
    final pnl = (pos['pnl'] as num?)?.toDouble() ??
        (currentPrice - costPrice) * shares;
    final pnlPercent = (pos['pnl_percent'] as num?)?.toDouble() ??
        (costPrice > 0 ? ((currentPrice - costPrice) / costPrice * 100) : 0);
    final isProfit = pnl >= 0;

    return GestureDetector(
      onTap: () => _showEditDialog(pos),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.textMuted.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            // 股票信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppTheme.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    symbol,
                    style: const TextStyle(
                      color: AppTheme.textDim,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_formatPrice(shares)}股 · 成本${_formatPrice(costPrice)}',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // 盈亏信息
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '现价 ${_formatPrice(currentPrice)}',
                  style: const TextStyle(
                    color: AppTheme.textDim,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${isProfit ? '+' : ''}¥${_formatPrice(pnl)}',
                  style: TextStyle(
                    color: isProfit ? AppTheme.down : AppTheme.up,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${pnlPercent >= 0 ? '+' : ''}${_formatPrice(pnlPercent)}%',
                  style: TextStyle(
                    color: isProfit ? AppTheme.down : AppTheme.up,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border(
          top: BorderSide(color: AppTheme.textMuted.withOpacity(0.15)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showAddDialog,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('添加持仓'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.down,
            foregroundColor: AppTheme.text,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}
