import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

/// API调用服务 — 封装所有后端接口
class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  final _headers = {
    'X-API-Key': AppConfig.apiToken,
    'Content-Type': 'application/json',
  };

  /// 通用GET请求
  Future<Map<String, dynamic>> _get(String path,
      {Map<String, String>? params}) async {
    final uri = Uri.parse('${AppConfig.baseUrl}$path')
        .replace(queryParameters: params);
    final resp = await http.get(uri, headers: _headers).timeout(
      const Duration(seconds: 10),
    );
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['error'] ?? '请求失败');
    }
    return body['data'] as Map<String, dynamic>;
  }

  // ============================================================
  // 复盘
  // ============================================================

  /// 市场总览：指数+情绪+涨跌统计+涨停TOP6
  Future<Map<String, dynamic>> getMarketOverview() =>
      _get(AppConfig.marketOverview);

  /// 情绪指数历史
  Future<Map<String, dynamic>> getMarketSentiment() =>
      _get(AppConfig.marketSentiment);

  /// 指数K线（支持 symbol 切换上证/深证/创业板）
  Future<Map<String, dynamic>> getIndexKline({int days = 120, String? symbol}) {
    final params = <String, String>{'days': '$days'};
    if (symbol != null) params['symbol'] = symbol;
    return _get(AppConfig.marketIndexKline, params: params);
  }

  // ============================================================
  // 龙头选股
  // ============================================================

  /// 最新龙头信号+候选股
  Future<Map<String, dynamic>> getDragonSelection() =>
      _get(AppConfig.dragonSelection);

  /// 历史信号列表
  Future<Map<String, dynamic>> getDragonSignalsHistory({int limit = 10}) =>
      _get(AppConfig.dragonSignalsHistory, params: {'limit': '$limit'});

  /// 龙头选股策略列表
  Future<Map<String, dynamic>> getDragonStrategies() =>
      _get(AppConfig.dragonStrategies);

  /// 指定策略的龙头选股
  Future<Map<String, dynamic>> getDragonSelectionByStrategy(String strategy) =>
      _get(AppConfig.dragonSelection, params: {'strategy': strategy});

  /// 个股因子详情
  Future<Map<String, dynamic>> getDragonFactors(String symbol) =>
      _get('${AppConfig.dragonFactors}/$symbol');

  // ============================================================
  // 个股查询
  // ============================================================

  /// 搜索股票
  Future<Map<String, dynamic>> searchStock(String query) =>
      _get(AppConfig.stockSearch, params: {'q': query});

  /// 个股K线
  Future<Map<String, dynamic>> getStockKline(String symbol,
      {int days = 60}) =>
      _get('${AppConfig.stockKline}/$symbol', params: {'days': '$days'});

  /// 个股实时行情
  Future<Map<String, dynamic>> getStockRealtime(String symbol) =>
      _get('${AppConfig.stockRealtime}/$symbol');

  /// 个股综合分析
  Future<Map<String, dynamic>> getStockAnalysis(String symbol) =>
      _get('${AppConfig.stockAnalysis}/$symbol');

  /// 批量概念查询
  Future<Map<String, dynamic>> getConceptsBatch(List<String> symbols) =>
      _get(AppConfig.conceptsBatch,
          params: {'symbols': symbols.join(',')});
}
