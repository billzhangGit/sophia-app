import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/app_theme.dart';

/// 聊天消息模型
class _ChatMessage {
  final String content;
  final bool isUser;
  final bool isStreaming;

  const _ChatMessage({
    required this.content,
    required this.isUser,
    this.isStreaming = false,
  });
}

/// 对话页 — 类似飞书的聊天气泡 UI
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _api = ApiService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  List<_ChatMessage> _messages = [];
  List<Map<String, dynamic>> _sessions = [];
  int? _currentSessionId;
  bool _isSending = false;
  StreamSubscription? _streamSub;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _streamSub?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 加载会话列表
  Future<void> _loadSessions() async {
    try {
      final sessions = await _api.getChatSessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions.cast<Map<String, dynamic>>();
      });
      // 默认选中第一个会话
      if (_sessions.isNotEmpty && _currentSessionId == null) {
        _selectSession(_sessions.first['id'] as int);
      }
    } catch (_) {
      if (!mounted) return;
    }
  }

  /// 选中一个会话
  Future<void> _selectSession(int sessionId) async {
    setState(() {
      _currentSessionId = sessionId;
      _messages = [];
    });
    try {
      final msgs = await _api.getChatMessages(sessionId);
      if (!mounted) return;
      setState(() {
        _messages = msgs.map((m) => _ChatMessage(
          content: m['content'] as String? ?? '',
          isUser: m['role'] == 'user',
        )).toList();
      });
      _scrollToBottom();
    } catch (_) {}
  }

  /// 新建会话
  Future<void> _createSession() async {
    try {
      final result = await _api.createChatSession(title: '新对话');
      if (!mounted) return;
      await _loadSessions();
      if (result['id'] != null) {
        _selectSession(result['id'] as int);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('创建会话失败')),
      );
    }
  }

  /// 发送消息
  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    _textController.clear();
    setState(() {
      _messages.add(_ChatMessage(content: text, isUser: true));
      _isSending = true;
      // 占位AI回复
      _messages.add(const _ChatMessage(
        content: '',
        isUser: false,
        isStreaming: true,
      ));
    });
    _scrollToBottom();

    try {
      final response = await _api.chatAsk(text, sessionId: _currentSessionId);
      final stream = response.stream.transform(utf8.decoder);
      final buffer = StringBuffer();

      _streamSub = stream.listen(
        (chunk) {
          // 解析 SSE 格式: data: {"content":"..."}\n\n
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final jsonStr = line.substring(6).trim();
              if (jsonStr == '[DONE]') continue;
              try {
                final obj = jsonDecode(jsonStr) as Map<String, dynamic>;
                final content = obj['content'] as String? ?? '';
                buffer.write(content);
                if (!mounted) return;
                setState(() {
                  // 替换最后的流式占位为实际内容
                  _messages.last = _ChatMessage(
                    content: buffer.toString(),
                    isUser: false,
                    isStreaming: true,
                  );
                });
                _scrollToBottom();
              } catch (_) {}
            }
          }
        },
        onDone: () {
          if (!mounted) return;
          setState(() {
            _messages.last = _ChatMessage(
              content: buffer.toString(),
              isUser: false,
              isStreaming: false,
            );
            _isSending = false;
          });
        },
        onError: (_) {
          if (!mounted) return;
          setState(() {
            _messages.last = _ChatMessage(
              content: '抱歉，回复生成失败，请重试。',
              isUser: false,
              isStreaming: false,
            );
            _isSending = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.last = _ChatMessage(
          content: '网络错误，请检查连接后重试。',
          isUser: false,
          isStreaming: false,
        );
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 会话选择栏
        _buildSessionBar(),
        // 消息列表
        Expanded(child: _buildMessageList()),
        // 输入区域
        _buildInputBar(),
      ],
    );
  }

  Widget _buildSessionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppTheme.card,
      child: Row(
        children: [
          const Icon(Icons.chat_outlined, color: AppTheme.textDim, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _currentSessionId,
                isExpanded: true,
                dropdownColor: AppTheme.cardAlt,
                hint: const Text('选择会话',
                    style: TextStyle(color: AppTheme.textDim)),
                style: const TextStyle(color: AppTheme.text, fontSize: 14),
                items: _sessions.map((s) {
                  final id = s['id'] as int;
                  final title = s['title'] as String? ?? '对话 $id';
                  return DropdownMenuItem(
                    value: id,
                    child: Text(title, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id != null) _selectSession(id);
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: AppTheme.up, size: 22),
            onPressed: _createSession,
            tooltip: '新建会话',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                color: AppTheme.textDim.withOpacity(0.3), size: 64),
            const SizedBox(height: 16),
            const Text(
              '开始与 Alex 对话',
              style: TextStyle(color: AppTheme.textDim, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '聊聊个股行情、市场观点...',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _buildBubble(msg);
      },
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    if (msg.isUser) {
      // 用户气泡 — 右对齐，绿色
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.up.withOpacity(0.15),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  msg.content,
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 用户头像
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.up.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.person, color: AppTheme.up, size: 18),
            ),
          ],
        ),
      );
    }

    // AI 气泡 — 左对齐，深灰色
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI 头像
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.info.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_awesome, color: AppTheme.info, size: 16),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: msg.isStreaming && msg.content.isEmpty
                  ? _buildTypingIndicator()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.content,
                          style: const TextStyle(
                            color: AppTheme.text,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        if (msg.isStreaming)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.textDim,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// 加载中抖动圆圈
  Widget _buildTypingIndicator() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TypingDot(delay: 0),
        SizedBox(width: 4),
        _TypingDot(delay: 200),
        SizedBox(width: 4),
        _TypingDot(delay: 400),
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border(
          top: BorderSide(color: AppTheme.textMuted.withOpacity(0.15)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              enabled: !_isSending,
              style: const TextStyle(color: AppTheme.text, fontSize: 14),
              decoration: InputDecoration(
                hintText: _isSending ? 'AI 回复中...' : '输入消息...',
                hintStyle: TextStyle(
                  color: _isSending ? AppTheme.textMuted : AppTheme.textDim,
                ),
                filled: true,
                fillColor: AppTheme.cardAlt,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _isSending
                    ? AppTheme.textMuted.withOpacity(0.3)
                    : AppTheme.up,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _isSending ? Icons.hourglass_empty : Icons.send_rounded,
                color: AppTheme.text,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 抖动加载指示器圆点
class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.textDim.withOpacity(0.4 + _animation.value * 0.6),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
