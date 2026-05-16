import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 缓存结果
class CacheResult {
  final dynamic data;
  final bool isStale;

  const CacheResult(this.data, this.isStale);
}

/// 本地缓存服务 — 基于 SharedPreferences
/// 存 JSON 字符串 + last_update_ts 实现 TTL 过期
class CacheService {
  static final CacheService _instance = CacheService._();
  factory CacheService() => _instance;
  CacheService._();

  static const String _prefix = 'cache_v1:';

  String _key(String key) => '$_prefix$key';
  String _tsKey(String key) => '${_key(key)}:ts';

  /// 存入缓存，带 TTL
  Future<void> set(String key, dynamic data, Duration ttl) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setString(_key(key), jsonEncode(data));
    await prefs.setInt(_tsKey(key), now + ttl.inMilliseconds);
  }

  /// 读取缓存 — 返回 (数据, 是否过期)
  /// 未过期 → (data, false)
  /// 已过期 → (旧数据, true)  供调用方静默刷新
  Future<CacheResult?> getWithStale(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(key));
    if (raw == null) return null;

    final expTs = prefs.getInt(_tsKey(key)) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final isStale = now >= expTs;

    try {
      final data = jsonDecode(raw);
      return CacheResult(data, isStale);
    } catch (_) {
      return null;
    }
  }

  /// 清除单个缓存
  Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(key));
    await prefs.remove(_tsKey(key));
  }

  /// 清除所有缓存
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final k in keys) {
      if (k.startsWith(_prefix)) {
        await prefs.remove(k);
      }
    }
  }
}
