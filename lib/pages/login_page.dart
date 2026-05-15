import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/app_theme.dart';

/// 登录 & 注册页面
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = '请输入用户名和密码');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await AuthService().login(username, password);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (!result.success) {
        _error = result.error;
      }
    });

    // 登录成功 → 返回上一页（由 main.dart 判断跳转到主页）
    if (result.success) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _doRegister() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirm = _confirmPwdCtrl.text.trim();

    if (username.length < 2) {
      setState(() => _error = '用户名至少 2 个字符');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = '密码至少 6 个字符');
      return;
    }
    if (password != confirm) {
      setState(() => _error = '两次密码不一致');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await AuthService().register(username, password);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (!result.success) {
        _error = result.error;
      }
    });

    if (result.success) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.up.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: AppTheme.up,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '骚 飞',
                  style: TextStyle(
                    color: AppTheme.text,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'A股量化交易助手',
                  style: TextStyle(color: AppTheme.textDim, fontSize: 14),
                ),
                const SizedBox(height: 32),

                // TabBar: 登录 / 注册
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppTheme.up.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: AppTheme.up,
                    unselectedLabelColor: AppTheme.textDim,
                    tabs: const [
                      Tab(text: '登录'),
                      Tab(text: '注册'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 输入框
                TextField(
                  controller: _usernameCtrl,
                  style: const TextStyle(color: AppTheme.text),
                  decoration: _inputDecoration('用户名', Icons.person_outline),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  style: const TextStyle(color: AppTheme.text),
                  decoration: _inputDecoration('密码', Icons.lock_outline),
                ),

                // 注册页多一个确认密码
                if (_tabController.index == 1) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPwdCtrl,
                    obscureText: true,
                    style: const TextStyle(color: AppTheme.text),
                    decoration:
                        _inputDecoration('确认密码', Icons.lock_outline),
                  ),
                ],

                const SizedBox(height: 8),

                // 错误提示
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.down, fontSize: 13),
                    ),
                  ),

                const SizedBox(height: 16),

                // 登录/注册按钮
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (_tabController.index == 0 ? _doLogin : _doRegister),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.up,
                      disabledBackgroundColor: AppTheme.up.withOpacity(0.3),
                      foregroundColor: AppTheme.bg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.bg,
                            ),
                          )
                        : Text(
                            _tabController.index == 0 ? '登 录' : '注 册',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textDim),
      prefixIcon: Icon(icon, color: AppTheme.textDim, size: 20),
      filled: true,
      fillColor: AppTheme.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.up, width: 1),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
