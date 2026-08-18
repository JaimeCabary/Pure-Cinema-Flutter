import 'package:flutter/material.dart';
import '../services/agent_service.dart';
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
  List<String> _suggestedPrompts = [
    'Recommend sci-fi movies',
    'Open my Watchlist',
    'Tell me about Interstellar',
    'Go to Live TV',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      AgentChatMessage(
        role: 'assistant',
        content: '🎬 **Welcome to Pure Cinema AI CineBot!**\nPowered by Google GenAI ADK. Ask me for movie recommendations, film trivia, or commands to navigate your app.',
      ),
    );
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
          duration: const Duration(milliseconds: 300),
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

  Widget _buildMessageItem(AgentChatMessage msg) {
    final isUser = msg.role == 'user';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF3F3F46)),
              ),
              child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                // Monochrome: Solid White for User, Sleek Obsidian Zinc for Assistant
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.content,
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
                border: Border.all(color: const Color(0xFFD4D4D8)),
              ),
              child: const Icon(Icons.person, color: Colors.black, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF050505),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF27272A), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF0C0C0E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                bottom: BorderSide(color: Color(0xFF1F1F23)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF3F3F46)),
                  ),
                  child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Pure Cinema AI CineBot',
                            style: AppFonts.sCoreDream(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white70,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Powered by Google GenAI ADK',
                        style: AppFonts.sCoreDream(
                          color: const Color(0xFFA1A1AA),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

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
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181B),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF3F3F46)),
                          ),
                          child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF121214),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF27272A)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'CineBot is thinking...',
                                style: AppFonts.sCoreDream(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),

          // Suggested Prompts
          if (_suggestedPrompts.isNotEmpty)
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestedPrompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final prompt = _suggestedPrompts[index];
                  return ActionChip(
                    backgroundColor: const Color(0xFF121214),
                    side: const BorderSide(color: Color(0xFF27272A)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    label: Text(
                      prompt,
                      style: AppFonts.sCoreDream(color: const Color(0xFFE4E4E7), fontSize: 11),
                    ),
                    onPressed: () => _handleSubmitted(prompt),
                  );
                },
              ),
            ),

          // Input Bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 16),
            decoration: const BoxDecoration(
              color: Color(0xFF0C0C0E),
              border: Border(
                top: BorderSide(color: Color(0xFF1F1F23)),
              ),
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
                      decoration: InputDecoration(
                        hintText: 'Ask Pure Cinema AI CineBot...',
                        hintStyle: AppFonts.sCoreDream(color: const Color(0xFF71717A), fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        border: InputBorder.none,
                      ),
                      onSubmitted: _handleSubmitted,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Solid White Circular Send Button with Black Icon
                GestureDetector(
                  onTap: () => _handleSubmitted(_textController.text),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.black, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
