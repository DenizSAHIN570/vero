import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vero/features/chat/chat_bubble.dart';
import 'package:vero/features/chat/chat_notifier.dart';
import 'package:vero/shared/theme/app_theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _focusNode.unfocus();
    ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatProvider);
    final colors = Theme.of(context).extension<VeroColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: colors.accent, size: 20),
            const SizedBox(width: 8),
            const Text('Vero'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear conversation',
            onPressed: () {
              ref.read(chatProvider.notifier).clearConversation();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () async {
              await Navigator.pushNamed(context, '/settings');
              // Re-init in case API key was changed
              ref.read(chatProvider.notifier).reinitialize();
            },
          ),
        ],
      ),
      body: chatAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: TextStyle(color: colors.textSecondary)),
        ),
        data: (state) => Column(
          children: [
            // No provider banner
            if (!state.hasProvider) _buildNoProviderBanner(context),

            // Error banner
            if (state.errorMessage != null)
              _buildErrorBanner(context, state.errorMessage!),

            // Message list
            Expanded(
              child: state.messages.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      itemCount: state.messages.length +
                          (state.status == ChatStatus.thinking ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == state.messages.length) {
                          return const ThinkingBubble();
                        }
                        return ChatBubble(message: state.messages[i]);
                      },
                    ),
            ),

            // Input bar
            _buildInputBar(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildNoProviderBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/settings'),
      child: Container(
        width: double.infinity,
        color: const Color(0xFF6C63FF).withOpacity(0.15),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.key_outlined, size: 16, color: Color(0xFF6C63FF)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'No AI provider configured. Tap to add an API key.',
                style:
                    TextStyle(color: Color(0xFF6C63FF), fontSize: 13),
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 16, color: Color(0xFF6C63FF)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      color: Colors.red.withOpacity(0.12),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = Theme.of(context).extension<VeroColors>()!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome,
              size: 48, color: colors.accent.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'Hi, I\'m Vero.',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type a message to get started.',
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, ChatState state) {
    final colors = Theme.of(context).extension<VeroColors>()!;
    final isThinking = state.status == ChatStatus.thinking;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !isThinking,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: isThinking ? 'Thinking…' : 'Message Vero…',
                ),
                style: TextStyle(color: colors.textPrimary),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: isThinking
                  ? Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.assistantBubble,
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : FloatingActionButton.small(
                      onPressed: _send,
                      backgroundColor: colors.userBubble,
                      child: const Icon(Icons.send, size: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
