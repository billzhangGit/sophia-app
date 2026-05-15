import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

/// 认证服务 — 管理用户登录/注册/Token持久化
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  // ---- 状态 ----
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  // ---- Getters ----
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _token != null && _user != null;
  bool get isLoading => _isLoading;
  String get role => _user?['role'] as String? ?? 'basic';
  bool get isVip => role == 'vip' || role == 'admin';
  bool get isAdmin => role == 'admin';
  String get username => _user?['username'] as String? ?? '';

  /// 本地存储 Keys
  static const _kToken = 'auth_token';
  static const _kUser = 'auth_user';

  /// App 启动时从本地恢复登录状态
  Future<void> restoreSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_kToken);
      final savedUser = prefs.getString(_kUser);

      if (savedToken != null && savedUser != null) {
        _token = savedToken;
        _user = jsonDecode(savedUser) as Map<String, dynamic>;

        // 验证 Token 是否仍然有效
        final valid = await _verifyToken();
        if (!valid) {
          await _clearSession();
        }
      }
    } catch (e) {
      debugPrint('恢复会话失败: $e');
      await _clearSession();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 验证当前 Token 是否有效
  Future<bool> _verifyToken() async {
    if (_token == null) return false;
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}${AppConfig.authMe}');
      final resp = await http.get(
        uri,
        headers: _buildHeaders(),
      ).timeout(const Duration(seconds: 5));

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body['success'] == true) {
          _user = body['data']['user'] as Map<String, dynamic>;
          await _saveSession();
          return true;
        }
      }
      return false;
    } catch (e) {
      // 网络错误时不销毁 session，允许离线使用
      debugPrint('Token 验证网络错误: $e');
      return _token != null; // 有本地 token 就认为有效
    }
  }

  /// 登录
  Future<AuthResult> login(String username, String password) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}${AppConfig.authLogin}');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(resp.body);

      if (resp.statusCode == 200 && body['success'] == true) {
        _token = body['data']['token'] as String;
        _user = body['data']['user'] as Map<String, dynamic>;
        await _saveSession();
        notifyListeners();
        return AuthResult.ok();
      }

      if (resp.statusCode == 401) {
        return AuthResult.error('用户名或密码错误');
      }
      if (resp.statusCode == 403) {
        return AuthResult.error('账号已被禁用');
      }

      final detail = body['detail'] ?? body['error'] ?? '登录失败';
      return AuthResult.error(detail.toString());
    } catch (e) {
      return AuthResult.error('网络错误，请检查连接');
    }
  }

  /// 注册
  Future<AuthResult> register(String username, String password) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}${AppConfig.authRegister}');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(resp.body);

      if (resp.statusCode == 200 && body['success'] == true) {
        _token = body['data']['token'] as String;
        _user = body['data']['user'] as Map<String, dynamic>;
        await _saveSession();
        notifyListeners();
        return AuthResult.ok();
      }

      if (resp.statusCode == 409) {
        return AuthResult.error('用户名已存在');
      }

      final detail = body['detail'] ?? body['error'] ?? '注册失败';
      return AuthResult.error(detail.toString());
    } catch (e) {
      return AuthResult.error('网络错误，请检查连接');
    }
  }

  /// 退出登录
  Future<void> logout() async {
    await _clearSession();
    notifyListeners();
  }

  /// 保存 session 到本地
  Future<void> _saveSession() async {
    if (_token == null || _user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, _token!);
    await prefs.setString(_kUser, jsonEncode(_user));
  }

  /// 清除本地 session
  Future<void> _clearSession() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUser);
  }

  /// 构建请求头（用于 ApiService）
  Map<String, String> get headers {
    final h = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }

  Map<String, String> _buildHeaders() {
    final h = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }
}

/// 认证操作结果
class AuthResult {
  final bool success;
  final String? error;
  AuthResult._(this.success, this.error);

  factory AuthResult.ok() => AuthResult._(true, null);
  factory AuthResult.error(String msg) => AuthResult._(false, msg);
}
