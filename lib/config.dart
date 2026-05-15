/// Sophia API 配置
class AppConfig {
  // 服务器地址 — 上线后改为正式域名
  // 开发期间用局域网IP或 10.0.2.2（安卓模拟器访问宿主机）
  static const String baseUrl = 'http://101.35.228.36';

  // API Token（跟服务器 SOPHIA_API_TOKEN 保持一致）
  static const String apiToken = 'dc9f57bfaea46ad4e4e1fa3d88caf345';

  // API路径
  static const String marketOverview = '/api/market/overview';
  static const String marketSentiment = '/api/market/sentiment';
  static const String marketIndexKline = '/api/market/index-kline';
  static const String dragonSelection = '/api/dragon/selection';
  static const String dragonSignalsHistory = '/api/dragon/signals-history';
  static const String dragonStrategies = '/api/dragon/strategies';
  static const String dragonFactors = '/api/dragon/factors';
  static const String stockSearch = '/api/stock/search';
  static const String stockKline = '/api/stock/kline';
  static const String stockRealtime = '/api/stock/realtime';
  static const String stockAnalysis = '/api/stock/analysis';
  static const String conceptsBatch = '/api/concepts/batch';
}
