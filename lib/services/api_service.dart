import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'auth_service.dart';

/// API调用服务 — 封装所有后端接口
/// 使用 AuthService 动态获取 Token
class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  /// 获取当前认证头
  Map<String, String> get _headers => AuthService().headers;

  /// 通用GET请求
  Future<Map<String, dynamic>> _get(String path,
      {Map<String, String>? params}) async {
    final uri = Uri.parse('${AppConfig.baseUrl}$path')
        .replace(queryParameters: params);

    final resp = await http.get(uri, headers: _headers).timeout(
      const Duration(seconds: 10),
    );

    // 处理认证错误
    if (resp.statusCode == 401) {
      throw AuthException('登录已过期，请重新登录');
    }
    if (resp.statusCode == 403) {
      throw AuthException('权限不足，需要 VIP 权限');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['error'] ?? '请求失败');
    }
    return body['data'] as Map<String, dynamic>;
  }

  // ============================================================
  // 复盘（Basic 权限）
  // ============================================================

  Future<Map<String, dynamic>> getMarketOverview() =>
      _get(AppConfig.marketOverview);

  Future<Map<String, dynamic>> getMarketSentiment() =>
      _get(AppConfig.marketSentiment);

  Future<Map<String, dynamic>> getIndexKline({int days = 120, String? symbol}) {
    final params = <String, String>{'days': '$days'};
    if (symbol != null) params['symbol'] = symbol;
    return _get(AppConfig.marketIndexKline, params: params);
  }

  // ============================================================
  // 龙头选股（VIP 权限）
  // ============================================================

  Future<Map<String, dynamic>> getDragonSelection() =>
      _get(AppConfig.dragonSelection);

  Future<Map<String, dynamic>> getDragonSignalsHistory({int limit = 10}) =>
      _get(AppConfig.dragonSignalsHistory, params: {'limit': '$limit'});

  Future<Map<String, dynamic>> getDragonStrategies() =>
      _get(AppConfig.dragonStrategies);

  Future<Map<String, dynamic>> getDragonSelectionByStrategy(
          String strategy) =>
      _get(AppConfig.dragonSelection, params: {'strategy': strategy});

  Future<Map<String, dynamic>> getDragonFactors(String symbol) =>
      _get('${AppConfig.dragonFactors}/$symbol');

  // ============================================================
  // 个股查询（VIP 权限）
  // ============================================================

  Future<Map<String, dynamic>> searchStock(String query) =>
      _get(AppConfig.stockSearch, params: {'q': query});

  Future<Map<String, dynamic>> getStockKline(String symbol,
      {int days = 60}) =>
      _get('${AppConfig.stockKline}/$symbol', params: {'days': '$days'});

  Future<Map<String, dynamic>> getStockRealtime(String symbol) =>
      _get('${AppConfig.stockRealtime}/$symbol');

  Future<Map<String, dynamic>> getStockAnalysis(String symbol) =>
      _get('${AppConfig.stockAnalysis}/$symbol');

  Future<Map<String, dynamic>> getConceptsBatch(List<String> symbols) =>
      _get(AppConfig.conceptsBatch,
          params: {'symbols': symbols.join(',')});
}

/// 认证异常 — 由 ApiService 抛出，页面层捕获后显示对应 UI
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
