import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/app_theme.dart';

/// 用户资料页（从首页 AppBar 右上角进入）
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: const Text('个人中心'),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 头像
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: auth.isVip
                    ? AppTheme.up.withOpacity(0.2)
                    : AppTheme.textDim.withOpacity(0.2),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Center(
                child: Text(
                  auth.username.isNotEmpty
                      ? auth.username[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: auth.isVip ? AppTheme.up : AppTheme.textDim,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user?['username'] as String? ?? '',
              style: const TextStyle(
                color: AppTheme.text,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),

            // 角色标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: auth.isVip
                    ? AppTheme.up.withOpacity(0.15)
                    : AppTheme.textDim.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                auth.isVip ? 'VIP 用户' : 'Basic 用户',
                style: TextStyle(
                  color: auth.isVip ? AppTheme.up : AppTheme.textDim,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // VIP 过期时间
            if (auth.isVip && user?['vip_expires_at'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '有效期至: ${user!['vip_expires_at']}',
                  style: const TextStyle(color: AppTheme.textDim, fontSize: 12),
                ),
              ),

            const SizedBox(height: 32),

            // 功能列表卡片
            Container(
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _infoRow('用户名', user?['username'] as String? ?? ''),
                  const Divider(color: AppTheme.bg, height: 1),
                  _infoRow('用户ID', '#${user?['id'] ?? '?'}'),
                  const Divider(color: AppTheme.bg, height: 1),
                  _infoRow('注册时间',
                      (user?['created_at'] as String? ?? '').length >= 10 ? (user!['created_at'] as String).substring(0, 10) : ''),
                  const Divider(color: AppTheme.bg, height: 1),
                  _infoRow(
                    '权限等级',
                    auth.isAdmin
                        ? '管理员'
                        : auth.isVip
                            ? 'VIP'
                            : '基础版',
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 退出登录
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout, color: AppTheme.down),
                label: const Text(
                  '退出登录',
                  style: TextStyle(color: AppTheme.down, fontSize: 15),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.down.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textDim)),
          Text(value, style: const TextStyle(color: AppTheme.text)),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('退出登录', style: TextStyle(color: AppTheme.text)),
        content: const Text('确定要退出登录吗？',
            style: TextStyle(color: AppTheme.textDim)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确定', style: TextStyle(color: AppTheme.down)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService().logout();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }
}
