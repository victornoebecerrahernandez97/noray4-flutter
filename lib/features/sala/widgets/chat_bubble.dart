import 'package:flutter/material.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/sala/models/sala_models.dart';

class ChatBubble extends StatefulWidget {
  final SalaMessage message;
  const ChatBubble({super.key, required this.message});

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _showTime = false;

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    return GestureDetector(
      onTap: () => setState(() => _showTime = !_showTime),
      child: Align(
        alignment:
            msg.isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: msg.isOutgoing
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!msg.isOutgoing) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  msg.sender,
                  style: Noray4TextStyles.label.copyWith(
                    color: Noray4Colors.darkSecondary,
                    letterSpacing: 0.05 * 10,
                  ),
                ),
              ),
            ],
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              child: Container(
                padding: const EdgeInsets.all(Noray4Spacing.s4),
                decoration: BoxDecoration(
                  color: msg.isOutgoing
                      ? Noray4Colors.darkPrimary
                      : const Color(0xFF1C1C1B),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(msg.isOutgoing ? 12 : 0),
                    bottomRight: Radius.circular(msg.isOutgoing ? 0 : 12),
                  ),
                  border: msg.isOutgoing
                      ? null
                      : Border.all(
                          color: const Color(0xFF262624),
                          width: 0.5,
                        ),
                ),
                child: Text(
                  msg.text,
                  style: Noray4TextStyles.body.copyWith(
                    color: msg.isOutgoing
                        ? const Color(0xFF111110)
                        : Noray4Colors.darkPrimary,
                    height: 1.6,
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _showTime ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                child: Text(
                  msg.time,
                  style: Noray4TextStyles.bodySmall.copyWith(
                    color: Noray4Colors.darkOnSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
