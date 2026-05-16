import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'widgets/app_theme.dart';
import 'pages/review_page.dart';
import 'pages/dragon_page.dart';
import 'pages/stock_query_page.dart';
import 'pages/chat_page.dart';
import 'pages/portfolio_page.dart';
import 'pages/login_page.dart';
import 'pages/profile_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SophiaApp());
}

class SophiaApp extends StatelessWidget {
  const SophiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '骚飞',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AuthGate(),
    );
  }
}

/// 认证网关 — 检查登录状态，决定显示哪个页面
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    await AuthService().restoreSession();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    // 加载中 → 闪屏
    if (auth.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.up.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: AppTheme.up,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '骚飞',
                style: TextStyle(
                  color: AppTheme.text,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.up,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 未登录 → 登录页
    if (!auth.isLoggedIn) {
      return Scaffold(
        backgroundColor: AppTheme.bg,
        body: LoginPage(
          key: ValueKey('login'),
        ),
      );
    }

    // 已登录 → 主页
    return const HomePage();
  }
}

/// 主页 — 5 个 Tab
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!_auth.isLoggedIn && mounted) {
      // 退出登录后回到登录页
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    }
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVip = _auth.isVip;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        appBar: AppBar(
          backgroundColor: AppTheme.bg,
          title: Row(
            children: [
              const Text('骚飞'),
              if (isVip)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.up.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'VIP',
                    style: TextStyle(
                      color: AppTheme.up,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            // 个人中心入口
            IconButton(
              icon: const Icon(Icons.person_outline, color: AppTheme.textDim),
              onPressed: _openProfile,
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppTheme.up,
            labelColor: AppTheme.up,
            unselectedLabelColor: AppTheme.textDim,
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.bar_chart), text: '复盘'),
              Tab(icon: Icon(Icons.trending_up), text: '龙头选股'),
              Tab(icon: Icon(Icons.shopping_cart), text: '买卖决策'),
              Tab(icon: Icon(Icons.chat), text: '对话'),
              Tab(icon: Icon(Icons.account_balance_wallet), text: '持仓'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ReviewPage(),
            isVip
                ? DragonPage()
                : _VipLockPage(
                    icon: Icons.trending_up,
                    title: '龙头选股',
                    description: '7大策略 × 情绪周期\n智能龙头识别与买卖建议',
                  ),
            isVip
                ? StockQueryPage()
                : _VipLockPage(
                    icon: Icons.shopping_cart,
                    title: '买卖决策',
                    description: '个股深度分析 × 五维评分\n实时买卖策略与退出规则',
                  ),
            isVip
                ? const ChatPage()
                : _VipLockPage(
                    icon: Icons.chat,
                    title: '对话',
                    description: '跟Alex聊个股和市场',
                  ),
            isVip
                ? const PortfolioPage()
                : _VipLockPage(
                    icon: Icons.account_balance_wallet,
                    title: '持仓',
                    description: '管理交易记录与盈亏',
                  ),
          ],
        ),
      ),
    );
  }
}

/// VIP 专享功能的锁页
class _VipLockPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _VipLockPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.textDim.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.lock_outline,
                color: AppTheme.textDim,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'VIP 专享功能',
              style: const TextStyle(
                color: AppTheme.text,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.up,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textDim,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.textDim.withOpacity(0.2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline,
                      color: AppTheme.textDim, size: 16),
                  SizedBox(width: 8),
                  Text(
                    '联系管理员开通 VIP',
                    style: TextStyle(color: AppTheme.textDim, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
