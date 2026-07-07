import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/spoil_colors.dart';
import '../data/support_repository.dart';
import '../models/support_models.dart';
import '../providers/support_provider.dart';

class SupportChatScreen extends ConsumerStatefulWidget {
  const SupportChatScreen({super.key});

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;
  List<SupportMessageModel> _messages = [];
  bool _loading = true;
  String? _lastMessageAt;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollNewMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final conversation = await ref.read(supportRepositoryProvider).fetchConversation();
      if (mounted) {
        setState(() {
          _messages = conversation.messages;
          _loading = false;
          _lastMessageAt = conversation.messages.isNotEmpty ? conversation.messages.last.createdAt : null;
        });
        _scrollToEnd();
      }
    } catch (_) {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _pollNewMessages() async {
    if (_lastMessageAt == null) {
      await _load(silent: true);
      return;
    }
    try {
      final conversation = await ref.read(supportRepositoryProvider).fetchConversation(since: _lastMessageAt);
      if (!mounted || conversation.messages.isEmpty) return;
      setState(() {
        _messages = [..._messages, ...conversation.messages];
        _lastMessageAt = conversation.messages.last.createdAt;
      });
      _scrollToEnd();
    } catch (_) {}
  }

  void _scrollToEnd() {
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

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    _controller.clear();
    final message = await ref.read(supportRepositoryProvider).sendMessage(body);
    setState(() {
      _messages = [..._messages, message];
      _lastMessageAt = message.createdAt;
    });
    _scrollToEnd();
    ref.invalidate(supportConversationProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
        ),
        title: const Text('Live chat'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                'Live',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: SpoilColors.teal),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: SpoilColors.teal))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg = _messages[i];
                      final align = msg.isUser ? Alignment.centerRight : Alignment.centerLeft;
                      final color = msg.isUser ? SpoilColors.teal : SpoilColors.cream;
                      final textColor = msg.isUser ? Colors.white : SpoilColors.charcoal;
                      return Align(
                        alignment: align,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(msg.body, style: TextStyle(color: textColor)),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Type a message…'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(backgroundColor: SpoilColors.teal, foregroundColor: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}