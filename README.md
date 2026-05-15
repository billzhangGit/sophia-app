# Sophia APP

A股量化交易客户端 — 复盘/龙头选股/个股查询

## 快速开始

### 1. 服务器端（已就绪）

API已部署在服务器 127.0.0.1:8000，使用 systemd 管理：

```bash
sudo cp ~/sophia_app/api.service /etc/systemd/system/sophia-api.service
sudo systemctl daemon-reload
sudo systemctl enable sophia-api
sudo systemctl start sophia-api
sudo systemctl status sophia-api
```

**修改API Token：**
```bash
sudo systemctl stop sophia-api
# 编辑 service 文件修改 SOPHIA_API_TOKEN
sudo vim /etc/systemd/system/sophia-api.service
sudo systemctl daemon-reload
sudo systemctl start sophia-api
```

**查看日志：**
```bash
tail -f ~/quant-auto-agent/logs/api.log
```

### 2. 安卓APP开发

#### 环境准备
```bash
# 下载Android Studio（阿里镜像）
# 浏览器打开：https://mirrors.aliyun.com/android-studio/

# 安装Flutter
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# 验证环境
flutter doctor

# 安装JDK
sudo apt install openjdk-17-jdk
```

#### 创建项目
```bash
flutter create sophia_app
cd sophia_app
```

然后用本仓库 `lib/` 目录覆盖 `sophia_app/lib/` 目录。

#### 修改服务器地址
编辑 `lib/config.dart`，将 `baseUrl` 改为你的服务器IP：
- 模拟器：`http://10.0.2.2:8000`（模拟器中 10.0.2.2 指向宿主机）
- 真机：`http://YOUR_SERVER_IP:8000`

#### 运行
```bash
cd sophia_app
flutter pub get
flutter run
```

## API文档

服务器启动后访问：http://127.0.0.1:8000/docs 查看Swagger文档

## 项目结构

```
sophia_app/
├── lib/
│   ├── main.dart                 # 入口+三Tab
│   ├── config.dart               # API配置（服务器地址+Token）
│   ├── services/
│   │   └── api_service.dart      # API调用封装
│   ├── pages/
│   │   ├── review_page.dart      # 复盘（市场总览+情绪+K线简图）
│   │   ├── dragon_page.dart      # 龙头选股（信号+候选股列表）
│   │   └── stock_query_page.dart # 个股查询（搜索+分析+K线）
│   └── widgets/                  # 通用组件（预留）
├── pubspec.yaml
└── analysis_options.yaml
```

## 技术栈

- **前端**: Flutter (Dart)
- **后端**: FastAPI (Python)
- **数据源**: DuckDB + 腾讯行情API
- **图表**: 自定义Canvas绘制 (CustomPaint)
