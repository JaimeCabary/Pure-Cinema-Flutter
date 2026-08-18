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
        content: '🎬 **Welcome to Pure Cinema AI Agent!**\nPowered by Google GenAI ADK. Ask me for movie recommendations, film trivia, or commands to navigate your app.',
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
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFE50914), Color(0xFF7928CA)],
                  center: Alignment(-0.2, -0.3),
                ),
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFFE50914).withValues(alpha: 0.9) : const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
                  bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                ),
                border: Border.all(
                  color: isUser ? const Color(0xFFE50914) : Colors.purpleAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.content,
                    style: AppFonts.sCoreDream(
                      color: Colors.white,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                  if (msg.actions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: msg.actions.map((act) {
                        final type = act['type'] as String?;
                        final payload = act['payload'] as Map<String, dynamic>? ?? {};
                        final label = type == 'OPEN_MOVIE'
                            ? '▶ Play ${payload['title'] ?? 'Movie'}'
                            : type == 'NAVIGATE_TAB'
                                ? '📌 Go to Section'
                                : '✨ Take Action';

                        return ElevatedButton.icon(
                          onPressed: () {
                            if (type == 'NAVIGATE_TAB' && widget.onNavigateTab != null) {
                              Navigator.of(context).pop();
                              widget.onNavigateTab!(payload['index'] as int? ?? 0);
                            } else if (type == 'OPEN_MOVIE' && widget.onOpenMovie != null) {
                              Navigator.of(context).pop();
                              widget.onOpenMovie!(payload['movieId'] as int? ?? 157336);
                            }
                          },
                          icon: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                          label: Text(label, style: AppFonts.sCoreDream(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFE50914),
              child: Icon(Icons.person, size: 18, color: Colors.white),
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
        color: Color(0xFF0F0F1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF161626),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: [
              // Big Robot Avatar in Header
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFE50914), Color(0xFF7928CA)],
                  ),
                  border: Border.all(color: Colors.cyanAccent, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Pure Cinema AI CineBot',
                        style: AppFonts.sCoreDream(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00FF66),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Powered by Google GenAI ADK',
                    style: AppFonts.sCoreDream(fontSize: 10, color: Colors.purpleAccent),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: _messages.length,
                itemBuilder: (ctx, idx) => _buildMessageItem(_messages[idx]),
              ),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent),
                    ),
                    const SizedBox(width: 8),
                    Text('Agent is thinking...', style: AppFonts.sCoreDream(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),

            // Suggested prompt pills
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _suggestedPrompts.length,
                itemBuilder: (ctx, idx) {
                  final prompt = _suggestedPrompts[idx];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      backgroundColor: const Color(0xFF26263A),
                      label: Text(
                        prompt,
                        style: AppFonts.sCoreDream(color: Colors.white70, fontSize: 11),
                      ),
                      onPressed: () => _handleSubmitted(prompt),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Input Bar
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF161626),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: AppFonts.sCoreDream(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Ask Pure Cinema AI Bot...',
                          hintStyle: AppFonts.sCoreDream(color: Colors.grey.shade500, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF252538),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: _handleSubmitted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () => _handleSubmitted(_textController.text),
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFFE50914)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
