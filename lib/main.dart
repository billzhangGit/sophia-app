import 'package:flutter/material.dart';
import 'widgets/app_theme.dart';
import 'pages/review_page.dart';
import 'pages/dragon_page.dart';
import 'pages/stock_query_page.dart';

void main() {
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
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('骚飞'),
          bottom: const TabBar(
            indicatorColor: AppTheme.up,
            labelColor: AppTheme.up,
            unselectedLabelColor: AppTheme.textDim,
            tabs: [
              Tab(icon: Icon(Icons.bar_chart), text: '复盘'),
              Tab(icon: Icon(Icons.trending_up), text: '龙头选股'),
              Tab(icon: Icon(Icons.shopping_cart), text: '买卖决策'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ReviewPage(),
            DragonPage(),
            StockQueryPage(),
          ],
        ),
      ),
    );
  }
}
