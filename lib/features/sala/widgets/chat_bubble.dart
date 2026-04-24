import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:noray4/core/theme/noray4_theme.dart';
import 'package:noray4/features/sala/models/sala_models.dart';
import 'package:noray4/shared/widgets/rider_avatar.dart';

class ChatBubble extends StatefulWidget {
  final SalaMessage message;
  final Future<void> Function(String msgId)? onDelete;
  final Future<void> Function(String msgId, String newContent)? onEdit;

  const ChatBubble({
    super.key,
    required this.message,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _showTime = false;

  void _onLongPress() {
    final msg = widget.message;
    if (!msg.isOutgoing) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Noray4Colors.darkSurfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => _MessageActionsSheet(
        message: msg,
        onDelete: widget.onDelete != null
            ? () {
                Navigator.pop(context);
                widget.onDelete!(msg.id);
              }
            : null,
        onEdit: (msg.type == 'text' && widget.onEdit != null)
            ? () {
                Navigator.pop(context);
                _showEditDialog(msg);
              }
            : null,
      ),
    );
  }

  void _showEditDialog(SalaMessage msg) {
    final ctrl = TextEditingController(text: msg.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Noray4Colors.darkSurfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: Noray4Radius.primary,
          side: const BorderSide(
              color: Noray4Colors.darkOutlineVariant, width: 0.5),
        ),
        title: Text(
          'Editar mensaje',
          style: Noray4TextStyles.headlineM
              .copyWith(color: Noray4Colors.darkPrimary),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 4000,
          maxLines: null,
          style: Noray4TextStyles.body
              .copyWith(color: Noray4Colors.darkPrimary),
          decoration: InputDecoration(
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: Noray4Radius.secondary,
              borderSide: const BorderSide(
                  color: Noray4Colors.darkOutlineVariant, width: 0.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: Noray4TextStyles.body
                    .copyWith(color: Noray4Colors.darkOnSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isNotEmpty && text != msg.text) {
                widget.onEdit!(msg.id, text);
              }
              Navigator.pop(ctx);
            },
            child: Text('Guardar',
                style: Noray4TextStyles.body
                    .copyWith(color: Noray4Colors.darkPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    return GestureDetector(
      onTap: () => setState(() => _showTime = !_showTime),
      onLongPress: msg.isOutgoing ? _onLongPress : null,
      child: Align(
        alignment:
            msg.isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!msg.isOutgoing) ...[
              Padding(
                padding: const EdgeInsets.only(right: 6, bottom: 4),
                child: RiderAvatarCircle(
                  riderId: msg.riderId,
                  initials: msg.sender.isNotEmpty
                      ? msg.sender.characters.first.toUpperCase()
                      : '?',
                  size: 26,
                  backgroundColor: Noray4Colors.darkSurfaceContainerHighest,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            Flexible(
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
                padding: msg.type == 'image'
                    ? EdgeInsets.zero
                    : const EdgeInsets.all(Noray4Spacing.s4),
                decoration: BoxDecoration(
                  color: msg.type == 'image'
                      ? Colors.transparent
                      : (msg.isOutgoing
                          ? Noray4Colors.darkPrimary
                          : const Color(0xFF1C1C1B)),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(msg.isOutgoing ? 12 : 0),
                    bottomRight: Radius.circular(msg.isOutgoing ? 0 : 12),
                  ),
                  border: (msg.isOutgoing || msg.type == 'image')
                      ? null
                      : Border.all(
                          color: const Color(0xFF262624),
                          width: 0.5,
                        ),
                ),
                child: msg.type == 'image' && msg.mediaUrl != null
                    ? _ImageContent(
                        url: msg.mediaThumbUrl ?? msg.mediaUrl!,
                        fullUrl: msg.mediaUrl!,
                        isOutgoing: msg.isOutgoing,
                      )
                    : _TextContent(msg: msg),
              ),
            ),
            AnimatedOpacity(
              opacity: _showTime ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      msg.time,
                      style: Noray4TextStyles.bodySmall.copyWith(
                        color: Noray4Colors.darkOnSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                    if (msg.edited) ...[
                      const SizedBox(width: 4),
                      Text(
                        'editado',
                        style: Noray4TextStyles.bodySmall.copyWith(
                          color: Noray4Colors.darkOutline,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
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

// ─── Text content ──────────────────────────────────────────────────────────────

class _TextContent extends StatelessWidget {
  final SalaMessage msg;
  const _TextContent({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Text(
      msg.text,
      style: Noray4TextStyles.body.copyWith(
        color: msg.isOutgoing
            ? const Color(0xFF111110)
            : Noray4Colors.darkPrimary,
        height: 1.6,
      ),
    );
  }
}

// ─── Image content ─────────────────────────────────────────────────────────────

class _ImageContent extends StatelessWidget {
  final String url;
  final String fullUrl;
  final bool isOutgoing;

  const _ImageContent({
    required this.url,
    required this.fullUrl,
    required this.isOutgoing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullScreen(context),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: Radius.circular(isOutgoing ? 12 : 0),
          bottomRight: Radius.circular(isOutgoing ? 0 : 12),
        ),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 220,
          height: 160,
          fit: BoxFit.cover,
          placeholder: (ctx, url0) => Container(
            width: 220,
            height: 160,
            color: Noray4Colors.darkSurfaceContainerHigh,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Noray4Colors.darkOutlineVariant,
                ),
              ),
            ),
          ),
          errorWidget: (ctx, url0, err) => Container(
            width: 220,
            height: 160,
            color: Noray4Colors.darkSurfaceContainerHigh,
            child: const Icon(
              Symbols.broken_image,
              color: Noray4Colors.darkOutlineVariant,
            ),
          ),
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (ctx, anim, second) => _FullScreenImage(url: fullUrl),
      ),
    );
  }
}

// ─── Full screen viewer ────────────────────────────────────────────────────────

class _FullScreenImage extends StatelessWidget {
  final String url;
  const _FullScreenImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: Center(
          child: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Message actions sheet ────────────────────────────────────────────────────

class _MessageActionsSheet extends StatelessWidget {
  final SalaMessage message;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _MessageActionsSheet({
    required this.message,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Noray4Spacing.s4,
          vertical: Noray4Spacing.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Noray4Colors.darkOutlineVariant,
                borderRadius: Noray4Radius.pill,
              ),
            ),
            const SizedBox(height: Noray4Spacing.s4),
            if (onEdit != null)
              _ActionTile(
                icon: Symbols.edit,
                label: 'Editar mensaje',
                onTap: onEdit!,
              ),
            if (onDelete != null)
              _ActionTile(
                icon: Symbols.delete,
                label: 'Eliminar mensaje',
                destructive: true,
                onTap: onDelete!,
              ),
            const SizedBox(height: Noray4Spacing.s2),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFFF453A)
        : Noray4Colors.darkOnSurface;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: Noray4Spacing.s4,
          vertical: Noray4Spacing.s4,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: Noray4Spacing.s4),
            Text(
              label,
              style: Noray4TextStyles.body.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
