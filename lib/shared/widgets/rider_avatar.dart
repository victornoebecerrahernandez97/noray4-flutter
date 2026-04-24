import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noray4/features/perfil/services/riders_service.dart';

/// Cache de URLs de avatar por riderId — consulta /riders/{id} y guarda el
/// resultado para no refetchear en cada render.
final riderAvatarProvider =
    FutureProvider.family<String?, String>((ref, riderId) async {
  if (riderId.isEmpty) return null;
  try {
    final rider = await RidersService().getRider(riderId);
    return rider.avatarUrl;
  } catch (_) {
    return null;
  }
});

/// Círculo de avatar reutilizable.
/// Si [overrideUrl] es null se resuelve desde [riderAvatarProvider].
/// Mientras carga o en error cae a iniciales.
class RiderAvatarCircle extends ConsumerWidget {
  final String? riderId;
  final String initials;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final Color backgroundColor;
  final String? overrideUrl;
  final double? fontSize;
  final FontWeight fontWeight;

  const RiderAvatarCircle({
    super.key,
    required this.riderId,
    required this.initials,
    required this.size,
    this.borderColor,
    this.borderWidth = 0,
    this.backgroundColor = const Color(0xFF1C1C1E),
    this.overrideUrl,
    this.fontSize,
    this.fontWeight = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? url = overrideUrl;
    if (url == null && riderId != null && riderId!.isNotEmpty) {
      url = ref.watch(riderAvatarProvider(riderId!)).valueOrNull;
    }

    final circle = Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
      child: (url != null && url.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, _) => _initialsLabel(),
              errorWidget: (_, _, _) => _initialsLabel(),
            )
          : _initialsLabel(),
    );

    return circle;
  }

  Widget _initialsLabel() => Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize ?? (size * 0.3).clamp(9.0, 16.0),
            fontWeight: fontWeight,
            letterSpacing: -0.2,
          ),
        ),
      );
}
