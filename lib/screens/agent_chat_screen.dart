import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

class _AgentChatScreenState extends State<AgentChatScreen> {
  final List<AgentChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  String _userName = '';

  // Outsourced clean monochrome avatar image
  final String _botAvatarUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&fit=crop&q=80';

  List<String> _suggestedPrompts = [
    'Recommend Sci-Fi movies',
    'Show Available Movies',
    'Open Live TV (10,000+ Channels)',
    'Check My Watchlist',
    'Interstellar plot explanation',
  ];

  @override
  void initState() {
    super.initState();
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
        ? 'Hi $greetingName, how can I help you today?'
        : 'Hi there, how can I help you today?';

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
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
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
      final reply = res['reply'] as String? ?? 'Sorry, I couldn\'t process that request.';
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // Monochrome Outsourced Avatar Image
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CachedNetworkImage(
                imageUrl: _botAvatarUrl,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1F24),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF3F3F46)),
                  ),
                  child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 16),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                // Pure Monochrome: Solid White for User, Dark Zinc Grey for Assistant
                color: isUser ? Colors.white : const Color(0xFF121214),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser ? Colors.white : const Color(0xFF27272A),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cleanedText,
                    style: AppFonts.sCoreDream(
                      color: isUser ? Colors.black : Colors.white,
                      fontSize: 13.5,
                      fontWeight: isUser ? FontWeight.w700 : FontWeight.w400,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF3F3F46)),
              ),
              child: Center(
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                  style: AppFonts.sCoreDream(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: _botAvatarUrl,
              width: 28,
              height: 28,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF121214),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: Text(
              'CineBot is typing...',
              style: AppFonts.sCoreDream(
                color: Colors.white54,
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
              ),
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
        backgroundColor: const Color(0xFF050505),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: _botAvatarUrl,
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI CINEBOT',
                  style: AppFonts.sCoreDream(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'Google Gemini 3.6',
                  style: AppFonts.sCoreDream(color: Colors.white54, fontSize: 9.5),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Divider(color: Color(0xFF1F1F23), height: 1),

            // Messages List
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

            // Monochrome Action Chips
            if (_suggestedPrompts.isNotEmpty)
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(vertical: 2),
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
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF121214),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF27272A)),
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
                color: Color(0xFF050505),
                border: Border(top: BorderSide(color: Color(0xFF1F1F23))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF121214),
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
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.black, size: 18),
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
