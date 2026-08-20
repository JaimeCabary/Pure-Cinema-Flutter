import 'package:flutter/material.dart';
import '../services/agent_service.dart';
import '../services/auth_service.dart';
import '../theme/fonts.dart';

class AgentChatScreen extends StatefulWidget {
  final Function(int index)? onNavigateTab;
  final Function(int movieId)? onOpenMovie;

  const AgentChatScreen({
    super.key,
    this.onNavigateTab,
    this.onOpenMovie,
  });

  @override
  State<AgentChatScreen> createState() => _AgentChatScreenState();
}

class _AgentChatScreenState extends State<AgentChatScreen> with TickerProviderStateMixin {
  final List<AgentChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _pulseController;
  bool _isLoading = false;
  String _userName = '';

  List<String> _suggestedPrompts = [
    '🎬 Recommend Sci-Fi Movies',
    '🍿 Show Available Movies Vault',
    '📺 Open Live TV (10,000+ Channels)',
    '⭐ Check My Watchlist',
    '⚡ Interstellar Lore & Physics',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _initGreeting();
  }

  Future<void> _initGreeting() async {
    final user = await AuthService.getCurrentUser();
    String greetingName = '';
    if (user != null && user.name.isNotEmpty) {
      greetingName = user.name.split(' ').first;
      _userName = greetingName;
    }

    final welcomeText = greetingName.isNotEmpty
        ? 'Welcome back, $greetingName! I am your AI CineBot Concierge. Ask me for movie recommendations, plot breakdowns, or ask me to control the app for you!'
        : 'Welcome to Pure Cinema! I am your AI CineBot Concierge. Ask me for movie recommendations, plot breakdowns, or ask me to control the app for you!';

    if (mounted) {
      setState(() {
        _messages.add(
          AgentChatMessage(
            role: 'assistant',
            content: welcomeText,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _handleSubmitted(String text) async {
    final query = text.trim();
    if (query.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() {
      _messages.add(AgentChatMessage(role: 'user', content: query));
      _isLoading = true;
    });
    _scrollToBottom();

    final res = await AgentService.sendChatMessage(
      message: query,
      history: _messages.sublist(0, _messages.length - 1),
    );

    if (mounted) {
      final reply = res['reply'] as String? ?? 'Sorry, I couldn\'t process that request right now.';
      final rawActions = res['actions'] as List<dynamic>? ?? [];
      final rawPrompts = (res['suggestedPrompts'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

      setState(() {
        _messages.add(AgentChatMessage(
          role: 'assistant',
          content: reply,
          actions: rawActions,
        ));
        if (rawPrompts.isNotEmpty) {
          _suggestedPrompts = rawPrompts;
        }
        _isLoading = false;
      });
      _scrollToBottom();

      // Trigger actions if returned from backend
      for (final act in rawActions) {
        final type = act['type'] as String?;
        final payload = act['payload'] as Map<String, dynamic>? ?? {};

        if (type == 'NAVIGATE_TAB' && widget.onNavigateTab != null) {
          final idx = payload['index'] as int? ?? 0;
          Navigator.of(context).pop();
          widget.onNavigateTab!(idx);
          break;
        } else if (type == 'OPEN_MOVIE' && widget.onOpenMovie != null) {
          final mId = payload['movieId'] as int?;
          if (mId != null) {
            Navigator.of(context).pop();
            widget.onOpenMovie!(mId);
            break;
          }
        }
      }
    }
  }

  String _cleanContent(String content) {
    return content.replaceAll('**', '').trim();
  }

  Widget _buildMessageItem(AgentChatMessage msg) {
    final isUser = msg.role == 'user';
    final cleanedText = _cleanContent(msg.content);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // Glowing AI Bot Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: isUser ? Colors.white : const Color(0xFF101014),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: Border.all(
                  color: isUser
                      ? Colors.white
                      : const Color(0xFF27272A),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'AI CINEBOT',
                            style: AppFonts.sCoreDream(
                              color: const Color(0xFF00E5FF),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E24),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'GEMINI 3.6',
                              style: AppFonts.sCoreDream(
                                color: Colors.white70,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    cleanedText,
                    style: AppFonts.sCoreDream(
                      color: isUser ? Colors.black : const Color(0xFFF4F4F5),
                      fontSize: 13.5,
                      fontWeight: isUser ? FontWeight.w800 : FontWeight.w400,
                      height: 1.48,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE4E4E7), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                  style: AppFonts.sCoreDream(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF101014),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: Row(
              children: [
                FadeTransition(
                  opacity: _pulseController,
                  child: const Icon(Icons.psychology_rounded, color: Color(0xFF00E5FF), size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  'CineBot is analyzing movie archives...',
                  style: AppFonts.sCoreDream(
                    color: Colors.white70,
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0E),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Holographic Animated Avatar Header
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFFFF007F)],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF050505),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'AI CINEBOT',
                      style: AppFonts.sCoreDream(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        'ONLINE',
                        style: AppFonts.sCoreDream(
                          color: const Color(0xFF00E5FF),
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Powered by Google Gemini 3.6 Hyperdrive',
                  style: AppFonts.sCoreDream(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Ambient Neon Glow Divider
            Container(
              height: 1.5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xFF00E5FF), Color(0xFF7C4DFF), Colors.transparent],
                ),
              ),
            ),

            // Message List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _messages.length) {
                    return _buildMessageItem(_messages[index]);
                  } else {
                    return _buildThinkingIndicator();
                  }
                },
              ),
            ),

            // Quick Suggestion Chips Row
            if (_suggestedPrompts.isNotEmpty)
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _suggestedPrompts.length,
                  itemBuilder: (context, index) {
                    final prompt = _suggestedPrompts[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => _handleSubmitted(prompt),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141418),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF27272A)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            prompt,
                            style: AppFonts.sCoreDream(
                              color: const Color(0xFFE4E4E7),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 6),

            // Input Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF0B0B0E),
                border: Border(top: BorderSide(color: Color(0xFF1F1F23))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF16161B),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF27272A)),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: AppFonts.sCoreDream(color: Colors.white, fontSize: 13),
                        textInputAction: TextInputAction.send,
                        onSubmitted: _handleSubmitted,
                        decoration: InputDecoration(
                          hintText: 'Ask CineBot or request an action...',
                          hintStyle: AppFonts.sCoreDream(color: Colors.white38, fontSize: 12.5),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _handleSubmitted(_textController.text),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
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
