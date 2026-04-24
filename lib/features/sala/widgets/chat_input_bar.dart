import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/theme/noray4_theme.dart';

class ChatInputBar extends StatefulWidget {
  final ValueChanged<String> onSend;
  final Future<void> Function(String filePath)? onSendImage;

  const ChatInputBar({
    super.key,
    required this.onSend,
    this.onSendImage,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  bool _sending = false;

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || text.length > 4000) return;
    widget.onSend(_controller.text);
    _controller.clear();
  }

  Future<void> _pickImage() async {
    if (widget.onSendImage == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _sending = true);
    try {
      await widget.onSendImage!(picked.path);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: Noray4Spacing.s6,
        right: Noray4Spacing.s6,
        bottom: MediaQuery.of(context).viewInsets.bottom + Noray4Spacing.s4,
      ),
      child: ClipRRect(
        borderRadius: Noray4Radius.pill,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Noray4Colors.darkBackground.withValues(alpha: 0.8),
              borderRadius: Noray4Radius.pill,
              border: Border.all(
                color: const Color(0xFF262624),
                width: 0.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 64,
                  offset: Offset(0, 32),
                ),
              ],
            ),
            child: Row(
              children: [
                _sending
                    ? const SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Noray4Colors.darkSecondary,
                            ),
                          ),
                        ),
                      )
                    : _IconBtn(icon: Symbols.add, onTap: _pickImage),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: Noray4TextStyles.body.copyWith(
                      color: Noray4Colors.darkPrimary,
                    ),
                    maxLength: 4000,
                    decoration: InputDecoration(
                      hintText: 'Mensaje expedición...',
                      hintStyle: Noray4TextStyles.body.copyWith(
                        color: Noray4Colors.darkOnSurfaceVariant,
                      ),
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 4),
                _SendBtn(onTap: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Icon(icon, size: 22, color: Noray4Colors.darkSecondary),
      ),
    );
  }
}

class _SendBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _SendBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Noray4Colors.darkPrimary,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Symbols.arrow_upward,
          size: 20,
          color: Color(0xFF111110),
        ),
      ),
    );
  }
}
