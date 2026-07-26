import 'package:flutter/material.dart';
import '../config/theme_config.dart';
import '../providers/assistant_provider.dart';
import 'glass_card.dart';

/// Scrollable conversation panel showing the recent exchange history.
///
/// User messages align right; assistant messages align left.
/// New messages slide in from the bottom with a fade.
class ConversationPanel extends StatefulWidget {
  final List<AssistantMessage> messages;
  final String interimText;

  const ConversationPanel({
    super.key,
    required this.messages,
    required this.interimText,
  });

  @override
  State<ConversationPanel> createState() => _ConversationPanelState();
}

class _ConversationPanelState extends State<ConversationPanel> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void didUpdateWidget(ConversationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length ||
        widget.interimText != oldWidget.interimText) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasContent =
        widget.messages.isNotEmpty || widget.interimText.isNotEmpty;

    if (!hasContent) {
      return const _EmptyHint();
    }

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      borderRadius: 24,
      glowColor: ThemeConfig.primary,
      glowRadius: 12,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.messages.length + (widget.interimText.isNotEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          // Interim text bubble (at the end)
          if (index == widget.messages.length) {
            return _InterimBubble(text: widget.interimText);
          }
          final msg = widget.messages[index];
          return _MessageBubble(
            key: ValueKey('msg_$index'),
            role: msg.role,
            content: msg.content,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  final String role;
  final String content;

  const _MessageBubble({super.key, required this.role, required this.content});

  bool get _isUser => role == 'user';

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment:
              _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!_isUser) const _Avatar(isUser: false),
            if (!_isUser) const SizedBox(width: 8),
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.68,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(_isUser ? 18 : 4),
                    bottomRight: Radius.circular(_isUser ? 4 : 18),
                  ),
                  color: _isUser
                      ? ThemeConfig.primary.withValues(alpha: 0.18)
                      : ThemeConfig.surfaceElevated,
                  border: Border.all(
                    color: _isUser
                        ? ThemeConfig.primary.withValues(alpha: 0.35)
                        : ThemeConfig.border,
                    width: 1,
                  ),
                ),
                child: Text(
                  content,
                  style: TextStyle(
                    color: _isUser
                        ? ThemeConfig.primary
                        : ThemeConfig.textPrimary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            if (_isUser) const SizedBox(width: 8),
            if (_isUser) const _Avatar(isUser: true),
          ],
        ),
      ),
    );
  }
}

class _InterimBubble extends StatelessWidget {
  final String text;
  const _InterimBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.68,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: ThemeConfig.primary.withValues(alpha: 0.08),
                border: Border.all(
                  color: ThemeConfig.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: ThemeConfig.primary.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const _Avatar(isUser: true),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final bool isUser;
  const _Avatar({required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUser
            ? ThemeConfig.primary.withValues(alpha: 0.2)
            : ThemeConfig.accent.withValues(alpha: 0.2),
        border: Border.all(
          color: isUser
              ? ThemeConfig.primary.withValues(alpha: 0.5)
              : ThemeConfig.accent.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
          size: 14,
          color: isUser ? ThemeConfig.primary : ThemeConfig.accent,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        'Press the mic or power on to begin',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: ThemeConfig.textMuted,
          fontSize: 13,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
