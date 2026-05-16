import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'auth_service.dart';
import 'cache_service.dart';

/// API调用服务 — 封装所有后端接口
/// 使用 AuthService 动态获取 Token
class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  /// 获取当前认证头
  Map<String, String> get _headers => AuthService().headers;

  // ============================================================
  // 缓存辅助
  // ============================================================

  /// 带缓存的GET请求
  /// cacheTtl 不为 null 时启用缓存
  Future<Map<String, dynamic>> _get(String path,
      {Map<String, String>? params, Duration? cacheTtl}) async {
    final cacheKey = '$path?${params?.toString() ?? ''}';

    if (cacheTtl != null) {
      final cached = await CacheService().getWithStale(cacheKey);
      if (cached != null) {
        if (!cached.isStale) {
          return cached.data as Map<String, dynamic>;
        }
        // 过期数据：后台静默刷新，返回旧数据
        _refreshCache(cacheKey, path, params);
        return cached.data as Map<String, dynamic>;
      }
    }

    return _httpGet(path, params: params);
  }

  /// 后台刷新缓存
  void _refreshCache(String cacheKey, String path,
      Map<String, String>? params) {
    _httpGet(path, params: params).then((data) {
      CacheService().set(cacheKey, data, const Duration(seconds: 30));
    }).catchError((_) {});
  }

  /// 实际 HTTP GET
  Future<Map<String, dynamic>> _httpGet(String path,
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

  /// 通用 POST
  Future<Map<String, dynamic>> _post(String path,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${AppConfig.baseUrl}$path');
    final resp = await http
        .post(uri, headers: _headers, body: body != null ? jsonEncode(body) : null)
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode == 401) {
      throw AuthException('登录已过期，请重新登录');
    }
    if (resp.statusCode == 403) {
      throw AuthException('权限不足，需要 VIP 权限');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    if (json['success'] != true) {
      throw Exception(json['error'] ?? '请求失败');
    }
    return json['data'] as Map<String, dynamic>;
  }

  /// 通用 DELETE
  Future<Map<String, dynamic>> _delete(String path) async {
    final uri = Uri.parse('${AppConfig.baseUrl}$path');
    final resp = await http
        .delete(uri, headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode == 401) {
      throw AuthException('登录已过期，请重新登录');
    }
    if (resp.statusCode == 403) {
      throw AuthException('权限不足，需要 VIP 权限');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    if (json['success'] != true) {
      throw Exception(json['error'] ?? '请求失败');
    }
    return json['data'] as Map<String, dynamic>;
  }

  // ============================================================
  // 复盘（Basic 权限）
  // ============================================================

  Future<Map<String, dynamic>> getMarketOverview(
          {Duration? cacheTtl}) =>
      _get(AppConfig.marketOverview,
          cacheTtl: cacheTtl ?? const Duration(seconds: 30));

  Future<Map<String, dynamic>> getMarketSentiment(
          {Duration? cacheTtl}) =>
      _get(AppConfig.marketSentiment,
          cacheTtl: cacheTtl ?? const Duration(seconds: 30));

  Future<Map<String, dynamic>> getIndexKline(
      {int days = 120, String? symbol, Duration? cacheTtl}) {
    final params = <String, String>{'days': '$days'};
    if (symbol != null) params['symbol'] = symbol;
    return _get(AppConfig.marketIndexKline,
        params: params, cacheTtl: cacheTtl);
  }

  // ============================================================
  // 龙头选股（VIP 权限）
  // ============================================================

  Future<Map<String, dynamic>> getDragonSelection(
          {Duration? cacheTtl}) =>
      _get(AppConfig.dragonSelection,
          cacheTtl: cacheTtl ?? const Duration(seconds: 30));

  Future<Map<String, dynamic>> getDragonSignalsHistory(
      {int limit = 10, Duration? cacheTtl}) =>
      _get(AppConfig.dragonSignalsHistory,
          params: {'limit': '$limit'},
          cacheTtl: cacheTtl);

  Future<Map<String, dynamic>> getDragonStrategies(
          {Duration? cacheTtl}) =>
      _get(AppConfig.dragonStrategies,
          cacheTtl: cacheTtl ?? const Duration(seconds: 60));

  Future<Map<String, dynamic>> getDragonSelectionByStrategy(
      String strategy, {Duration? cacheTtl}) =>
      _get(AppConfig.dragonSelection,
          params: {'strategy': strategy}, cacheTtl: cacheTtl);

  Future<Map<String, dynamic>> getDragonFactors(String symbol,
          {Duration? cacheTtl}) =>
      _get('${AppConfig.dragonFactors}/$symbol', cacheTtl: cacheTtl);

  // ============================================================
  // 个股查询（VIP 权限）
  // ============================================================

  Future<Map<String, dynamic>> searchStock(String query,
          {Duration? cacheTtl}) =>
      _get(AppConfig.stockSearch,
          params: {'q': query}, cacheTtl: cacheTtl);

  Future<Map<String, dynamic>> getStockKline(String symbol,
      {int days = 60, Duration? cacheTtl}) =>
      _get('${AppConfig.stockKline}/$symbol',
          params: {'days': '$days'}, cacheTtl: cacheTtl);

  Future<Map<String, dynamic>> getStockRealtime(String symbol,
          {Duration? cacheTtl}) =>
      _get('${AppConfig.stockRealtime}/$symbol', cacheTtl: cacheTtl);

  Future<Map<String, dynamic>> getStockAnalysis(String symbol,
          {Duration? cacheTtl}) =>
      _get('${AppConfig.stockAnalysis}/$symbol', cacheTtl: cacheTtl);

  Future<Map<String, dynamic>> getConceptsBatch(List<String> symbols,
          {Duration? cacheTtl}) =>
      _get(AppConfig.conceptsBatch,
          params: {'symbols': symbols.join(',')}, cacheTtl: cacheTtl);

  // ============================================================
  // 对话（VIP 权限）
  // ============================================================

  /// SSE 流式对话请求
  Future<http.StreamedResponse> chatAsk(String message,
      {int? sessionId}) async {
    final uri = Uri.parse('${AppConfig.baseUrl}${AppConfig.chatAsk}');
    final request = http.StreamedRequest('POST', uri);
    request.headers.addAll(AuthService().headers);
    request.headers['Accept'] = 'text/event-stream';

    final body = <String, dynamic>{'message': message};
    if (sessionId != null) body['session_id'] = sessionId;
    request.sink.add(utf8.encode(jsonEncode(body)));
    await request.sink.close();

    return http.Client().send(request);
  }

  /// 获取会话列表
  Future<List<dynamic>> getChatSessions() async {
    final data = await _get(AppConfig.chatSessions);
    return data['sessions'] as List<dynamic>? ?? [];
  }

  /// 获取会话消息列表
  Future<List<dynamic>> getChatMessages(int sessionId) async {
    final data = await _get('${AppConfig.chatMessages}/$sessionId/messages');
    return data['messages'] as List<dynamic>? ?? [];
  }

  /// 创建新会话
  Future<Map<String, dynamic>> createChatSession({String? title}) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    return _post(AppConfig.chatCreateSession, body: body);
  }

  // ============================================================
  // 持仓管理（VIP 权限）
  // ============================================================

  /// 获取持仓列表
  Future<List<dynamic>> getPortfolio() async {
    final data = await _get(AppConfig.portfolioList);
    return data['positions'] as List<dynamic>? ?? [];
  }

  /// 添加持仓
  Future<Map<String, dynamic>> addPosition(
      String symbol, double shares, double costPrice) async {
    return _post(AppConfig.portfolioAdd, body: {
      'symbol': symbol,
      'shares': shares,
      'cost_price': costPrice,
    });
  }

  /// 更新持仓
  Future<Map<String, dynamic>> updatePosition(
      int id, double shares, double costPrice) async {
    return _post('${AppConfig.portfolioUpdate}/$id', body: {
      'shares': shares,
      'cost_price': costPrice,
    });
  }

  /// 删除持仓
  Future<Map<String, dynamic>> deletePosition(int id) async {
    return _delete('${AppConfig.portfolioDelete}/$id');
  }

  /// 获取单个持仓盈亏数据
  Future<Map<String, dynamic>> getPortfolioPerformance(int id) async {
    return _get('${AppConfig.portfolioPerformance}/$id/performance');
  }

  /// 获取持仓总览（总市值、总盈亏）
  Future<Map<String, dynamic>> getPortfolioOverview() async {
    return _get(AppConfig.portfolioOverview);
  }
}

/// 认证异常 — 由 ApiService 抛出，页面层捕获后显示对应 UI
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
